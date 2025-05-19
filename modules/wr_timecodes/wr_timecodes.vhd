-------------------------------------------------------------------------------
-- Title      : WR core timecode interface
-- Project    : White Rabbit
-------------------------------------------------------------------------------
-- File       : wr_timecode.vhd
-- Author     : Harvey Leicester
-- Company    : CERN BE-CEM-EDL
-- Created    : 2024-11-11
-- Last update: 2024-11-11
-- Platform   : FPGA-generic
-- Standard   : VHDL
-------------------------------------------------------------------------------
-- Description:
-- wr core timecode interface
-- Based on cute-wr by Guanghua Gong
-------------------------------------------------------------------------------
--
-- Copyright (c) 2012 - 2025 CERN / BE-CEM-EDL
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wishbone_pkg.all;
use work.gencores_pkg.all;
use work.timecode_regs_pkg.all;
use work.wr_timecode_pkg.all;

entity wr_timecodes is
  generic (
    g_interface_mode        : t_wishbone_interface_mode      := PIPELINED;
    g_address_granularity   : t_wishbone_address_granularity := BYTE;
    g_ref_clock_rate        : integer := 62500;
    g_serdes_data_width     : integer := 8;
    g_timecode_config       : t_wr_timecode_config := c_WR_TIMECODE_NONE
  );
  port (

    clk_sys_i   : in std_logic;
    clk_ref_i   : in std_logic;
    rst_sys_n_i : in std_logic;
    rst_ref_n_i : in std_logic;

    --ref clock domain
    pps_valid_i : in std_logic := '0';
    pps_pre_i   : in std_logic := '0';
    pps_i       : in std_logic := '0';

    --sys clk domain
    pll_serdes_locked_i : in std_logic := '0';

    --wb
    wb_i        : in t_wishbone_slave_in;
    wb_o        : out t_wishbone_slave_out;

    --outputs
    utc_o        : out t_utc_out;
    aux_timing_o : out t_aux_timing_out
  );
end entity wr_timecodes;

architecture rtl of wr_timecodes is

  signal wb_in  : t_wishbone_slave_in;
  signal wb_out : t_wishbone_slave_out;

  signal nmea_wb_in : t_wishbone_slave_in;
  signal nmea_wb_out : t_wishbone_slave_out;

  signal auxclk_wb_in : t_wishbone_slave_in;
  signal auxclk_wb_out : t_wishbone_slave_out;

  signal timecode_regs_in  : t_timecode_regs_master_in;
  signal timecode_regs_out : t_timecode_regs_master_out;

  signal utc_out : t_utc_out;
  signal aux_timing_out : t_aux_timing_out;

  signal auxclk_adr_out         : std_logic_vector(2 downto 2);
  signal auxclk_adr_out_resize  : std_logic_vector(31 downto 0);

  signal nmea_adr_out         : std_logic_vector(3 downto 2);
  signal nmea_adr_out_resize  : std_logic_vector(31 downto 0);

  signal utc_valid_ref        : std_logic;
  signal utc_year_ref         : std_logic_vector(11 downto 0);
  signal utc_diy_ref          : std_logic_vector(8 downto 0);
  signal utc_month_ref        : std_logic_vector(3 downto 0);
  signal utc_day_ref          : std_logic_vector(4 downto 0);
  signal utc_hour_ref         : std_logic_vector(5 downto 0);
  signal utc_min_ref          : std_logic_vector(5 downto 0);
  signal utc_sec_ref          : std_logic_vector(5 downto 0);
  signal utc_sbs_ref          : std_logic_vector(16 downto 0);

  signal utc_bcd_valid : std_logic;
  signal utc_bcd_year  : std_logic_vector(15 downto 0);
  signal utc_bcd_diy   : std_logic_vector(11 downto 0);
  signal utc_bcd_month : std_logic_vector(7 downto 0);
  signal utc_bcd_day   : std_logic_vector(7 downto 0);
  signal utc_bcd_hour  : std_logic_vector(7 downto 0);
  signal utc_bcd_min   : std_logic_vector(7 downto 0);
  signal utc_bcd_sec   : std_logic_vector(7 downto 0);

  signal tai_next : std_logic_vector(39 downto 0);
  signal tai_curr : std_logic_vector(39 downto 0);

  signal utc_bcd_valid_out : std_logic;

  signal ls_val_ref   : std_logic_vector(7 downto 0);
  signal ls_flag_ref  : std_logic_vector(1 downto 0);
  signal ls_valid_ref : std_logic;

  signal tx_en          : std_logic;
  signal irig_out       : std_logic;
  signal irig_valid     : std_logic;
  signal nmea_out       : std_logic;
  signal nmea_valid     : std_logic;
  signal auxclk_sd_out  : std_logic_vector(7 downto 0);
  signal auxclk_sd_valid   : std_logic;

  signal valid_out : std_logic;

begin

  U_Adapter : wb_slave_adapter
  generic map
  (
    g_master_use_struct  => true,
    g_master_mode        => CLASSIC,
    g_master_granularity => WORD,
    g_slave_use_struct   => true,
    g_slave_mode         => g_interface_mode,
    g_slave_granularity  => g_address_granularity
  )
  port map
  (
    clk_sys_i => clk_sys_i,
    rst_n_i   => rst_sys_n_i,
    slave_i   => wb_i,
    slave_o   => wb_o,
    master_i  => wb_out,
    master_o  => wb_in
  );

  U_timecode_regs: entity work.timecode_regs
  port map
  (
    rst_n_i         => rst_sys_n_i,
    clk_i           => clk_sys_i,
    wb_cyc_i        => wb_in.cyc,
    wb_stb_i        => wb_in.stb,
    wb_adr_i        => wb_in.adr(4 downto 0),
    wb_sel_i        => wb_in.sel,
    wb_we_i         => wb_in.we,
    wb_dat_i        => wb_in.dat,
    wb_ack_o        => wb_out.ack,
    wb_err_o        => wb_out.err,
    wb_rty_o        => wb_out.rty,
    wb_stall_o      => wb_out.stall,
    wb_dat_o        => wb_out.dat,
    timecode_regs_i => timecode_regs_in,
    timecode_regs_o => timecode_regs_out,

    --auxclk interface
    auxclk_cyc_o    => auxclk_wb_in.cyc,
    auxclk_stb_o    => auxclk_wb_in.stb,
    auxclk_adr_o    => auxclk_adr_out,
    auxclk_sel_o    => auxclk_wb_in.sel,
    auxclk_we_o     => auxclk_wb_in.we,
    auxclk_dat_o    => auxclk_wb_in.dat,
    auxclk_ack_i    => auxclk_wb_out.ack,
    auxclk_err_i    => auxclk_wb_out.err,
    auxclk_rty_i    => auxclk_wb_out.rty,
    auxclk_stall_i  => auxclk_wb_out.stall,
    auxclk_dat_i    => auxclk_wb_out.dat,

    --nmea interface
    nmea_cyc_o    => nmea_wb_in.cyc,
    nmea_stb_o    => nmea_wb_in.stb,
    nmea_adr_o    => nmea_adr_out,
    nmea_sel_o    => nmea_wb_in.sel,
    nmea_we_o     => nmea_wb_in.we,
    nmea_dat_o    => nmea_wb_in.dat,
    nmea_ack_i    => nmea_wb_out.ack,
    nmea_err_i    => nmea_wb_out.err,
    nmea_rty_i    => nmea_wb_out.rty,
    nmea_stall_i  => nmea_wb_out.stall,
    nmea_dat_i    => nmea_wb_out.dat
  );

--------------------------------------------------------------------------------
-- irig
--------------------------------------------------------------------------------
  gen_irig: if g_timecode_config(c_WITH_IRIG_IDX) generate

    U_irig: entity work.wr_irig_master
    generic map
    (
      g_clks_per_ms => g_ref_clock_rate/1000
    )
    port map
    (
      clk_i   => clk_ref_i,
      rst_n_i => rst_ref_n_i,
      irig_o  => irig_out,

      secs_i  => utc_bcd_sec,
      mins_i  => utc_bcd_min,
      hrs_i   => utc_bcd_hour,
      days_i  => utc_bcd_diy(9 downto 0),
      year_i  => utc_bcd_year(7 downto 0), --0-99
      ctrl0_i => (others => '0'),
      ctrl1_i => (others => '0'),
      sbs_i   => utc_sbs_ref,
      valid_i => utc_bcd_valid,
      tx_en_i => tx_en,
      tip_o   => open
    );

    timecode_regs_in.SR_irig_enabled <= '1';
    irig_valid <= '1';

  end generate gen_irig;

  gen_no_irig: if not g_timecode_config(c_WITH_IRIG_IDX) generate

    timecode_regs_in.SR_irig_enabled <= '0';
    irig_out <= '0';
    irig_valid <= '0';

  end generate;

--------------------------------------------------------------------------------
-- nmea
--------------------------------------------------------------------------------
  gen_nmea: if g_timecode_config(c_WITH_NMEA_IDX) generate

    nmea_adr_out_resize(3 downto 2)  <= nmea_adr_out;
    nmea_adr_out_resize(31 downto 4) <= (others => '0');
    nmea_adr_out_resize(1 downto 0)  <= (others => '0');

    nmea_wb_in.adr <= nmea_adr_out_resize;

    U_nmea: entity work.xwr_nmea_master
    generic map
    (
      g_interface_mode      => g_interface_mode,
      g_address_granularity => g_address_granularity,
      g_ref_clock_rate      => g_ref_clock_rate
    )
    port map
    (
      clk_sys_i   => clk_sys_i,
      clk_ref_i   => clk_ref_i,
      rst_sys_n_i => rst_sys_n_i,
      rst_ref_n_i => rst_ref_n_i,

      wb_i        => nmea_wb_in,
      wb_o        => nmea_wb_out,

      sec_i       => utc_bcd_sec,
      min_i       => utc_bcd_min,
      hour_i      => utc_bcd_hour,
      day_i       => utc_bcd_day,
      month_i     => utc_bcd_month,
      year_i      => utc_bcd_year,
      valid_i     => utc_bcd_valid,
      tx_en_i     => tx_en,

      nmea_o      => nmea_out
    );

    timecode_regs_in.SR_nmea_enabled <= '1';
    nmea_valid <= '1';

  end generate gen_nmea;

  gen_no_nmea: if not g_timecode_config(c_WITH_NMEA_IDX) generate

    nmea_out <= '0';
    timecode_regs_in.SR_nmea_enabled <= '0';
    nmea_valid <= '1';

    nmea_wb_out.dat   <= (others => '0');
    nmea_wb_out.stall <= '0';
    nmea_wb_out.err   <= '0';
    nmea_wb_out.rty   <= '0';
    nmea_wb_out.ack   <= '1';


  end generate gen_no_nmea;

--------------------------------------------------------------------------------
-- auxclk
--------------------------------------------------------------------------------
  gen_auxclk: if g_timecode_config(c_WITH_AUXCLK_IDX) generate

    auxclk_adr_out_resize(3 downto 3)  <= auxclk_adr_out;
    auxclk_adr_out_resize(31 downto 4) <= (others => '0');
    auxclk_adr_out_resize(2 downto 0)  <= (others => '0');

    auxclk_wb_in.adr <= auxclk_adr_out_resize;

    U_auxclk: entity work.xwr_auxclk_gen
    generic map
    (
      g_interface_mode      => g_interface_mode,
      g_address_granularity => g_address_granularity,
      g_data_width          => g_serdes_data_width
    )
    port map
    (
      clk_sys_i     => clk_sys_i,
      rst_sys_n_i   => rst_sys_n_i,
      clk_ref_i     => clk_ref_i,
      rst_ref_n_i   => rst_ref_n_i,


      slave_i       => auxclk_wb_in,
      slave_o       => auxclk_wb_out,

      pps_i         => pps_i,
      pps_valid_i   => pps_valid_i,
      pll_locked_i  => pll_serdes_locked_i,

      sd_data_o     => auxclk_sd_out(g_serdes_data_width-1 downto 0)
    );

    timecode_regs_in.SR_auxclk_enabled <= '1';
    auxclk_sd_valid <= '1';

  end generate gen_auxclk;

  gen_no_auxclk: if not g_timecode_config(c_WITH_AUXCLK_IDX) generate

    timecode_regs_in.SR_auxclk_enabled <= '0';

    auxclk_wb_out.dat   <= (others => '0');
    auxclk_wb_out.stall <= '0';
    auxclk_wb_out.err   <= '0';
    auxclk_wb_out.rty   <= '0';
    auxclk_wb_out.ack   <= '1';

    auxclk_sd_out <= (others => '0');
    auxclk_sd_valid <= '0';

  end generate gen_no_auxclk;

--------------------------------------------------------------------------------
--utc fields
--------------------------------------------------------------------------------

  U_utc_timecode: entity work.utc_timecode
  port map
  (

    clk_sys_i       => clk_sys_i,
    clk_ref_i       => clk_ref_i,
    rst_sys_n_i     => rst_sys_n_i,
    rst_ref_n_i     => rst_ref_n_i,

    pps_valid_i     => pps_valid_i,
    pps_pre_i       => pps_pre_i,

    utc_year_sys_i  => timecode_regs_out.NEXT_UTC_Y_utc_year,
    utc_diy_sys_i   => timecode_regs_out.NEXT_UTC_Y_utc_diy,
    utc_month_sys_i => timecode_regs_out.NEXT_UTC_MDHMS_utc_mon,
    utc_day_sys_i   => timecode_regs_out.NEXT_UTC_MDHMS_utc_day,
    utc_hour_sys_i  => timecode_regs_out.NEXT_UTC_MDHMS_utc_hr,
    utc_min_sys_i   => timecode_regs_out.NEXT_UTC_MDHMS_minute,
    utc_sec_sys_i   => timecode_regs_out.NEXT_UTC_MDHMS_second,
    utc_sbs_sys_i   => timecode_regs_out.NEXT_UTC_SBS_utc_sbs,
    ls_val_sys_i    => timecode_regs_out.NEXT_LEAP_SEC_ls_value,
    ls_flag_sys_i(0)=> timecode_regs_out.NEXT_LEAP_SEC_ls_flag59,
    ls_flag_sys_i(1)=> timecode_regs_out.NEXT_LEAP_SEC_ls_flag61,
    ls_valid_sys_i  => timecode_regs_out.NEXT_LEAP_SEC_ls_valid,
    utc_valid_sys_i => timecode_regs_out.CR_valid,

    utc_year_sys_o  => timecode_regs_in.CURR_UTC_Y_utc_year,
    utc_diy_sys_o   => timecode_regs_in.CURR_UTC_Y_utc_diy,
    utc_month_sys_o => timecode_regs_in.CURR_UTC_MDHMS_utc_mon,
    utc_day_sys_o   => timecode_regs_in.CURR_UTC_MDHMS_utc_day,
    utc_hour_sys_o  => timecode_regs_in.CURR_UTC_MDHMS_utc_hr,
    utc_min_sys_o   => timecode_regs_in.CURR_UTC_MDHMS_minute,
    utc_sec_sys_o   => timecode_regs_in.CURR_UTC_MDHMS_second,
    utc_sbs_sys_o   => timecode_regs_in.CURR_UTC_SBS_utc_sbs,
    ls_val_sys_o    => timecode_regs_in.CURR_LEAP_SEC_ls_value,
    ls_flag_sys_o(0)=> timecode_regs_in.CURR_LEAP_SEC_ls_flag59,
    ls_flag_sys_o(1)=> timecode_regs_in.CURR_LEAP_SEC_ls_flag61,
    ls_valid_sys_o  => timecode_regs_in.CURR_LEAP_SEC_ls_valid,
    utc_valid_sys_o => timecode_regs_in.SR_valid,

    utc_valid_ref_o => utc_valid_ref,
    utc_year_ref_o  => utc_year_ref,
    utc_diy_ref_o   => utc_diy_ref,
    utc_month_ref_o => utc_month_ref,
    utc_day_ref_o   => utc_day_ref,
    utc_hour_ref_o  => utc_hour_ref,
    utc_min_ref_o   => utc_min_ref,
    utc_sec_ref_o   => utc_sec_ref,
    utc_sbs_ref_o   => utc_sbs_ref,

    utc_bcd_year_o  => utc_bcd_year,
    utc_bcd_diy_o   => utc_bcd_diy,
    utc_bcd_month_o => utc_bcd_month,
    utc_bcd_day_o   => utc_bcd_day,
    utc_bcd_hour_o  => utc_bcd_hour,
    utc_bcd_min_o   => utc_bcd_min,
    utc_bcd_sec_o   => utc_bcd_sec,
    utc_bcd_valid_o => utc_bcd_valid_out,

    ls_val_ref_o    => ls_val_ref,
    ls_flag_ref_o   => ls_flag_ref,
    ls_valid_ref_o  => ls_valid_ref
  );

  utc_bcd_valid     <= pps_valid_i and utc_bcd_valid_out;

  U_edge_detect: gc_edge_detect
  port map (
    clk_i   => clk_ref_i,
    rst_n_i => rst_ref_n_i,
    data_i  => pps_pre_i,
    pulse_o => tx_en
  );

  --timecode output port
  p_timecode_op: process(clk_ref_i) is
  begin
    if rising_edge(clk_ref_i) then
      utc_o.utc_valid          <= utc_valid_ref;
      utc_o.ls_valid           <= ls_valid_ref;
      if (pps_pre_i = '1') then
        utc_o.utc_sec          <= utc_sec_ref;
        utc_o.utc_min          <= utc_min_ref;
        utc_o.utc_hour         <= utc_hour_ref;
        utc_o.utc_day          <= utc_day_ref;
        utc_o.utc_month        <= utc_month_ref;
        utc_o.utc_year         <= utc_year_ref;
        utc_o.utc_diy          <= utc_diy_ref;
        utc_o.utc_sbs          <= utc_sbs_ref;
        utc_o.ls_flag          <= ls_flag_ref;
        utc_o.ls_val           <= ls_val_ref;
      end if;
    end if;
  end process;

  aux_timing_o.irig             <= irig_out;
  aux_timing_o.irig_valid       <= irig_valid;
  aux_timing_o.nmea             <= nmea_out;
  aux_timing_o.nmea_valid       <= nmea_valid;

  --input select to serdes.  required for auxclk, optional to route/mux irig and nmea through serdes if user wants
  with timecode_regs_out.CR_serdes_ip_sel(1 downto 0) select
    aux_timing_o.serdes_in(g_serdes_data_width-1 downto 0) <= auxclk_sd_out(g_serdes_data_width-1 downto 0) when "00",
                                (others => irig_out) when "01",
                                (others => nmea_out) when "10",
                                auxclk_sd_out(g_serdes_data_width-1 downto 0) when others;

end rtl;
