-------------------------------------------------------------------------------
-- SPDX-FileCopyrightText: 2026 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+
-------------------------------------------------------------------------------
--  10G TX framer
--  Generate 66b data from raw data.  Add start and terminate, pad the frame.
-------------------------------------------------------------------------------

--  TODO:
--  * insert source mac address
--  * err input
--  * disable crc generation ?
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.epx_pkg.all;

entity epx_tx_framer is
  port (
    clk_i : in std_logic;
    rst_n_i : in std_logic;

    --  Source mac address.  Bit 47 is the MSB
    --  So the first transmitted bit is bit 40 (which must be 0 as it is not
    --  a broadcast).
    saddr_i : in std_logic_vector(47 downto 0);

    --  Output to scrambler
    --  Bits 0 and 1 are sync bits.  Bit 0 is transmitted first.
    --  ready_i is for back-pressure.
    txdata_o : out t_blk66;
    ready_i  : in std_logic;

    --  Raw data.  First byte is (7 downto 0), second is (15 downto 8), ...
    --  start_i is set on the first transfer.
    --  ready_o is for back-pressure, beat is ignored when '0'.
    --  last_i is set on the last beat, and len_i indicate the number of
    --   valid bytes (0 means 8). last_i cannot be set on the first beat (ie
    --   at the same time as start_i).
    data_i : in std_logic_vector(63 downto 0);
    ready_o : out std_logic;
    start_i : in std_logic;
    last_i : in std_logic;
    len_i : in std_logic_vector(2 downto 0);
    force_saddr_i : in std_logic
  );
end epx_tx_framer;

architecture arch of epx_tx_framer is
  type t_fsm_state is (S_IDLE, S_DATA,
                       S_PAD,
                       S_TERMINATE0,
                       S_TERMINATE1,
                       S_TERMINATE2,
                       S_TERMINATE3,
                       S_TERMINATE4,
                       S_IGP1, S_IGP2);

  type t_state is record
    state : t_fsm_state;

    --  Output 66b block
    dout : t_blk66;

    --  Input data in transmission order.
    rdin : std_logic_vector(0 to 63);

    --  Inputs
    last : std_logic;
    len : std_logic_vector(2 downto 0);
    ready : std_logic;

    crc : t_slv32;
    tword : std_logic_vector(0 to 31);

    --  Frame length (in 8B)
    flen : unsigned(11 downto 0);
  end record;

  type t_slv32_arr is array(natural range <>) of t_slv32;

  signal s_crc : t_slv32_arr(1 to 8);

  signal state, nstate : t_state;

  --  Same as data_i but bit reversed.
  signal rev_datai : std_logic_vector(0 to 63);

  --  The final value is negated.
  --  CRC is sent from MSB to LSB, which is the natural order.
  subtype t_fcrc is std_logic_vector(0 to 31);
  function fcrc (v : t_slv32) return t_fcrc is
  begin
    return (not v(31 downto 24))
      & (not v(23 downto 16))
      & (not v(15 downto 8))
      & (not v(7 downto 0));
  end fcrc;
begin
  process (clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        state <= (state => S_IDLE,
                  dout => c_blk_idle,
                  rdin => (others => 'X'),
                  ready => '1',
                  last => '0',
                  len => "000",
                  crc => (others => 'X'),
                  tword => (others => 'X'),
                  flen => (others => 'X'));
      else
        if ready_i = '1' then
          state <= nstate;
        end if;
      end if;
    end if;
  end process;

  --  Compute CRC for 1 to 8 bytes.
  process (state.rdin, state.crc)
    variable v_crc : t_slv32;
    variable b : std_logic;
  begin
    v_crc := state.crc;
    for i in 0 to 7 loop
      v_crc(31 downto 24) :=
        v_crc(31 downto 24) xor state.rdin(i*8 to i*8 + 7);
      for j in 0 to 7 loop
        b := v_crc(31);
        v_crc := v_crc(30 downto 0) & '0';
        if b = '1' then
          v_crc := v_crc xor crc_poly;
        end if;
      end loop;
      s_crc(1 + i) <= v_crc;

--      report "crc: " & hex(not v_crc) & " " & t_fsm_state'image(state.state);
    end loop;
  end process;

  txdata_o <= state.dout;
  ready_o <= state.ready and ready_i;

  rev_datai(0 to 7)   <= rev8(data_i(7 downto 0));
  rev_datai(8 to 15)  <= rev8(data_i(15 downto 8));
  rev_datai(16 to 23) <= rev8(data_i(23 downto 16));
  rev_datai(24 to 31) <= rev8(data_i(31 downto 24));
  rev_datai(32 to 39) <= rev8(data_i(39 downto 32));
  rev_datai(40 to 47) <= rev8(data_i(47 downto 40));
  rev_datai(48 to 55) <= rev8(data_i(55 downto 48));
  rev_datai(56 to 63) <= rev8(data_i(63 downto 56));

  process(state, start_i, rev_datai, last_i, len_i, s_crc, force_saddr_i, saddr_i)
  begin
    nstate <= state;

    case state.state is
      when S_IDLE =>
        nstate.ready <= '1';
        if start_i = '1' then
          -- 802.3 2015 46.2.2 Preamble and start of frame delimiter
          -- On transmit the RS converts the first data octet of preamble
          -- transferred from the MAC into s Start control character.
          nstate.rdin <= rev_datai;
          nstate.last <= last_i;
          nstate.len <= len_i;
          nstate.dout <= c_blk_start;
          nstate.state <= S_DATA;
          nstate.flen <= (others => '0');
          nstate.crc <= (others => '1');

          if force_saddr_i = '1' then
            nstate.rdin(48 to 55) <= rev8(saddr_i(47 downto 40));
            nstate.rdin(56 to 63) <= rev8(saddr_i(39 downto 32));
          end if;
        end if;
      when S_DATA =>
        --  Transfer data
        nstate.flen <= state.flen + 1;

        --  Get next block
        nstate.rdin <= rev_datai;
        nstate.last <= last_i;
        nstate.len <= len_i;

        if state.flen = 0 and force_saddr_i = '1' then
          --  Overwrite source address
          nstate.rdin( 0 to  7) <= rev8(saddr_i(31 downto 24));
          nstate.rdin( 8 to 15) <= rev8(saddr_i(23 downto 16));
          nstate.rdin(16 to 23) <= rev8(saddr_i(15 downto  8));
          nstate.rdin(24 to 31) <= rev8(saddr_i( 7 downto  0));
        end if;

        if state.last = '1' then
          --  Need to pad if:
          --  * less than 7 blocks (ie 56B)
          --  * 7 blocks but len < 4
          if state.flen < 7 then
            --  Need to pad
            --  TODO: clear extra bytes (according to len) ?
            nstate.dout (0 to 1) <= c_blk_data (0 to 1);
            nstate.dout (2 to 65) <= state.rdin;
            nstate.crc <= s_crc(8);
            nstate.state <= S_PAD;
            nstate.rdin <= (others => '0');
          elsif state.flen = 7 then
            case state.len is
              when "001"
                | "010"
                | "011"
                | "100" =>
                nstate.dout (0 to 1) <= c_blk_data (0 to 1);
                nstate.dout (2 to 33) <= state.rdin(0 to 31);
                nstate.dout (34 to 65) <= fcrc(s_crc(4));
                nstate.state <= S_TERMINATE0;
              when "101" =>
                nstate.dout (0 to 1) <= c_blk_data (0 to 1);
                nstate.dout (2 to 41) <= state.rdin(0 to 39);
                nstate.dout (42 to 65) <= fcrc(s_crc(5))(0 to 23);
                nstate.tword (0 to 7) <= fcrc(s_crc(5))(24 to 31);
                nstate.state <= S_TERMINATE1;
              when "110" =>
                nstate.dout (0 to 1) <= c_blk_data (0 to 1);
                nstate.dout (2 to 49) <= state.rdin(0 to 47);
                nstate.dout (50 to 65) <= fcrc(s_crc(6))(0 to 15);
                nstate.tword (0 to 15) <= fcrc(s_crc(6))(16 to 31);
                nstate.state <= S_TERMINATE2;
              when "111" =>
                nstate.dout (0 to 1) <= c_blk_data (0 to 1);
                nstate.dout (2 to 57) <= state.rdin(0 to 55);
                nstate.dout (58 to 65) <= fcrc(s_crc(7))(0 to 7);
                nstate.tword (0 to 23) <= fcrc(s_crc(7))(8 to 31);
                nstate.state <= S_TERMINATE3;
              when "000" =>
                nstate.dout (0 to 1) <= c_blk_data (0 to 1);
                nstate.dout (2 to 65) <= state.rdin;
                nstate.tword <= fcrc(s_crc(8));
                nstate.state <= S_TERMINATE4;
              when others =>
                assert false;
            end case;
          else
            case state.len is
              when "000" =>
                nstate.dout (0 to 1) <= c_blk_data (0 to 1);
                nstate.dout (2 to 65) <= state.rdin;
                nstate.tword <= fcrc(s_crc(8));
                nstate.state <= S_TERMINATE4;
              when "001" =>
                nstate.dout (0 to 9) <= c_blk_t5 (0 to 9);
                nstate.dout (10 to 17) <= state.rdin(0 to 7);
                nstate.dout (18 to 49) <= fcrc(s_crc(1));
                nstate.dout (50 to 65) <= (others => '0');
                nstate.state <= S_IGP1;
              when "010" =>
                nstate.dout (0 to 9) <= c_blk_t6 (0 to 9);
                nstate.dout (10 to 25) <= state.rdin(0 to 15);
                nstate.dout (26 to 57) <= fcrc(s_crc(2));
                nstate.dout (58 to 65) <= (others => '0');
                nstate.state <= S_IGP1;
              when "011" =>
                nstate.dout (0 to 9) <= c_blk_t7 (0 to 9);
                nstate.dout (10 to 33) <= state.rdin(0 to 23);
                nstate.dout (34 to 65) <= fcrc(s_crc(3));
                nstate.state <= S_IGP1;
              when "100" =>
                nstate.dout (0 to 1) <= c_blk_data(0 to 1);
                nstate.dout (2 to 33) <= state.rdin(0 to 31);
                nstate.dout (34 to 65) <= fcrc(s_crc(4));
                nstate.state <= S_TERMINATE0;
              when "101" =>
                nstate.dout (0 to 1) <= c_blk_data (0 to 1);
                nstate.dout (2 to 41) <= state.rdin(0 to 39);
                nstate.dout (42 to 65) <= fcrc(s_crc(5))(0 to 23);
                nstate.tword (0 to 7) <= fcrc(s_crc(5))(24 to 31);
                nstate.state <= S_TERMINATE1;
              when "110" =>
                nstate.dout (0 to 1) <= c_blk_data (0 to 1);
                nstate.dout (2 to 49) <= state.rdin(0 to 47);
                nstate.dout (50 to 65) <= fcrc(s_crc(6))(0 to 15);
                nstate.tword (0 to 15) <= fcrc(s_crc(6))(16 to 31);
                nstate.state <= S_TERMINATE2;
              when "111" =>
                nstate.dout (0 to 1) <= c_blk_data (0 to 1);
                nstate.dout (2 to 57) <= state.rdin(0 to 55);
                nstate.dout (58 to 65) <= fcrc(s_crc(7))(0 to 7);
                nstate.tword (0 to 23) <= fcrc(s_crc(7))(8 to 31);
                nstate.state <= S_TERMINATE3;
              when others =>
                assert false;
            end case;
          end if;
        else
          --  Send block
          nstate.dout (0 to 1) <= c_blk_data (0 to 1);
          nstate.dout (2 to 65) <= state.rdin;

          nstate.crc <= s_crc(8);

          --  Clear ready if the next block is the last one.
          if last_i = '1' then
            nstate.ready <= '0';
          end if;
        end if;
      when S_PAD =>
        nstate.dout (0 to 1) <= c_blk_data (0 to 1);
        nstate.dout (2 to 65) <= (others => '0');
        nstate.rdin <= (others => '0');
        if state.flen = 7 then
          nstate.dout (34 to 65) <= fcrc(s_crc(4));
          nstate.state <= S_TERMINATE0;
        else
          nstate.crc <= s_crc(8);
          nstate.flen <= state.flen + 1;
        end if;
      when S_TERMINATE0 =>
        nstate.dout <= c_blk_t0;
        nstate.state <= S_IGP2;
      when S_TERMINATE1 =>
        nstate.dout <= c_blk_t1;
        nstate.dout (10 to 17) <= state.tword(0 to 7);
        nstate.state <= S_IGP2;
      when S_TERMINATE2 =>
        nstate.dout <= c_blk_t2;
        nstate.dout (10 to 25) <= state.tword(0 to 15);
        nstate.state <= S_IGP2;
      when S_TERMINATE3 =>
        nstate.dout <= c_blk_t3;
        nstate.dout (10 to 33) <= state.tword(0 to 23);
        nstate.state <= S_IGP2;
      when S_TERMINATE4 =>
        nstate.dout <= c_blk_t4;
        nstate.dout (10 to 41) <= state.tword(0 to 31);
        nstate.state <= S_IGP1;
      when S_IGP1 =>
        nstate.dout <= c_blk_idle;
        nstate.state <= S_IGP2;
      when S_IGP2 =>
        --  Note: according to IEEE 802.3 4.4.2 MAC parameters
        --   interPacketGap is 96b
        --  We extened it to 128b to simplify the logic.
        nstate.dout <= c_blk_idle;
        nstate.state <= S_IDLE;
    end case;
  end process;
end arch;
