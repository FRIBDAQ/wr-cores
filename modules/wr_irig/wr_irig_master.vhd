-------------------------------------------------------------------------------
-- SPDX-FileCopyrightText: 2012 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+
-------------------------------------------------------------------------------
-- Title      : WR Switch IRIG master module
-- Project    : White Rabbit
-------------------------------------------------------------------------------
-- File       : wr_irig_master.vhd
-- Author     : Harvey Leicester
-- Company    : CERN BE-CEM-EDL
-- Created    : 2024-11-11
-- Last update: 2024-11-11
-- Platform   : FPGA-generic
-- Standard   : VHDL
-------------------------------------------------------------------------------
-- Description:
-- IRIG-B004 master interface
-- Based on cute-wr by Guanghua Gong
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.gencores_pkg.all;

entity wr_irig_master is
  generic (
    g_clks_per_ms : integer := 62500
  );
  port (
    clk_i     : in std_logic;
    rst_n_i   : in std_logic;
    irig_o    : out std_logic;

    --inputs bcd format
    secs_i        : in std_logic_vector(7 downto 0);  --seconds
    mins_i        : in std_logic_vector(7 downto 0);  --minutes
    hrs_i         : in std_logic_vector(7 downto 0);  --hours
    days_i        : in std_logic_vector(9 downto 0);  --day of year
    year_i        : in std_logic_vector(7 downto 0);  --year
    ctrl0_i       : in std_logic_vector(8 downto 0);  --control function 0
    ctrl1_i       : in std_logic_vector(8 downto 0);  --contorl function 1
    sbs_i         : in std_logic_vector(16 downto 0); --straight binary seconds
    valid_i       : in std_logic;                     --output valid
    tx_en_i       : in std_logic;                     --tx enable (ref clock domain), frame txd 1 cycle after rising edge

    tip_o         : out std_logic                     --transfer in progress
  );
end entity wr_irig_master;

architecture rtl of wr_irig_master is

  constant c_MARKER_MS : integer := 8;
  constant c_HIGH_MS   : integer := 5;
  constant c_LOW_MS    : integer := 2;
  constant c_BIT_PD_MS : integer := 10;
  constant c_FRAME_LEN : integer := 100;

  type t_pulse_state is
  (
    S_IDLE,
    S_HIGH,
    S_LOW
  );

  signal pulse_state : t_pulse_state := S_IDLE;

  signal tick : std_logic;
  signal clk_cnt  : unsigned(16 downto 0);
  signal ms_cnt : unsigned(3 downto 0);
  signal bit_cnt : unsigned(6 downto 0);
  signal tx_en, eof, sof : std_logic;
  signal ms_cnt_rst, bit_cnt_rst : std_logic;
  signal high_pd : unsigned(3 downto 0);
  signal shift_en : std_logic;

  constant c_MARKERS : std_logic_vector(c_FRAME_LEN-1 downto 0) := (0 => '1',
                                                                    9 => '1',
                                                                    19 => '1',
                                                                    29 => '1',
                                                                    39 => '1',
                                                                    49 => '1',
                                                                    59 => '1',
                                                                    69 => '1',
                                                                    79 => '1',
                                                                    89 => '1',
                                                                    99 => '1',
                                                                    others => '0');

  signal frame_d : std_logic_vector(c_FRAME_LEN-1 downto 0);    --data
  signal frame_m : std_logic_vector(c_FRAME_LEN-1 downto 0);    --markers

begin
  u_edge_detect: gc_edge_detect
  port map
  (
    clk_i   => clk_i,
    rst_n_i => rst_n_i,
    data_i  => tx_en_i,
    pulse_o => tx_en
  );

  p_tick_gen: process(clk_i) is
  begin
    if rising_edge(clk_i) then
      if (rst_n_i = '0' or sof = '1') then
        clk_cnt <= (others => '0');
      else
        clk_cnt <= clk_cnt+1;
        if(clk_cnt >= g_clks_per_ms-1) then
          clk_cnt <= (others => '0');
        end if;
      end if;
    end if;
  end process;

  --sample tick
  tick <= '1' when (clk_cnt = g_clks_per_ms-1) else '0';

  p_ms_cnt: process(clk_i) is
  begin
    if rising_edge(clk_i) then
      if (rst_n_i = '0' or ms_cnt_rst = '1') then
        ms_cnt <= (others => '0');
      else
        if(tick = '1') then
          ms_cnt <= ms_cnt+1;
        end if;
      end if;
    end if;
  end process;

  sof <= tx_en and valid_i;
  eof <= '1' when tick = '1' and ms_cnt = c_MARKER_MS-1 and bit_cnt = c_FRAME_LEN-1 else '0';  --falling edge of p0 marker

  p_bit_cnt: process(clk_i) is
  begin
    if rising_edge(clk_i) then
      if (rst_n_i = '0' or bit_cnt_rst = '1') then
        bit_cnt <= (others => '0');
      else
        if(shift_en = '1') then
          bit_cnt <= bit_cnt + 1;
        end if;
      end if;
    end if;
  end process;

  p_pulse_sm: process(clk_i) is
  begin
    if rising_edge(clk_i) then
      if (rst_n_i = '0') then
        pulse_state <= S_IDLE;
        irig_o      <= '0';
        ms_cnt_rst  <= '1';
        bit_cnt_rst <= '1';
        shift_en    <= '0';
      else

        irig_o      <= '0';
        ms_cnt_rst  <= '0';
        bit_cnt_rst <= '0';
        shift_en    <= '0';

        case pulse_state is

          when S_IDLE =>  ms_cnt_rst  <= '1';
                          bit_cnt_rst <= '1';
                          if(sof = '1') then
                            irig_o <= '1';
                            pulse_state <= S_HIGH;
                          end if;

          when S_HIGH =>  irig_o <= '1';
                          if(tick = '1') then
                            if (ms_cnt >= high_pd) then
                              irig_o      <= '0';
                              pulse_state <= S_LOW;
                              if(eof = '1') then
                                ms_cnt_rst  <= '1';
                                bit_cnt_rst <= '1';
                                pulse_state <= S_IDLE;
                              end if;
                            end if;
                          end if;

          when S_LOW  =>  if(tick = '1') then
                            if(ms_cnt >= c_BIT_PD_MS-1) then
                              ms_cnt_rst <= '1';
                              if(eof = '1') then --shouldn't trigger here
                                bit_cnt_rst <= '1';
                                pulse_state <= S_IDLE;
                              else
                                shift_en    <= '1';
                                irig_o      <= '1';
                                pulse_state <= S_HIGH;
                              end if;
                            end if;
                          end if;

          when others => pulse_state <= S_IDLE;
        end case;
      end if;
    end if;
  end process;

  tip_o <= '1' when pulse_state /= S_IDLE else '0';

  p_shift_reg: process(clk_i) is
  begin
    if rising_edge(clk_i) then
      if(rst_n_i = '0') then
        frame_d <= (others => '0');
        frame_m <= c_MARKERS;
      else
        if(sof = '1') then
          frame_d <= (others => '0');
          frame_d(4 downto 1)   <= secs_i(3 downto 0);
          frame_d(8 downto 6)   <= secs_i(6 downto 4);
          frame_d(13 downto 10) <= mins_i(3 downto 0);
          frame_d(17 downto 15) <= mins_i(6 downto 4);
          frame_d(23 downto 20) <= hrs_i(3 downto 0);
          frame_d(26 downto 25) <= hrs_i(5 downto 4);
          frame_d(33 downto 30) <= days_i(3 downto 0);
          frame_d(38 downto 35) <= days_i(7 downto 4);
          frame_d(41 downto 40) <= days_i(9 downto 8);
          frame_d(53 downto 50) <= year_i(3 downto 0);
          frame_d(58 downto 55) <= year_i(7 downto 4);
          frame_d(68 downto 60) <= ctrl0_i(8 downto 0);
          frame_d(78 downto 70) <= ctrl1_i(8 downto 0);
          frame_d(88 downto 80) <= sbs_i(8 downto 0);
          frame_d(97 downto 90) <= sbs_i(16 downto 9);
          frame_m <= c_MARKERS;
        elsif(shift_en = '1') then
          frame_d <= '0' & frame_d(frame_d'length-1 downto 1);
          frame_m <= '0' & frame_m(frame_m'length-1 downto 1);
        end if;
      end if;
    end if;
  end process;

  p_thresh_gen: process(frame_d, frame_m) is
  begin
    high_pd <= to_unsigned(c_MARKER_MS-1, high_pd'length);
    if(frame_m(0) = '1') then
      high_pd <= to_unsigned(c_MARKER_MS-1, high_pd'length);
    elsif(frame_d(0) = '1') then
      high_pd <= to_unsigned(c_HIGH_MS-1, high_pd'length);
    else
      high_pd <= to_unsigned(c_LOW_MS-1, high_pd'length);
    end if;
  end process;

end architecture;
