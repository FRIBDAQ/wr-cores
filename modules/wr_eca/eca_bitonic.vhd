-------------------------------------------------------------------------------
-- SPDX-FileCopyrightText: 2013 GSI / Wesley W. Terpstra <w.terpstra@gsi.de>
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+
-------------------------------------------------------------------------------
--! @file eca_bitonic.vhd
--! @brief ECA Bitonic Sorting Network
--! @author Wesley W. Terpstra <w.terpstra@gsi.de>
--!
--! This component sorts the input numbers in O(nlog^2n) area and 
--!
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.eca_internals_pkg.all;

entity eca_bitonic is
  generic(
    g_log_size : natural;
    g_wide     : natural;
    g_order    : boolean := true); -- true = smallest first
  port(
    clk_i   : in  std_logic;
    rst_n_i : in  std_logic;
    en_i    : in  std_logic;
    nums_i  : in  t_eca_matrix(2**g_log_size-1 downto 0, g_wide-1 downto 0);
    nums_o  : out t_eca_matrix(2**g_log_size-1 downto 0, g_wide-1 downto 0));
end eca_bitonic;

architecture rtl of eca_bitonic is
  -- Quartus 11+ goes crazy and infers 7 M9Ks in an altshift_taps! Stop it.
  attribute altera_attribute : string; 
  attribute altera_attribute of rtl : architecture is "-name AUTO_SHIFT_REGISTER_RECOGNITION OFF";
begin

  -- Handle the case of only a single number = pass-through
  base0: if g_log_size = 0 generate
    nums_o <= nums_i;
  end generate;
  
  basen0 : if g_log_size > 0 generate
    blockn0 : block is
      constant c_full : natural := 2**g_log_size;
      signal sub_done : t_eca_matrix(c_full-1 downto 0, g_wide-1 downto 0);
    begin
      -- If only two elements, no recursive step needed
      base1 : if g_log_size = 1 generate
        sub_done <= nums_i;
      end generate;
      
      -- Recursively solve 2 sub-problems
      basen1 : if g_log_size > 1 generate
        blockn1 : block is
          constant c_log_size1 : natural := g_log_size - 1;
          constant c_half      : natural := 2**c_log_size1;
          signal sub_i0, sub_i1 : t_eca_matrix(c_half-1 downto 0, g_wide-1 downto 0);
          signal sub_o0, sub_o1 : t_eca_matrix(c_half-1 downto 0, g_wide-1 downto 0);
        begin
        
          sub0 : work.eca_internals_pkg.eca_bitonic
            generic map(
              g_log_size => c_log_size1,
              g_wide     => g_wide,
              g_order    => g_order)
            port map(
              clk_i   => clk_i,
              rst_n_i => rst_n_i,
              en_i    => en_i,
              nums_i  => sub_i0,
              nums_o  => sub_o0);
              
          sub1 : work.eca_internals_pkg.eca_bitonic
            generic map(
              g_log_size => c_log_size1,
              g_wide     => g_wide,
              g_order    => not g_order)
            port map(
              clk_i   => clk_i,
              rst_n_i => rst_n_i,
              en_i    => en_i,
              nums_i  => sub_i1,
              nums_o  => sub_o1);
          
          -- Remap the indexes
          relabel : for i in 0 to c_half-1 generate
            bits : for b in 0 to g_wide-1 generate
              sub_i0(i, b) <= nums_i(i,       b);
              sub_i1(i, b) <= nums_i(i+c_half, b);
              sub_done(i,        b) <= sub_o0(i, b);
              sub_done(i+c_half, b) <= sub_o1(i, b);
            end generate;
          end generate;
          
        end block;
      end generate;
      
      -- Generate the comparators
      sort : eca_bitonic_helper
        generic map(
          g_log_size => g_log_size,
          g_wide     => g_wide,
          g_order    => g_order)
        port map(
          clk_i   => clk_i,
          rst_n_i => rst_n_i,
          en_i    => en_i,
          nums_i  => sub_done,
          nums_o  => nums_o);
      
    end block;
  end generate;
  
end rtl;
