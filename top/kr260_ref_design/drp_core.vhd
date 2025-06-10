library ieee;
use ieee.std_logic_1164.all;

use work.wishbone_pkg.all;

entity drp_core is
  generic (ila : boolean := false);
  port (
    clk_i : in std_logic;
    rst_n_i : in std_logic;

    wb_i: in t_wishbone_slave_in;
    wb_o: out t_wishbone_slave_out;

    drp_addr_o : out std_logic_vector(15 downto 0);
    drp_en_o : out std_logic;
    drp_we_o : out std_logic;
    drp_rst_o : out std_logic;
    drp_di_o : out std_logic_vector(15 downto 0);
    drp_do_i : in  std_logic_vector(15 downto 0);
    drp_rdy_i : in std_logic
    );
end drp_core;

architecture arch of drp_core is
  signal drp_addr, data_in, data_out, wdata : std_logic_vector(15 downto 0);
  signal rdy, we, we_in, en_in, rst, rst_in : std_logic;
  signal control_wr, drp_en : std_logic;
begin
  inst_map: entity work.drp_map
    port map (
      rst_n_i => rst_n_i,
      clk_i => clk_i,
      wb_i => wb_i,
      wb_o => wb_o,
      addr_o => drp_addr,
      control_data_i => data_in,
      control_data_o => data_out,
      control_rdy_i => rdy,
      control_rdy_o => open,
      control_we_i => we,
      control_we_o => we_in,
      control_en_i => '0',
      control_en_o => en_in,
      control_rst_i => rst,
      control_rst_o => rst_in,
      control_wr_o => control_wr
    );

  drp_rst_o <= rst;
  drp_di_o <= wdata;
  drp_addr_o <= drp_addr;

  process(clk_i)
  begin
    if rising_edge(clk_i) then
      --  Delay drp_en by one cycle.
      drp_we_o <= '0';
      drp_en_o <= '0';
      if drp_en = '1' then
        drp_en_o <= '1';
        drp_we_o <= we;
      end if;
      drp_en <= '0';

      if rst_n_i = '0' then
        rdy <= '1';
        rst <= '0';
        we <= '0';
        wdata <= (others => '0');
        data_in <= (others => '0');
      else
        --  rdy is cleared on enable, and set when ready.
        --  Pulse on drp_en_o when en is set.
        if drp_rdy_i = '1' then
          rdy <= '1';
          data_in <= drp_do_i;
        end if;
        if control_wr = '1' and en_in = '1' then
          drp_en <= '1';
          rdy <= '0';
        end if;
        if drp_en = '1' then
          rdy <= '0';
        end if;

        if control_wr = '1' then
          rst <= rst_in;
          we <= we_in;
          wdata <= data_out;
        end if;
      end if;
    end if;
  end process;


  gen_ila: if ila generate
  component ila_0
    port (
      clk    : in STD_LOGIC;
      probe0 : in STD_LOGIC_VECTOR(63 downto 0)
    );
  end component  ;
begin
  inst_ila: ila_0
    port map (
      clk => clk_i,
      probe0(15 downto 0) => drp_do_i,
      probe0(31 downto 16) => wdata,
--        probe0(47 downto 32) => gth_tx_data_out,
      probe0(47 downto 32) => drp_addr,
      probe0(48) => drp_en,
      probe0(49) => we,
      probe0(50) => rdy,
      probe0(51) => control_wr,
      probe0(52) => drp_rdy_i,
      probe0(63 downto 53) => (others => '0')
    );
end generate;

end arch;