-------------------------------------------------------------------------------
-- Title      : Auxiliary clock generation (10MHz by default)
-- Project    : White Rabbit Switch
-------------------------------------------------------------------------------
-- File       : xwrsw_gen_10mhz.vhd
-- Author     : Grzegorz Daniluk
-- Company    : CERN BE-CO-HT
-- Created    : 2014-12-01
-- Last update: 2020-07-28
-- Platform   : FPGA-generic
-- Standard   : VHDL
-------------------------------------------------------------------------------
-- Description:
-- Module used to generate aux clock of configured frequency and phase. It can
-- be used with WRS hardware >= 3.4. The clk_aux_p/n_o is there wired to CLK2
-- SMC connector on the front panel. By default 10MHz signal is generated.
-------------------------------------------------------------------------------
--
-- Copyright (c) 2014 CERN / BE-CO-HT
--
-- This source file is free software; you can redistribute it
-- and/or modify it under the terms of the GNU Lesser General
-- Public License as published by the Free Software Foundation;
-- either version 2.1 of the License, or (at your option) any
-- later version.
--
-- This source is distributed in the hope that it will be
-- useful, but WITHOUT ANY WARRANTY; without even the implied
-- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
-- PURPOSE.  See the GNU Lesser General Public License for more
-- details.
--
-- You should have received a copy of the GNU Lesser General
-- Public License along with this source; if not, download it
-- from http://www.gnu.org/licenses/lgpl-2.1.html
--
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2014-12-01  1.0      greg.d          Created
-- 2024-07-24  1.1      harvey.l        Adapt for WRPC
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.wishbone_pkg.all;
use work.auxclk_gen_regs_pkg.all;
use work.gencores_pkg.all;

library UNISIM;
use UNISIM.vcomponents.all;

entity xwr_auxclk_gen is
  generic (
    g_interface_mode      : t_wishbone_interface_mode      := PIPELINED;
    g_address_granularity : t_wishbone_address_granularity := WORD;
    g_data_width          : natural := 8
  );
  port (
    rst_n_i     : in std_logic;
    clk_i       : in std_logic;
    pps_i       : in std_logic;
    pps_valid_i : in std_logic;
    pll_locked_i : in std_logic;

    sd_data_o       : out std_logic_vector(g_data_width-1 downto 0);

    slave_i   : in  t_wishbone_slave_in := cc_dummy_slave_in;
    slave_o   : out t_wishbone_slave_out);
end entity xwr_auxclk_gen;

architecture behav of xwr_auxclk_gen is

  constant c_DATA_W : integer := g_data_width;
  constant c_HALF   : integer := 25;-- default high/low width for 10MHz

  signal sd_data : std_logic_vector(g_data_width-1 downto 0);

  signal wb_in  : t_wishbone_slave_in;
  signal wb_out : t_wishbone_slave_out;
  signal aux_half_high: unsigned(15 downto 0);
  signal aux_half_low : unsigned(15 downto 0);
  signal aux_shift    : unsigned(15 downto 0);
  signal pps_valid_d  : std_logic;
  signal clk_realign  : std_logic;
  signal new_freq     : std_logic;
  signal auxclk_regs_out : t_auxclk_regs_master_out;

begin

  U_Adapter : wb_slave_adapter
    generic map (
      g_master_use_struct  => true,
      g_master_mode        => CLASSIC,
      g_master_granularity => WORD,
      g_slave_use_struct   => true,
      g_slave_mode         => g_interface_mode,
      g_slave_granularity  => g_address_granularity)
    port map (
      clk_sys_i => clk_i,
      rst_n_i   => rst_n_i,
      slave_i   => slave_i,
      slave_o   => slave_o,
      master_i  => wb_out,
      master_o  => wb_in);

  U_WB_IF: entity work.auxclk_gen_regs
  port map (
    rst_n_i => rst_n_i,
    clk_i   => clk_i,
    wb_cyc_i  => wb_in.cyc,
    wb_stb_i  => wb_in.stb,
    wb_adr_i  => wb_in.adr(0 downto 0),
    wb_sel_i  => wb_in.sel,
    wb_we_i   => wb_in.we,
    wb_dat_i  => wb_in.dat,
    wb_ack_o  => wb_out.ack,
    wb_err_o  => wb_out.err,
    wb_rty_o  => wb_out.rty,
    wb_stall_o   => wb_out.stall,
    wb_dat_o     => wb_out.dat,
      -- Wires and registers
    auxclk_regs_o => auxclk_regs_out
  );

  p_pw_settings: process(clk_i)
  begin
    if rising_edge(clk_i) then
      if (rst_n_i = '0') then
        aux_half_high <= to_unsigned(c_HALF, aux_half_high'length);
        aux_half_low  <= to_unsigned(c_HALF, aux_half_low'length);
        aux_shift     <= (others=>'0');
        new_freq      <= '0';
      elsif auxclk_regs_out.PR_wr = '1' then
        aux_half_high <= unsigned(auxclk_regs_out.PR_hp_width);
        aux_half_low  <= unsigned(auxclk_regs_out.PR_hp_width);
        new_freq      <= '1';
      elsif auxclk_regs_out.DCR_wr = '1' then
        aux_half_low  <= unsigned(auxclk_regs_out.DCR_low_width);
        new_freq      <= '1';
      else
        new_freq <= '0';
      end if;
    end if;
  end process;

  p_pps_align: process(clk_i)
  begin
    if rising_edge(clk_i) then
      if(rst_n_i = '0' or new_freq = '1' or pll_locked_i = '0') then  -- if new_freq or pll lost lock,
                                                -- force alignment to next PPS
        pps_valid_d <= '0';
      elsif(pps_i = '1') then
        pps_valid_d <= pps_valid_i;
      end if;
    end if;
  end process;

  clk_realign <= (not pps_valid_d) and pps_valid_i and pps_i;

  p_word_gen: process(clk_i)
    variable rest  : integer range 0 to 65535;
    variable v_bit : std_logic;
  begin
    if rising_edge(clk_i) then
      if (rst_n_i = '0' or pll_locked_i = '0' or clk_realign = '1') then
        if(aux_shift <= aux_half_high) then
          rest := to_integer(aux_half_high - aux_shift);
          v_bit := '1';
        else
          rest := to_integer(aux_half_low + aux_half_high - aux_shift);
          v_bit := '0';
        end if;
      else
        for i in 0 to c_DATA_W-1 loop
          if(rest /= 0) then
            sd_data(i) <= v_bit;
            rest := rest - 1;
          elsif(v_bit = '1') then
            sd_data(i) <= '0';
            v_bit := '0';
            rest := to_integer(aux_half_low-1); -- because here we already wrote first bit
                                    -- from this group
          elsif(v_bit = '0') then
            sd_data(i) <= '1';
            v_bit := '1';
            rest := to_integer(aux_half_high-1);
          end if;
        end loop;

      end if;
    end if;
  end process;

  sd_data_o <= sd_data;

end behav;
