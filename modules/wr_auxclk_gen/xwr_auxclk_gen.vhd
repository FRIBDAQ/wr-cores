-------------------------------------------------------------------------------
-- SPDX-FileCopyrightText: 2014 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+
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

entity xwr_auxclk_gen is
  generic (
    g_interface_mode      : t_wishbone_interface_mode      := PIPELINED;
    g_address_granularity : t_wishbone_address_granularity := WORD;
    g_data_width          : natural := 8
  );
  port (
    rst_sys_n_i     : in std_logic;
    clk_sys_i       : in std_logic;
    rst_ref_n_i     : in std_logic;
    clk_ref_i       : in std_logic;

    pps_i           : in std_logic;
    pps_valid_i     : in std_logic;
    pll_locked_i    : in std_logic;

    sd_data_o       : out std_logic_vector(g_data_width-1 downto 0);

    slave_i         : in  t_wishbone_slave_in := cc_dummy_slave_in;
    slave_o         : out t_wishbone_slave_out);
end entity xwr_auxclk_gen;

architecture behav of xwr_auxclk_gen is

  constant c_DATA_W : integer := g_data_width;
  constant c_HALF   : integer := 25;-- default high/low width for 10MHz

  signal sd_data : std_logic_vector(g_data_width-1 downto 0);

  signal wb_in  : t_wishbone_slave_in;
  signal wb_out : t_wishbone_slave_out;

  signal aux_half_high: std_logic_vector(15 downto 0);
  signal aux_half_low : std_logic_vector(15 downto 0);
  signal pps_valid_d  : std_logic;
  signal clk_realign  : std_logic;
  signal new_freq     : std_logic;
  signal auxclk_regs_in  : t_auxclk_regs_master_in;
  signal auxclk_regs_out : t_auxclk_regs_master_out;
  signal dcr_ref : std_logic_vector(auxclk_regs_out.DCR_low_width'length-1 downto 0);
  signal dcr_wr  : std_logic;
  signal pr_ref  : std_logic_vector(auxclk_regs_out.PR_hp_width'length-1 downto 0);
  signal pr_wr   : std_logic;

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
      clk_sys_i => clk_sys_i,
      rst_n_i   => rst_sys_n_i,
      slave_i   => slave_i,
      slave_o   => slave_o,
      master_i  => wb_out,
      master_o  => wb_in);

  U_WB_IF: entity work.auxclk_gen_regs
  port map (
    rst_n_i => rst_sys_n_i,
    clk_i   => clk_sys_i,
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
    auxclk_regs_i => auxclk_regs_in,
    auxclk_regs_o => auxclk_regs_out
  );

  p_read_regs: process(clk_sys_i) is
  begin
    if rising_edge(clk_sys_i) then
      if (rst_sys_n_i = '0') then
        auxclk_regs_in.DCR_low_width <= std_logic_vector(to_unsigned(c_HALF, aux_half_high'length));
        auxclk_regs_in.PR_hp_width   <= std_logic_vector(to_unsigned(c_HALF, aux_half_high'length));
      else
        if (auxclk_regs_out.DCR_wr = '1') then
          auxclk_regs_in.DCR_low_width <= auxclk_regs_out.DCR_low_width;
        elsif(auxclk_regs_out.PR_wr = '1') then
          auxclk_regs_in.PR_hp_width   <= auxclk_regs_out.PR_hp_width;
        end if;
      end if;
    end if;
  end process;

  U_sync_pr: gc_sync_word_wr
    generic map (
      g_width => auxclk_regs_out.PR_hp_width'length
    )
    port map (
      clk_in_i     => clk_sys_i,
      rst_in_n_i   => rst_sys_n_i,
      clk_out_i    => clk_ref_i,
      rst_out_n_i  => rst_ref_n_i,
      data_i       => auxclk_regs_out.PR_hp_width,
      wr_i         => auxclk_regs_out.PR_wr,
      data_o       => pr_ref,
      wr_o         => pr_wr
    );

  U_sync_dcr: gc_sync_word_wr
    generic map (
      g_width => auxclk_regs_out.DCR_low_width'length
    )
    port map (
      clk_in_i     => clk_sys_i,
      rst_in_n_i   => rst_sys_n_i,
      clk_out_i    => clk_ref_i,
      rst_out_n_i  => rst_ref_n_i,
      data_i       => auxclk_regs_out.DCR_low_width,
      wr_i         => auxclk_regs_out.DCR_wr,
      data_o       => dcr_ref,
      wr_o         => dcr_wr
    );

  p_pw_settings: process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if (rst_ref_n_i = '0') then
        aux_half_high <= std_logic_vector(to_unsigned(c_HALF, aux_half_high'length));
        aux_half_low  <= std_logic_vector(to_unsigned(c_HALF, aux_half_low'length));
        new_freq      <= '0';
      else
        new_freq <= pr_wr or dcr_wr;
        if (pr_wr = '1') then
          aux_half_high <= pr_ref;
          aux_half_low  <= pr_ref;
        elsif (dcr_wr = '1') then
          aux_half_low  <= dcr_ref;
        end if;
      end if;
    end if;
  end process;

  p_pps_align: process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if(rst_ref_n_i = '0' or new_freq = '1' or pll_locked_i = '0') then  -- if new_freq or pll lost lock, force alignment to next PPS
        pps_valid_d <= '0';
      elsif(pps_i = '1') then
        pps_valid_d <= pps_valid_i;
      end if;
    end if;
  end process;

  clk_realign <= (not pps_valid_d) and pps_valid_i and pps_i;

  p_word_gen: process(clk_ref_i)
    variable rest  : integer range 0 to 65535;
    variable v_bit : std_logic;
  begin
    if rising_edge(clk_ref_i) then
      if (rst_ref_n_i = '0' or pll_locked_i = '0' or clk_realign = '1') then
          rest := to_integer(unsigned(aux_half_high));
          v_bit := '1';
      else
        for i in 0 to c_DATA_W-1 loop
          if(rest /= 0) then
            sd_data(i) <= v_bit;
            rest := rest - 1;
          elsif(v_bit = '1') then
            sd_data(i) <= '0';
            v_bit := '0';
            rest := to_integer(unsigned(aux_half_low)-1); -- because here we already wrote first bit from this group
          elsif(v_bit = '0') then
            sd_data(i) <= '1';
            v_bit := '1';
            rest := to_integer(unsigned(aux_half_high)-1);
          end if;
        end loop;
      end if;
    end if;
  end process;

  sd_data_o <= sd_data;

end behav;
