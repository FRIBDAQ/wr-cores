-------------------------------------------------------------------------------
-- Title      : WRPC reference design for KR260 board
-- Project    : WR PTP Core
-- URL        : http://www.ohwr.org/projects/wr-cores/wiki/Wrpc_core
-------------------------------------------------------------------------------
-- Company    : CERN (BE-CO-HT)
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Copyright (c) 2024 CERN
-------------------------------------------------------------------------------
-- GNU LESSER GENERAL PUBLIC LICENSE
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

library unisim;
use unisim.vcomponents.all;

entity xwrc_gthe4_rxpi is
  generic (
    --  If True, use QPLL sdm to tune the GTHe4 ref clock.
    --  If False, the ref clock must be tuned externally using dac_dpll interface
    g_use_sdm     : boolean := True
    );
  port (
    --  System clock (same as WR core clk_sys)
    clk_62m5_i  : in std_logic;
    rst_n_i     : in std_logic;

    --  WB bus to the WR core [clk_62m5_i]
    wb_aux_i: in  t_wishbone_slave_in;
    wb_aux_o: out t_wishbone_slave_out;

    --  txoutclk clock from GTHe4 (after buf_gt), at 62.5Mhz
    tx_out_clk_i : in std_logic;
    rx_out_clk_i : in std_logic;

    -- dmonitor signal from GTHe4
    dmonitorout_i : in std_logic_vector(15 downto 0);
    gth_dmon_clk_i : in std_logic;

    --  rxpi output
    rxpi_valid_o : out std_logic;
    rxpi_data_o : out std_logic_vector(31 downto 0);

    --  WR dac input
    mpll_data_i : in  std_logic_vector(15 downto 0) := (others => '0');
    hpll_data_i : in  std_logic_vector(31 downto 0) := (others => '0');
    hpll_load_i : in  std_logic := '0';
    mpll_load_i : in  std_logic := '0';

    --  sdm output
    mpll_data_o   : out std_logic_vector(24 downto 0);
    mpll_toggle_o : out std_logic;
    hpll_data_o   : out std_logic_vector(24 downto 0);
    hpll_toggle_o : out std_logic;

    --  phy ready (async)
    phy_rdy_i : in std_logic;
    phy_rdy_o : out std_logic;

    --  Phy control
    rxpmareset_o : out std_logic;
    bitslide_val_i : std_logic_vector(4 downto 0);

    --  Not used by SW, extra.
    gth_rst_o : out std_logic;
    gth_tx_rst_o : out std_logic;
    gth_rx_rst_o : out std_logic;
    rxbufreset_o : out std_logic;
    rxpcsreset_o : out std_logic;
    txpcsreset_o : out std_logic;
    txpmareset_o : out std_logic;
    gth_status_i : std_logic_vector(15 downto 0) := (others => '0')
  );
end;

architecture top of xwrc_gthe4_rxpi is
  signal gth_rst, gth_rst_n: std_logic;

  signal hpll_cnt, mpll_cnt : unsigned(5 downto 0);

  signal gth_dmon_rst_n : std_logic;

  signal rxpi_nsamp : std_logic_vector(31 downto 0);
  signal rxpi_shift : std_logic_vector(31 downto 0);
  signal rxpi_reset, rxpi_reset_dmon : std_logic;

  signal phy_rdy_in_62m5 : std_logic;

  --  For phase shift
  signal ps_clk_fb, ps_clk_fb_bufg : std_logic;
  signal ps_clk_in_stopped, ps_clk_fb_stopped : std_logic;
  signal clk_ps_out, clk_ps : std_logic;
  signal ps_clk_locked, ps_clk_pd, ps_clk_rst, ps_clk_rst_n : std_logic;
  signal ps_clk_pen, ps_clk_done, ps_clk_incdec, ps_clk_busy : std_logic;
  signal ps_clk_shift, ps_clk_shift_wr : std_logic;
  signal ps_clk_phase : unsigned(15 downto 0);

  signal ps_clk_nsamp : std_logic_vector(23 downto 0);
  signal rxoutclk_sync : std_logic;
  signal ps_clk_nsamp_cnt, ps_clk_count, ps_clk_count_out : unsigned(23 downto 0);
  signal ps_clk_gen : unsigned(7 downto 0);

begin
  --  MMCM for phase shift
  --  Input: ref clock
  --  Output: shifted version of ref clock
  --  VCO: 1250Mhz (x20)
  inst_mmcm_ps : MMCME4_ADV
    generic map (
      BANDWIDTH => "OPTIMIZED",  -- Jitter programming
      CLKFBOUT_MULT_F => 20.0,    -- Multiply value for all CLKOUT
      CLKFBOUT_PHASE => 0.0,     -- Phase offset in degrees of CLKFB
      CLKFBOUT_USE_FINE_PS => "FALSE", -- Fine phase shift enable (TRUE/FALSE)
      CLKIN1_PERIOD => 16.0,            -- Input clock period in ns to ps resolution (i.e., 33.333 is 30 MHz).
      CLKIN2_PERIOD => 0.0,            -- Input clock period in ns to ps resolution (i.e., 33.333 is 30 MHz).
      CLKOUT0_DIVIDE_F => 20.0,        -- Divide amount for CLKOUT0
      CLKOUT0_DUTY_CYCLE => 0.5,       -- Duty cycle for CLKOUT0
      CLKOUT0_PHASE => 0.0,            -- Phase offset for CLKOUT0
      CLKOUT0_USE_FINE_PS => "TRUE",   -- Fine phase shift enable (TRUE/FALSE)
      CLKOUT1_DIVIDE => 1,             -- Divide amount for CLKOUT (1-128)
      CLKOUT1_DUTY_CYCLE => 0.5,       -- Duty cycle for CLKOUT outputs (0.001-0.999).
      CLKOUT1_PHASE => 0.0,            -- Phase offset for CLKOUT outputs (-360.000-360.000).
      CLKOUT1_USE_FINE_PS => "FALSE",
      CLKOUT2_DIVIDE => 1,
      CLKOUT2_DUTY_CYCLE => 0.5,
      CLKOUT2_PHASE => 0.0,
      CLKOUT2_USE_FINE_PS => "FALSE",
      CLKOUT3_DIVIDE => 1,
      CLKOUT3_DUTY_CYCLE => 0.5,
      CLKOUT3_PHASE => 0.0,
      CLKOUT3_USE_FINE_PS => "FALSE",
      CLKOUT4_CASCADE => "FALSE",
      CLKOUT4_DIVIDE => 1,
      CLKOUT4_DUTY_CYCLE => 0.5,
      CLKOUT4_PHASE => 0.0,
      CLKOUT4_USE_FINE_PS => "FALSE",
      CLKOUT5_DIVIDE => 1,
      CLKOUT5_DUTY_CYCLE => 0.5,
      CLKOUT5_PHASE => 0.0,
      CLKOUT5_USE_FINE_PS => "FALSE",
      CLKOUT6_DIVIDE => 1,
      CLKOUT6_DUTY_CYCLE => 0.5,
      CLKOUT6_PHASE => 0.0,
      CLKOUT6_USE_FINE_PS => "FALSE",
      COMPENSATION => "AUTO",            -- Clock input compensation
      DIVCLK_DIVIDE => 1,                -- Master division value
      IS_CLKFBIN_INVERTED => '0',
      IS_CLKIN1_INVERTED => '0',
      IS_CLKIN2_INVERTED => '0',
      IS_CLKINSEL_INVERTED => '0',
      IS_PSEN_INVERTED => '0',
      IS_PSINCDEC_INVERTED => '0',
      IS_PWRDWN_INVERTED => '0',
      IS_RST_INVERTED => '0',
      REF_JITTER1 => 0.0,
      REF_JITTER2 => 0.0,
      SS_EN => "FALSE",
      SS_MODE => "CENTER_HIGH",
      SS_MOD_PERIOD => 10000,
      STARTUP_WAIT => "FALSE"
      )
    port map (
      CDDCDONE => open, -- 1-bit output: Clock dynamic divide done
      CLKFBOUT => ps_clk_fb, -- 1-bit output: Feedback clock
      CLKFBOUTB => open, -- 1-bit output: Inverted CLKFBOUT
      CLKFBSTOPPED => ps_clk_fb_stopped, -- 1-bit output: Feedback clock stopped
      CLKINSTOPPED => ps_clk_in_stopped, -- 1-bit output: Input clock stopped
      CLKOUT0 => clk_ps_out,   -- 1-bit output: CLKOUT0
      CLKOUT0B => open, -- 1-bit output: Inverted CLKOUT0
      CLKOUT1  => open,   -- 1-bit output: CLKOUT1
      CLKOUT1B => open, -- 1-bit output: Inverted CLKOUT1
      CLKOUT2  => open,   -- 1-bit output: CLKOUT2
      CLKOUT2B => open, -- 1-bit output: Inverted CLKOUT2
      CLKOUT3  => open,   -- 1-bit output: CLKOUT3
      CLKOUT3B => open, -- 1-bit output: Inverted CLKOUT3
      CLKOUT4  => open,   -- 1-bit output: CLKOUT4
      CLKOUT5  => open,   -- 1-bit output: CLKOUT5
      CLKOUT6  => open,   -- 1-bit output: CLKOUT6
      DO => open,             -- 16-bit output: DRP data output
      DRDY =>  open,         -- 1-bit output: DRP ready
      LOCKED => ps_clk_locked,     -- 1-bit output: LOCK
      PSDONE => ps_clk_done,     -- 1-bit output: Phase shift done
      CDDCREQ => '0',   -- 1-bit input: Request to dynamic divide clock
      CLKFBIN => ps_clk_fb_bufg,   -- 1-bit input: Feedback clock
      CLKIN1 => tx_out_clk_i,     -- 1-bit input: Primary clock
      CLKIN2 => '0',     -- 1-bit input: Secondary clock
      CLKINSEL => '1', -- 1-bit input: Clock select, High=CLKIN1 Low=CLKIN2
      DADDR => (others => '0'),       -- 7-bit input: DRP address
      DCLK => '0',         -- 1-bit input: DRP clock
      DEN => '0',           -- 1-bit input: DRP enable
      DI => (others => '0'),             -- 16-bit input: DRP data input
      DWE => '0',           -- 1-bit input: DRP write enable
      PSCLK => clk_62m5_i,        -- 1-bit input: Phase shift clock
      PSEN => ps_clk_pen,         -- 1-bit input: Phase shift enable
      PSINCDEC => ps_clk_incdec,  -- 1-bit input: Phase shift inc/dec
      PWRDWN => ps_clk_pd,        -- 1-bit input: Power-down
      RST => ps_clk_rst           -- 1-bit input: Reset
      );

  inst_bufg_ps : BUFG
    port map (
      I => clk_ps_out,
      O => clk_ps
    );

  inst_bufg_ps_fb: BUFG
    port map (
      I => ps_clk_fb,
      O => ps_clk_fb_bufg
    );

  gen_sdm: if g_use_sdm generate
    process(clk_62m5_i)
    begin
      if rising_edge(clk_62m5_i) then
        if rst_n_i = '0' then
          mpll_cnt <= (others => '0');
          hpll_cnt <= (others => '0');
          mpll_toggle_o <= '0';
          hpll_toggle_o <= '0';
        else
          if mpll_cnt = 0 then
            --  Idle, can accept a new value
            if mpll_load_i = '1' then
              --  Reformat.
              --  According to 73205, only LSB are significant.
              mpll_data_o <= (others => '0');
              mpll_data_o(13 downto 0) <= mpll_data_i(15 downto 2);
              mpll_cnt <= (others => '1');
            end if;
          else
            --  FB CLK should be way higher than system clock
            if mpll_cnt(5 downto 4) = "00" then
              mpll_toggle_o <= '0';
            elsif mpll_cnt(5 downto 4) /= "11" then
              mpll_toggle_o <= '1';
            end if;
            mpll_cnt <= mpll_cnt - 1;
          end if;

          if hpll_cnt = 0 then
            --  Idle, can accept a new value
            if hpll_load_i = '1' then
              --  Reformat.
              --  According to 73205, only LSB are significant.
              hpll_data_o <= (others => '0');
              hpll_data_o(23 downto 0) <= hpll_data_i(23 downto 0); -- b"1111_111" & hpll_data_out & '0';
              hpll_cnt <= (others => '1');
            end if;
          else
            --  FB CLK should be way higher than system clock
            if hpll_cnt(5 downto 4) = "00" then
              hpll_toggle_o <= '0';
            elsif mpll_cnt(5 downto 4) /= "11" then
              hpll_toggle_o <= '1';
            end if;
            hpll_cnt <= hpll_cnt - 1;
          end if;
        end if;
      end if;
    end process;
  end generate gen_sdm;

  gen_no_sdm: if not g_use_sdm generate
    mpll_data_o <= (others => '0');
    mpll_toggle_o <= '0';
    hpll_data_o <= (others => '0');
    hpll_toggle_o <= '0';
  end generate;

  inst_gthe4_map: entity work.rxpi_gthe4_map
    port map (
      rst_n_i => rst_n_i,
      clk_i => clk_62m5_i,
      wb_i => wb_aux_i,
      wb_o => wb_aux_o,
      reset_gth_rst_o => gth_rst,
      reset_gth_tx_rst_o => gth_tx_rst_o,
      reset_gth_tx_pcs_rst_o => txpcsreset_o,
      reset_gth_tx_pma_rst_o => txpmareset_o,
      reset_gth_rx_rst_o => gth_rx_rst_o,
      reset_gth_rx_pcs_rst_o => rxpcsreset_o,
      reset_gth_rx_pma_rst_o => rxpmareset_o,
      reset_gth_rx_buf_rst_o => rxbufreset_o,
      reset_rxpi_rst_o => rxpi_reset,
      status_phy_ready_i => phy_rdy_in_62m5,
      status_extra_i(15 downto 0) => gth_status_i,
      ctrl_rdy_o => phy_rdy_o,
      bitslide_i(4 downto 0) => bitslide_val_i,
      bitslide_i(31 downto 5) => (others => '0'),
      rxpi_nsamp_o => rxpi_nsamp,
      rxpi_shift_o => rxpi_shift,
      ps_ctrl_shift_i => '0',
      ps_ctrl_shift_o => ps_clk_shift,
      ps_ctrl_wr_o => ps_clk_shift_wr,
      ps_ctrl_rst_o => ps_clk_rst,
      ps_ctrl_pd_o => ps_clk_pd,
      ps_ctrl_incdec_o => ps_clk_incdec,
      ps_stat_phase_i => std_logic_vector(ps_clk_phase),
      ps_stat_fb_stopped_i => ps_clk_fb_stopped,
      ps_stat_in_stopped_i => ps_clk_in_stopped,
      ps_stat_locked_i => ps_clk_locked,
      ps_stat_ps_busy_i => ps_clk_busy,
      ps_count_val_o => ps_clk_nsamp,
      ps_res_val_i => std_logic_vector(ps_clk_count_out),
      ps_res_gen_i => std_logic_vector(ps_clk_gen)
    );

  inst_sync_rdy_in: entity work.gc_sync
    port map (
      clk_i => clk_62m5_i,
      rst_n_a_i => '1',
      d_i => phy_rdy_i,
      q_o => phy_rdy_in_62m5
    );

  inst_sync_rxoutclk: entity work.gc_sync
    port map (
      clk_i => clk_ps,
      rst_n_a_i => ps_clk_rst_n,
      d_i => rx_out_clk_i,
      q_o => rxoutclk_sync
    );
  
  ps_clk_rst_n <= not ps_clk_rst;

  ps_clk_pen <= ps_clk_shift_wr and ps_clk_shift;

  process (clk_62m5_i)
  begin
    if rising_edge(clk_62m5_i) then
      if ps_clk_rst = '1' then
        ps_clk_phase <= (others => '0');
        ps_clk_busy <= '1';
      else
        if ps_clk_done = '1' then
          ps_clk_busy <= '1';
        end if;

        if ps_clk_pen = '1' then
          ps_clk_busy <= '0';

          if ps_clk_incdec = '1' then
            ps_clk_phase <= ps_clk_phase + 1;
          else
            ps_clk_phase <= ps_clk_phase - 1;
          end if;
        end if;
      end if;
    end if;
  end process;

  process (clk_ps)
    variable cnt : unsigned(23 downto 0);
  begin
    if rising_edge(clk_ps) then
      if ps_clk_rst = '1' then
        ps_clk_nsamp_cnt <= unsigned (ps_clk_nsamp);
        ps_clk_gen <= x"00";
      else
        if ps_clk_nsamp_cnt = 0 then
          ps_clk_nsamp_cnt <= unsigned(ps_clk_nsamp);
          ps_clk_count_out <= ps_clk_count;
          ps_clk_gen <= ps_clk_gen + 1;
          cnt := (others => '0');
        else
          ps_clk_nsamp_cnt <= ps_clk_nsamp_cnt - 1;
          cnt := ps_clk_count;
        end if;

        --  Sample the sync signal
        if rxoutclk_sync = '1' then
          cnt := cnt + 1;
        end if;
        ps_clk_count <= cnt;
      end if;
    end if;
  end process;

  --  clk_ps; phase shift clock
  gth_rst_o <= gth_rst;
  gth_rst_n <= not gth_rst;

  inst_gth_rst_sync: entity work.gc_sync
    port map (
      clk_i => gth_dmon_clk_i,
      rst_n_a_i => '1',
      d_i => gth_rst_n,
      q_o => gth_dmon_rst_n
    );

  inst_rxpi_rst_sync: entity work.gc_sync
    port map (
      clk_i => gth_dmon_clk_i,
      rst_n_a_i => '1',
      d_i => rxpi_reset,
      q_o => rxpi_reset_dmon
    );
  
  b_rxpi: block
    alias rxpi is dmonitorout_i(6 downto 0);
    signal rxpi_ext : std_logic_vector(31 downto 0);
    alias rxpi_d is rxpi_ext(rxpi'range);

    signal rxpi_ext_0, rxpi_ext_1 : std_logic_vector(31 downto 7);

    signal rxpi_cnt : unsigned(31 downto 0);
    signal rxpi_acc : unsigned(31 downto 0);
    signal rxpi_res : std_logic_vector(31 downto 0);
    signal rxpi_wr, rxpi_sync_ack : std_logic;
  begin
    process(gth_dmon_clk_i)
    begin
      if rising_edge(gth_dmon_clk_i) then
        rxpi_wr <= '0';

        if gth_dmon_rst_n = '0' or rxpi_reset_dmon = '1' then
          --  Start point
          case rxpi(6 downto 5) is
            when "00" =>
              --  Might go below 0.
              rxpi_ext_0 <= x"000000" & '0';
              rxpi_ext_1 <= x"ffffff" & '1';
            when "11" =>
              --  Might go above 0x7f
              rxpi_ext_0 <= x"000000" & '1';
              rxpi_ext_1 <= x"000000" & '0';
            when others =>
              --  Safe
              rxpi_ext_0 <= (others => '0');
              rxpi_ext_1 <= (others => '0');
          end case;
          rxpi_cnt <= unsigned(rxpi_nsamp);
        else
          if rxpi_sync_ack = '1' then
            rxpi_wr <= '0';
          end if;
          if rxpi_cnt = 0 then
            rxpi_res <= std_logic_vector(rxpi_acc srl to_integer(unsigned (rxpi_shift(3 downto 0))));
            rxpi_acc <= unsigned(rxpi_ext);
            rxpi_wr <= '1';
            rxpi_cnt <= unsigned(rxpi_nsamp);
          else
            rxpi_acc <= rxpi_acc + unsigned(rxpi_ext);
            rxpi_cnt <= rxpi_cnt - 1;
          end if;

          --  Extend rxpi
          if rxpi(rxpi'high) = '1' then
            rxpi_ext(rxpi_ext_1'range) <= rxpi_ext_1;
          else
            rxpi_ext(rxpi_ext_0'range) <= rxpi_ext_0;
          end if;
          rxpi_ext(rxpi'range) <= rxpi;

          --  Update extensions.
          --  When rxpi increases:
          if rxpi_d(6 downto 3) = "0100" and rxpi(6 downto 3) = "0101" then
            --  Moving towards 1.
            rxpi_ext_1 <= rxpi_ext_0;
          end if;
          if rxpi_d(6 downto 3) = "1100" and rxpi(6 downto 3) = "1101" then
            --  Moving towards 0.
            rxpi_ext_0 <= std_logic_vector(unsigned(rxpi_ext_1) + 1);
          end if;

          --  When rxpi decreases:
          if rxpi_d(6 downto 3) = "1011" and rxpi(6 downto 3) = "1010" then
            --  Moving away from 1.
            rxpi_ext_0 <= rxpi_ext_1;
          end if;
          if rxpi_d(6 downto 3) = "0011" and rxpi(6 downto 3) = "0010" then
            --  Moving towards 0.
            rxpi_ext_1 <= std_logic_vector(unsigned(rxpi_ext_0) - 1);
          end if;
        end if;
      end if;
    end process;

    --  Synchronizer for rxpi acc.
    inst_sync_rxpi: entity work.gc_sync_word_wr
      generic map (
        g_auto_wr => false,
        g_width => 32
      )
      port map (
        clk_in_i => gth_dmon_clk_i,
        rst_in_n_i => gth_dmon_rst_n,
        clk_out_i => clk_62m5_i,
        rst_out_n_i => rst_n_i,
        data_i => rxpi_res,
        wr_i => rxpi_wr,
        busy_o => open,
        ack_o => rxpi_sync_ack,
        data_o => rxpi_data_o,
        wr_o => rxpi_valid_o
      );

  end block;
end top;
