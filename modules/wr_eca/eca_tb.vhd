-------------------------------------------------------------------------------
-- SPDX-FileCopyrightText: 2016 GSI / Wesley W. Terpstra <w.terpstra@gsi.de>
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+
-------------------------------------------------------------------------------
--! @file eca_tb.vhd
--! @brief ECA test-bench
--! @author Wesley W. Terpstra <w.terpstra@gsi.de>
--!
--! This drives all the entity unit tests
--!
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.eca_internals_pkg.all;

entity eca_tb is
end eca_tb;

architecture rtl of eca_tb is
  signal run  : boolean   := true;
  signal rstn : std_logic := '0';
  signal clk  : std_logic := '1';
begin

  stop : process is
  begin
    wait for 99996 ns;
    run <= false;
    wait;
  end process;
  
  reset : process is
  begin
    wait for 76 ns;
    rstn <= '1';
    wait;
  end process;

  clock : process is
  begin
    while run loop
      clk <= '1';
      wait for 4 ns;
      clk <= '0';
      wait for 4 ns;
    end loop;
    report "Simulation completed successfully";
    wait;
  end process;
  
  -- Test cases ------------------------------------------------------------------
  
  --sort0 : eca_bitonic_tb generic map(g_case => 0) port map(clk_i => clk, rst_n_i => rstn);
  --sort1 : eca_bitonic_tb generic map(g_case => 1) port map(clk_i => clk, rst_n_i => rstn);
  --sort2 : eca_bitonic_tb generic map(g_case => 2) port map(clk_i => clk, rst_n_i => rstn);
  comp0 : eca_compact_tb generic map(g_case => 0) port map(clk_i => clk, rst_n_i => rstn);
  comp1 : eca_compact_tb generic map(g_case => 1) port map(clk_i => clk, rst_n_i => rstn);
  compF : eca_compact_tb generic map(g_case =>15) port map(clk_i => clk, rst_n_i => rstn);
  fifo0 : eca_fifo_tb    generic map(g_case => 0) port map(clk_i => clk, rst_n_i => rstn);
  fifo2 : eca_fifo_tb    generic map(g_case => 2) port map(clk_i => clk, rst_n_i => rstn);
  rmw0  : eca_rmw_tb     generic map(g_case => 0) port map(clk_i => clk, rst_n_i => rstn);
  rmw2  : eca_rmw_tb     generic map(g_case => 2) port map(clk_i => clk, rst_n_i => rstn);
  free0 : eca_free_tb    generic map(g_case => 0) port map(clk_i => clk, rst_n_i => rstn);
  free2 : eca_free_tb    generic map(g_case => 2) port map(clk_i => clk, rst_n_i => rstn);
  scan0 : eca_scan_tb    generic map(g_case => 0) port map(clk_i => clk, rst_n_i => rstn);
  scan1 : eca_scan_tb    generic map(g_case => 1) port map(clk_i => clk, rst_n_i => rstn);
  scan2 : eca_scan_tb    generic map(g_case => 2) port map(clk_i => clk, rst_n_i => rstn);
  scan3 : eca_scan_tb    generic map(g_case => 3) port map(clk_i => clk, rst_n_i => rstn);
  tag0  : eca_tag_channel_tb generic map(g_case => 0) port map(clk_i => clk, rst_n_i => rstn);
  tag1  : eca_tag_channel_tb generic map(g_case => 1) port map(clk_i => clk, rst_n_i => rstn);
  tag2  : eca_tag_channel_tb generic map(g_case => 2) port map(clk_i => clk, rst_n_i => rstn);
  tag3  : eca_tag_channel_tb generic map(g_case => 3) port map(clk_i => clk, rst_n_i => rstn);
  tag4  : eca_tag_channel_tb generic map(g_case => 4) port map(clk_i => clk, rst_n_i => rstn);
  piso0 : eca_piso_fifo_tb   generic map(g_case => 0) port map(clk_i => clk, rst_n_i => rstn);
  piso1 : eca_piso_fifo_tb   generic map(g_case => 1) port map(clk_i => clk, rst_n_i => rstn);
  piso2 : eca_piso_fifo_tb   generic map(g_case => 2) port map(clk_i => clk, rst_n_i => rstn);
  chan2 : eca_channel_tb     generic map(g_case => 3) port map(clk_i => clk, rst_n_i => rstn);

end rtl;
