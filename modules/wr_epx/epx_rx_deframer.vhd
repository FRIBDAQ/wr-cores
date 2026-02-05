-------------------------------------------------------------------------------
-- SPDX-FileCopyrightText: 2026 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+
-------------------------------------------------------------------------------
--  10G RX deframer
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.epx_pkg.all;

entity epx_rx_deframer is
  port (
    clk_i : in std_logic;
    rst_n_i : in std_logic;

    --  Input from descrambler
    --  Bits 0 and 1 are sync bits.  Bit 0 is received first.
    rxdata_i : in t_blk66;
    valid_i  : in std_logic;
    lock_i   : in std_logic;

    --  Raw data.  First byte is (7 downto 0), second is (15 downto 8), ...
    --  start_o is set on the first transfer.
    --  last_i is set on the last beat, and len_i indicate the number of
    --   valid bytes (0 means 8). last_i cannot be set on the first beat (ie
    --   at the same time as start_i).
    data_o : out std_logic_vector(63 downto 0);
    valid_o : out std_logic;
    start_o : out std_logic;
    last_o : out std_logic;
    len_o : out std_logic_vector(2 downto 0);
    err_o : out std_logic;
    crc_ok_o : out std_logic
  );
end epx_rx_deframer;

architecture arch of epx_rx_deframer is
  type t_fsm_state is (S_IDLE, S_DATA);

  type t_data is record
    data : std_logic_vector(63 downto 0);
    valid : std_logic;
    start : std_logic;
    last : std_logic;
    len : std_logic_vector(2 downto 0);
    err : std_logic;
  end record;

  subtype t_flen is natural range 0 to 2**14 - 1;

  type t_state is record
    state : t_fsm_state;
    data_in : t_data;
    data_out : t_data;
    flen : t_flen;
    crc_in : t_slv32;
    crc_out : t_slv32;
  end record;

  signal crc_d8 : t_slv32;
  signal state, nstate : t_state;
  signal rev_rxdata : std_logic_vector(63 downto 0);

  type t_slv32_arr is array(natural range <>) of t_slv32;
  signal crc_t : t_slv32_arr(1 to 7);
  signal crc_out_rev : t_slv32;
begin
  process (clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        state <= (state => S_IDLE,
                  data_in | data_out => (data => (others => 'X'),
                                         valid => '0',
                                         start => '0',
                                         last => '0',
                                         len => "XXX",
                                         err => '0'),
                  flen => 0,
                  crc_in => (others => 'X'),
                  crc_out => (others => 'X'));
      else
        state <= nstate;
      end if;
    end if;
  end process;

  data_o <= state.data_out.data;
  valid_o <= state.data_out.valid;
  start_o <= state.data_out.start;
  last_o <= state.data_out.last;
  len_o <= state.data_out.len;
  err_o <= state.data_out.err;
  crc_ok_o <= '1' when crc_out_rev = crc_verify_rev else '0';

  crc_out_rev <= rev8(not state.crc_out( 7 downto 0))
                 & rev8(not state.crc_out(15 downto  8))
                 & rev8(not state.crc_out(23 downto 16))
                 & rev8(not state.crc_out(31 downto 24));

  rev_rxdata( 7 downto  0) <= rev8(rxdata_i( 2 to  9));
  rev_rxdata(15 downto  8) <= rev8(rxdata_i(10 to 17));
  rev_rxdata(23 downto 16) <= rev8(rxdata_i(18 to 25));
  rev_rxdata(31 downto 24) <= rev8(rxdata_i(26 to 33));
  rev_rxdata(39 downto 32) <= rev8(rxdata_i(34 to 41));
  rev_rxdata(47 downto 40) <= rev8(rxdata_i(42 to 49));
  rev_rxdata(55 downto 48) <= rev8(rxdata_i(50 to 57));
  rev_rxdata(63 downto 56) <= rev8(rxdata_i(58 to 65));

  --  Compute CRC for a data block
  process (rxdata_i, state.crc_in)
    variable v_crc : t_slv32;
    variable b : std_logic;
  begin
    v_crc := state.crc_in;
    for i in 0 to 7 loop
      v_crc(31 downto 24) :=
        v_crc(31 downto 24) xor rxdata_i(i*8 + 2 to i*8 + 9);
      for j in 0 to 7 loop
        b := v_crc(31);
        v_crc := v_crc(30 downto 0) & '0';
        if b = '1' then
          v_crc := v_crc xor crc_poly;
        end if;
      end loop;
    end loop;
    crc_d8 <= v_crc;
  end process;

  --  Compute CRC for a terminate block
  process (rxdata_i, state.crc_in)
    variable v_crc : t_slv32;
    variable b : std_logic;
  begin
    v_crc := state.crc_in;
    for i in 1 to 7 loop
      v_crc(31 downto 24) :=
        v_crc(31 downto 24) xor rxdata_i(i*8 + 2 to i*8 + 9);
      for j in 0 to 7 loop
        b := v_crc(31);
        v_crc := v_crc(30 downto 0) & '0';
        if b = '1' then
          v_crc := v_crc xor crc_poly;
        end if;
      end loop;
      crc_t(i) <= v_crc;
    end loop;
  end process;

  process (state, valid_i, lock_i, rxdata_i, rev_rxdata, crc_d8, crc_t)
  begin
    nstate <= state;

    case state.state is
      when S_IDLE =>
        if valid_i = '1' and lock_i = '1'
          and rxdata_i = c_blk_start
        then
          --  Start of frame, with correct preamble and SFD.
          nstate.state <= S_DATA;
          nstate.flen <= 0;
          nstate.crc_in <= (others => '1');
          nstate.crc_out <= (others => '0');
        end if;
        nstate.data_out <= state.data_in;
        nstate.data_in.valid <= '0';
        nstate.data_in.last <= '0';

      when S_DATA =>
        if lock_i = '0' then
          --  Lock loss.
          nstate.state <= S_IDLE;
          if state.data_in.valid = '1' then
            nstate.data_out <= state.data_in;
            nstate.data_out.err <= '1';
          end if;
          nstate.data_in.valid <= '0';

        elsif valid_i = '1' then
          --  Shift
          nstate.data_out <= state.data_in;

          nstate.data_in.start <= '0';

          if rxdata_i(0 to 1) = c_blk_data(0 to 1) then
            --  Data block
            nstate.data_in <= (data => rev_rxdata,
                               valid => '1',
                               start => '0',
                               last => '0',
                               len => "XXX",
                               err => '0');
            if state.flen = 0 then
              nstate.data_in.start <= '1';
            end if;
            nstate.flen <= state.flen + 8;
            nstate.crc_in <= crc_d8;
          else
            case rxdata_i(0 to 9) is
              when c_blk_t0_hdr =>
                --  Set the last bit on the previous beat.
                nstate.data_out.last <= '1';
                nstate.data_out.len <= "000";
                nstate.data_in.valid <= '0';
                nstate.crc_out <= state.crc_in;
              when c_blk_t1_hdr =>
                nstate.data_in.data(7 downto 0) <= rev_rxdata(15 downto 8);
                nstate.data_in.len <= "001";
                nstate.data_in.last <= '1';
                nstate.crc_out <= crc_t(1);
              when c_blk_t2_hdr =>
                nstate.data_in.data(15 downto 0) <= rev_rxdata(23 downto 8);
                nstate.data_in.len <= "010";
                nstate.data_in.last <= '1';
                nstate.crc_out <= crc_t(2);
              when c_blk_t3_hdr =>
                nstate.data_in.data(23 downto 0) <= rev_rxdata(31 downto 8);
                nstate.data_in.len <= "011";
                nstate.data_in.last <= '1';
                nstate.crc_out <= crc_t(3);
              when c_blk_t4_hdr =>
                nstate.data_in.data(31 downto 0) <= rev_rxdata(39 downto 8);
                nstate.data_in.len <= "100";
                nstate.data_in.last <= '1';
                nstate.crc_out <= crc_t(4);
              when c_blk_t5_hdr =>
                nstate.data_in.data(39 downto 0) <= rev_rxdata(47 downto 8);
                nstate.data_in.len <= "101";
                nstate.data_in.last <= '1';
                nstate.crc_out <= crc_t(5);
              when c_blk_t6_hdr =>
                nstate.data_in.data(47 downto 0) <= rev_rxdata(55 downto 8);
                nstate.data_in.len <= "110";
                nstate.data_in.last <= '1';
                nstate.crc_out <= crc_t(6);
              when c_blk_t7_hdr =>
                nstate.data_in.data(55 downto 0) <= rev_rxdata(63 downto 8);
                nstate.data_in.len <= "111";
                nstate.data_in.last <= '1';
                nstate.crc_out <= crc_t(7);
              when others =>
                if state.data_in.valid = '1' then
                  nstate.data_out.err <= '1';
                  nstate.data_in.valid <= '0';
                end if;
            end case;
            nstate.state <= S_IDLE;
          end if;
        else
          --  Not valid.  Don't shift data
          nstate.data_out.valid <= '0';
        end if;
    end case;
  end process;
end arch;
