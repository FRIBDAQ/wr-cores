-------------------------------------------------------------------------------
-- SPDX-FileCopyrightText: 2012 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+
-------------------------------------------------------------------------------
-- Title      : UTC timecode
-- Project    : White Rabbit
-------------------------------------------------------------------------------
-- File       : utc_timecode.vhd
-- Author     : Harvey Leicester
-- Company    : CERN BE-CEM-EDL
-- Created    : 2024-11-11
-- Last update: 2024-11-11
-- Platform   : FPGA-generic
-- Standard   : VHDL
-------------------------------------------------------------------------------
-- Description:
-- double buffer for utc timecodes
-- take utc from sw (clk_sys domain), cross to clk_ref domain
-- and convert to BCD format for auxiliary timing outputs (NMEA, IRIG-B)
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wishbone_pkg.all;
use work.gencores_pkg.all;

entity utc_timecode is
  port (

    clk_sys_i : in std_logic;
    clk_ref_i : in std_logic;
    rst_sys_n_i : in std_logic;
    rst_ref_n_i : in std_logic;

    --ref clk domain
    pps_valid_i : in std_logic := '0';
    pps_pre_i   : in std_logic := '0';

    --sys clk domain
    utc_year_sys_i  : in std_logic_vector(11 downto 0); --year value
    utc_diy_sys_i   : in std_logic_vector(8 downto 0);  --day in year value
    utc_month_sys_i : in std_logic_vector(3 downto 0);  --month value
    utc_day_sys_i   : in std_logic_vector(4 downto 0);  --day value
    utc_hour_sys_i  : in std_logic_vector(5 downto 0);  --hour value
    utc_min_sys_i   : in std_logic_vector(5 downto 0);  --minute value
    utc_sec_sys_i   : in std_logic_vector(5 downto 0);  --second value
    utc_sbs_sys_i   : in std_logic_vector(16 downto 0); --straight binary seconds value
    ls_val_sys_i    : in std_logic_vector(7 downto 0);  --leap seconds value
    ls_flag_sys_i   : in std_logic_vector(1 downto 0);  --leap seconds flags (0)=59, (1)=61
    ls_valid_sys_i  : in std_logic;                     --leap seconds fields are valid
    utc_valid_sys_i : in std_logic;                     --utc fields are valid

    utc_year_sys_o  : out std_logic_vector(11 downto 0);
    utc_diy_sys_o   : out std_logic_vector(8 downto 0);
    utc_month_sys_o : out std_logic_vector(3 downto 0);
    utc_day_sys_o   : out std_logic_vector(4 downto 0);
    utc_hour_sys_o  : out std_logic_vector(5 downto 0);
    utc_min_sys_o   : out std_logic_vector(5 downto 0);
    utc_sec_sys_o   : out std_logic_vector(5 downto 0);
    utc_sbs_sys_o   : out std_logic_vector(16 downto 0);
    ls_val_sys_o    : out std_logic_vector(7 downto 0);
    ls_flag_sys_o   : out std_logic_vector(1 downto 0);
    ls_valid_sys_o  : out std_logic;
    utc_valid_sys_o : out std_logic;

    --ref clk domain
    utc_valid_ref_o : out std_logic;
    utc_year_ref_o  : out std_logic_vector(11 downto 0);
    utc_diy_ref_o   : out std_logic_vector(8 downto 0);
    utc_month_ref_o : out std_logic_vector(3 downto 0);
    utc_day_ref_o   : out std_logic_vector(4 downto 0);
    utc_hour_ref_o  : out std_logic_vector(5 downto 0);
    utc_min_ref_o   : out std_logic_vector(5 downto 0);
    utc_sec_ref_o   : out std_logic_vector(5 downto 0);
    utc_sbs_ref_o   : out std_logic_vector(16 downto 0);

    --bcd outputs, ref clock domain
    utc_bcd_year_o  : out std_logic_vector(15 downto 0);
    utc_bcd_diy_o   : out std_logic_vector(11 downto 0);
    utc_bcd_month_o : out std_logic_vector(7 downto 0);
    utc_bcd_day_o   : out std_logic_vector(7 downto 0);
    utc_bcd_hour_o  : out std_logic_vector(7 downto 0);
    utc_bcd_min_o   : out std_logic_vector(7 downto 0);
    utc_bcd_sec_o   : out std_logic_vector(7 downto 0);
    utc_bcd_valid_o : out std_logic;

    --leap second outputs
    ls_val_ref_o      : out std_logic_vector(7 downto 0);
    ls_flag_ref_o     : out std_logic_vector(1 downto 0);
    ls_valid_ref_o    : out std_logic
  );
end entity utc_timecode;

architecture rtl of utc_timecode is

  signal utc_valid_sys : std_logic;
  signal pps_valid_sys : std_logic;
  signal pps_pre_sys   : std_logic;

  signal utc_valid_p_ref   : std_logic;
  signal utc_valid_ref_reg : std_logic;
  signal ls_valid_p_ref  : std_logic;
  signal ls_valid_ref_reg : std_logic;

  signal utc_valid_ref : std_logic;
  signal utc_year_ref  : std_logic_vector(11 downto 0);
  signal utc_diy_ref   : std_logic_vector(8 downto 0);
  signal utc_month_ref : std_logic_vector(3 downto 0);
  signal utc_day_ref   : std_logic_vector(4 downto 0);
  signal utc_hour_ref  : std_logic_vector(5 downto 0);
  signal utc_min_ref   : std_logic_vector(5 downto 0);
  signal utc_sec_ref   : std_logic_vector(5 downto 0);
  signal utc_sbs_ref   : std_logic_vector(16 downto 0);

  signal ls_val_ref   : std_logic_vector(7 downto 0);
  signal ls_flag_ref  : std_logic_vector(1 downto 0);
  signal ls_valid_ref : std_logic;
begin

  utc_valid_sys <= pps_valid_sys and utc_valid_sys_i;

  U_sync_ls_valid: gc_sync_ffs
    port map (
      clk_i     => clk_ref_i,
      rst_n_i   => rst_ref_n_i,
      data_i    => ls_valid_sys_i,
      synced_o  => ls_valid_ref,
      ppulse_o  => ls_valid_p_ref
    );

  U_sync_pps_valid: gc_sync
    port map (
      clk_i     => clk_sys_i,
      rst_n_a_i => rst_sys_n_i,
      d_i       => pps_valid_i,
      q_o       => pps_valid_sys
    );

  U_sync_utc_valid: gc_sync_ffs
    port map (
      clk_i     => clk_ref_i,
      rst_n_i   => rst_ref_n_i,
      data_i    => utc_valid_sys,
      synced_o  => utc_valid_ref,
      ppulse_o  => utc_valid_p_ref
    );

  --intention is that utc_valid_sys set when all utc_sys fields are stable
  --sync this to clk_ref and use as en for clk_ref regs
  p_sync_utc_regs: process(clk_ref_i) is
  begin
    if rising_edge(clk_ref_i) then
      if(rst_ref_n_i = '0') then
        utc_year_ref  <= (others => '0');
        utc_diy_ref   <= (others => '0');
        utc_month_ref <= (others => '0');
        utc_day_ref   <= (others => '0');
        utc_hour_ref  <= (others => '0');
        utc_min_ref   <= (others => '0');
        utc_sec_ref   <= (others => '0');
        utc_sbs_ref   <= (others => '0');
      else
        if(utc_valid_p_ref = '1') then
          utc_year_ref  <= utc_year_sys_i;
          utc_diy_ref   <= utc_diy_sys_i;
          utc_month_ref <= utc_month_sys_i;
          utc_day_ref   <= utc_day_sys_i;
          utc_hour_ref  <= utc_hour_sys_i;
          utc_min_ref   <= utc_min_sys_i;
          utc_sec_ref   <= utc_sec_sys_i;
          utc_sbs_ref   <= utc_sbs_sys_i;
        end if;
      end if;
    end if;
  end process;

  --register to align with utc_ref regs
  p_utc_valid_reg: process(clk_ref_i) is
  begin
    if rising_edge(clk_ref_i) then
      utc_valid_ref_reg <= utc_valid_ref;
    end if;
  end process;

  --same for leap seconds
  p_sync_ls_regs: process(clk_ref_i) is
  begin
    if rising_edge(clk_ref_i) then
      if(rst_ref_n_i = '0') then
        ls_val_ref   <= (others => '0');
        ls_flag_ref  <= (others => '0');
      else
        if(ls_valid_p_ref = '1') then
          ls_val_ref  <= ls_val_sys_i;
          ls_flag_ref <= ls_flag_sys_i;
        end if;
      end if;
    end if;
  end process;

  p_ls_valid_reg: process(clk_ref_i) is
  begin
    if rising_edge(clk_ref_i) then
      ls_valid_ref_reg <= ls_valid_ref;
    end if;
  end process;

  --bcd formatting
  U_utc2bcd: entity work.utc2bcd
  port map
  (
    rst_n_i         => rst_ref_n_i,
    clk_i           => clk_ref_i,

    utc_hex_valid_i => utc_valid_ref_reg,
    year_hex_i      => utc_year_ref,
    diy_hex_i       => utc_diy_ref,
    month_hex_i     => utc_month_ref,
    day_hex_i       => utc_day_ref,
    hour_hex_i      => utc_hour_ref,
    min_hex_i       => utc_min_ref,
    sec_hex_i       => utc_sec_ref,

    utc_bcd_valid_o => utc_bcd_valid_o,
    year_bcd_o      => utc_bcd_year_o,
    diy_bcd_o       => utc_bcd_diy_o,
    month_bcd_o     => utc_bcd_month_o,
    day_bcd_o       => utc_bcd_day_o,
    hour_bcd_o      => utc_bcd_hour_o,
    min_bcd_o       => utc_bcd_min_o,
    sec_bcd_o       => utc_bcd_sec_o
  );

  U_sync_pps_pre: gc_sync
    port map (
      clk_i     => clk_sys_i,
      rst_n_a_i => rst_sys_n_i,
      d_i       => pps_pre_i,
      q_o       => pps_pre_sys
    );

  --loopback for read regs
  p_read_regs: process(clk_sys_i) is
  begin
    if rising_edge(clk_sys_i) then
      utc_valid_sys_o     <= utc_valid_sys;
      ls_valid_sys_o      <= ls_valid_sys_i;
      if (pps_pre_sys = '1') then
          utc_sec_sys_o   <= utc_sec_sys_i;
          utc_min_sys_o   <= utc_min_sys_i;
          utc_hour_sys_o  <= utc_hour_sys_i;
          utc_day_sys_o   <= utc_day_sys_i;
          utc_month_sys_o <= utc_month_sys_i;
          utc_year_sys_o  <= utc_year_sys_i;
          utc_diy_sys_o   <= utc_diy_sys_i;
          utc_sbs_sys_o   <= utc_sbs_sys_i;
          ls_val_sys_o    <= ls_val_sys_i;
          ls_flag_sys_o   <= ls_flag_sys_i;
          ls_valid_sys_o  <= ls_valid_sys_i;
      end if;
    end if;
  end process;

  --clk_ref domain outputs
  utc_year_ref_o    <= utc_year_ref;
  utc_diy_ref_o     <= utc_diy_ref;
  utc_month_ref_o   <= utc_month_ref;
  utc_day_ref_o     <= utc_day_ref;
  utc_hour_ref_o    <= utc_hour_ref;
  utc_min_ref_o     <= utc_min_ref;
  utc_sec_ref_o     <= utc_sec_ref;
  utc_sbs_ref_o     <= utc_sbs_ref;
  utc_valid_ref_o   <= utc_valid_ref_reg;
  ls_val_ref_o      <= ls_val_ref;
  ls_flag_ref_o     <= ls_flag_ref;
  ls_valid_ref_o    <= ls_valid_ref_reg;

end rtl;
