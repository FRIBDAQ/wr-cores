-------------------------------------------------------------------------------
-- Title      : Platform-dependent components needed for WR PTP Core on Xilinx
-- Project    : WR PTP Core
-- URL        : http://www.ohwr.org/projects/wr-cores/wiki/Wrpc_core
-------------------------------------------------------------------------------
-- File       : wrc_platform_xilinx.vhd
-- Author     : Maciej Lipinski, Grzegorz Daniluk, Dimitrios Lampridis
-- Company    : CERN
-- Platform   : FPGA-generic
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description:
-- This module instantiates platform-specific modules that are needed by the
-- WR PTP Core (WRPC) to interface hardware on Xilinx FPGA. In particular it
-- contains:
-- * PHY
-- * PLLs
-- * buffers
--
-------------------------------------------------------------------------------
--
-- Copyright (c) 2016-2017 CERN / BE-CO-HT
--
-- This source file is free software; you can redistribute it
-- and/or modify it under the terms of the GNU Lesser General
-- Public License as published by the Free Software Foundation;
-- either version 2.1 of the License, or (at your option) any
-- later version
--
-- This source is distributed in the hope that it will be
-- useful, but WITHOUT ANY WARRANTY; without even the implied
-- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
-- PURPOSE.  See the GNU Lesser General Public License for more
-- details
--
-- You should have received a copy of the GNU Lesser General
-- Public License along with this source; if not, download it
-- from http://www.gnu.org/licenses/lgpl-2.1.html
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.endpoint_pkg.all;
use work.gencores_pkg.all;
use work.wr_xilinx_pkg.all;

library unisim;
use unisim.vcomponents.all;

entity xwrc_platform_xilinx is
  generic
    (
      -- Define the family/model of Xilinx FPGA
      -- (supported: for now only spartan6)
      g_fpga_family               : string  := "spartan6";
      g_direct_dmtd               : boolean := FALSE;
      -- Select whether to include external ref clock input
      g_with_external_clock_input : boolean := FALSE;
      -- Set to FALSE if you want to instantiate your own PLLs
      g_use_default_plls          : boolean := TRUE;
      -- Config for the auxiliary PLL output (for now only used in Spartan-6
      g_aux_pll_cfg               : t_auxpll_cfg_array := c_AUXPLL_CFG_ARRAY_DEFAULT;
      -- Select GTP channel to use 
      g_gtp_enable_ch0            : integer := 0;
      g_gtp_enable_ch1            : integer := 1;
      -- Select PHY reference clock
      -- default value of 4 selects CLK10 / CLK11 (see UG386, Fig 2-3, page 41)
      g_phy_refclk_sel            : integer range 0 to 7 := 4;
      -- g_gtrefclk_src is 4bits integer
      -- each bit represents GTP ref clock source of each channel(phy)
      -- bit '0' selects PLL0
      -- bit '1' selects PLL1
      g_gtrefclk_src              : std_logic_vector(3 downto 0);
      -- g_ref_clk_sel is 4bits integer
      -- each bit represents the clk_ref_o source of each channel(phy)
      -- bit '0' selects TXOUT
      -- bit '1' selects (GTP ref clock/2)
      g_ref_clk_sel               : std_logic_vector(3 downto 0);
      g_num_phys                  : integer range 0 to 4 := 1; 
      -- Set to TRUE will speed up some initialization processes
      g_simulation                : integer := 0);
  port (
    ---------------------------------------------------------------------------
    -- Asynchronous reset (active low)
    ---------------------------------------------------------------------------
    areset_n_i            : in  std_logic;
    ---------------------------------------------------------------------------
    -- ext ref clock input (g_with_external_clock_input = TRUE)
    ---------------------------------------------------------------------------
    clk_ext_i             : in  std_logic             := '0';
    ---------------------------------------------------------------------------
    -- GTP/GTX reference clock
    ---------------------------------------------------------------------------
    clk_gtp_ref0_p_i      : in  std_logic             := '0';
    clk_gtp_ref0_n_i      : in  std_logic             := '0';
    clk_gtp_ref1_p_i      : in  std_logic             := '0';
    clk_gtp_ref1_n_i      : in  std_logic             := '0';
    clk_gtp_ref0_locked_i : in  std_logic             := '1';
    clk_gtp_ref1_locked_i : in  std_logic             := '1';
    ---------------------------------------------------------------------------
    -- Clock inputs for default PLLs (g_use_default_plls = TRUE)
    ---------------------------------------------------------------------------
    -- 20MHz VCXO clock
    clk_20m_vcxo_i        : in  std_logic             := '0';
    -- 125.000 MHz PLL reference
    clk_125m_pllref_i     : in  std_logic             := '0';
    -- 124.992 MHz DMTD reference (CLBv3 reference design)
    clk_125m_dmtd_i       : in  std_logic             := '0';
    ---------------------------------------------------------------------------
    -- Clock inputs from custom PLLs (g_use_default_plls = FALSE)
    ---------------------------------------------------------------------------
    -- DMTD offset clock and lock status
    clk_dmtd_i            : in  std_logic             := '0';
    clk_dmtd_locked_i     : in  std_logic             := '1';
    -- Main system clock and lock status
    clk_sys_i             : in  std_logic             := '0';
    clk_sys_locked_i      : in  std_logic             := '1';
    -- 125MHz  Reference clock
    clk_ref_i             : in  std_logic             := '0';
    clk_ref_locked_i      : in  std_logic             := '1';
    -- 125MHz derived from 10MHz external reference and lock status
    -- (when g_with_external_clock_input = TRUE)
    clk_ext_mul_i         : in  std_logic             := '0';
    clk_ext_locked_i      : in  std_logic             := '1';
    clk_ext_stopped_i     : in  std_logic             := '0';
    clk_ext_rst_o         : out std_logic;
    ---------------------------------------------------------------------------
    -- SFP x g_num_phys
    ---------------------------------------------------------------------------
    sfp_txn_o             : out std_logic_vector(g_num_phys-1 downto 0);
    sfp_txp_o             : out std_logic_vector(g_num_phys-1 downto 0);
    sfp_rxn_i             : in  std_logic_vector(g_num_phys-1 downto 0):=(others=>'0');
    sfp_rxp_i             : in  std_logic_vector(g_num_phys-1 downto 0):=(others=>'0');
    sfp_tx_fault_i        : in  std_logic_vector(g_num_phys-1 downto 0):=(others=>'0');
    sfp_los_i             : in  std_logic_vector(g_num_phys-1 downto 0):=(others=>'0');
    sfp_tx_disable_o      : out std_logic_vector(g_num_phys-1 downto 0):=(others=>'0');

    ---------------------------------------------------------------------------
    --Auxiliary PLL outputs
    ---------------------------------------------------------------------------
    clk_pll_aux_o         : out std_logic_vector(3 downto 0);
    pll_aux_locked_o      : out std_logic;
    ---------------------------------------------------------------------------
    --Interface to WR PTP Core (WRPC)
    ---------------------------------------------------------------------------
    -- PLL outputs
    clk_sys_o             : out std_logic;
    clk_ref_o             : out std_logic_vector(g_num_phys-1 downto 0);
    clk_20m_o             : out std_logic;
    clk_ref_locked_o      : out std_logic_vector(g_num_phys-1 downto 0);
    clk_dmtd_o            : out std_logic;
    pll_locked_o          : out std_logic;
    clk_ext_o             : out std_logic;

    -- PHY - CH0
    phy8_o                : out t_phy_8bits_to_wrc_array(g_num_phys-1 downto 0);
    phy8_i                : in  t_phy_8bits_from_wrc_array(g_num_phys-1 downto 0):=(others=>c_dummy_phy8_from_wrc);
    phy16_o               : out t_phy_16bits_to_wrc_array(g_num_phys-1 downto 0);
    phy16_i               : in  t_phy_16bits_from_wrc_array(g_num_phys-1 downto 0):=(others=>c_dummy_phy16_from_wrc);

    -- External reference
    clk_ext_mul_o         : out std_logic;
    clk_ext_mul_locked_o  : out std_logic;
    clk_ext_mul_stopped_o : out std_logic;
    clk_ext_rst_i         : in  std_logic:= '0';

    clk_gtp_ref0_o        : out std_logic;
    clk_gtp_ref0_bufg_o   : out std_logic;
    PLL0OUTCLK_OUT        : out std_logic;
    PLL0OUTREFCLK_OUT     : out std_logic;
    PLL0LOCK_OUT          : out std_logic;
    PLL0LOCKDETCLK_IN     : in  std_logic:='0';
    PLL0REFCLKLOST_OUT    : out std_logic;
    PLL0RESET_IN          : in  std_logic:='0'
    );

end entity xwrc_platform_xilinx;

architecture rtl of xwrc_platform_xilinx is

  -----------------------------------------------------------------------------
  -- Signals declaration
  -----------------------------------------------------------------------------

  signal pll_arst            : std_logic := '0';
  signal clk_pllref_buf      : std_logic;
  signal phy8_out            : t_phy_8bits_to_wrc_array(2-1 downto 0);
  signal phy8_in             : t_phy_8bits_from_wrc_array(2-1 downto 0):=(others=>c_dummy_phy8_from_wrc);
  signal phy16_out           : t_phy_16bits_to_wrc_array(2-1 downto 0);
  signal phy16_in            : t_phy_16bits_from_wrc_array(2-1 downto 0):=(others=>c_dummy_phy16_from_wrc);
  signal clk_sys             : std_logic;
  signal clk_sys_out         : std_logic;
  signal pll_sys_locked      : std_logic;

begin  -- architecture rtl

  -----------------------------------------------------------------------------
  -- Check for unsupported features and/or misconfiguration
  -----------------------------------------------------------------------------
  gen_unknown_fpga : if (g_fpga_family /= "spartan6" and g_fpga_family /= "kintex7" and g_fpga_family /= "artix7" and g_fpga_family /= "virtex5") generate
    assert FALSE
      report "Xilinx FPGA family [" & g_fpga_family & "] is not supported"
      severity ERROR;
  end generate gen_unknown_fpga;

  gen_no_gtp_channel : if (g_gtp_enable_ch0 = 0 and g_gtp_enable_ch1 = 0)
  generate
    assert FALSE
      report "At least one GTP channels must be enabled"
      severity ERROR;
  end generate gen_no_gtp_channel;

  -----------------------------------------------------------------------------
  -- Clock PLLs
  -----------------------------------------------------------------------------

  -- active high async reset for PLLs
  pll_arst   <= not areset_n_i;
  clk_sys_o  <= clk_sys_out;

  gen_default_plls : if (g_use_default_plls = TRUE) generate

    -- Default PLL setup consists of two PLLs.
    -- One takes a 125MHz clock signal as input and produces the
    -- 62.5MHz WR PTP core main system clock.
    -- The other PLL takes a 20MHz clock signal as input and produces the
    -- 62.5MHz DMTD clock.
    --
    -- A third PLL is instantiated if also g_with_external_clock_input = TRUE.
    -- In that case, a 10MHz external reference is multiplied to generate a
    -- 125MHz reference clock
    gen_spartan6_default_plls : if (g_fpga_family = "spartan6") generate

      signal clk_20m          : std_logic;
      signal clk_sys_fb       : std_logic;
      signal clk_dmtd         : std_logic;
      signal clk_dmtd_fb      : std_logic;
      signal pll_dmtd_locked  : std_logic;
      signal clk_20m_vcxo_buf : std_logic;
      signal clk_pll_aux      : std_logic_vector(3 downto 0);

      signal clk_pllref_buf_int1 : std_logic;
      signal clk_pllref_buf_int2 : std_logic;

    begin  --gen_spartan6_default_plls

      -- System PLL
      cmp_sys_clk_pll : PLL_BASE
        generic map (
          BANDWIDTH          => "OPTIMIZED",
          CLK_FEEDBACK       => "CLKFBOUT",
          COMPENSATION       => "INTERNAL",
          DIVCLK_DIVIDE      => 1,
          CLKFBOUT_MULT      => 8,
          CLKFBOUT_PHASE     => 0.000,
          CLKOUT0_DIVIDE     => 16,
          CLKOUT0_PHASE      => 0.000,
          CLKOUT0_DUTY_CYCLE => 0.500,
          -- 1st aux user clock parameters
          CLKOUT1_DIVIDE     => g_aux_pll_cfg(0).divide,
          CLKOUT1_PHASE      => 0.000,
          CLKOUT1_DUTY_CYCLE => 0.500,
          CLKOUT2_DIVIDE     => 8,
          CLKOUT2_PHASE      => 0.000,
          CLKOUT2_DUTY_CYCLE => 0.500,
          -- The rest of aux user clocks parameters
          CLKOUT3_DIVIDE     => g_aux_pll_cfg(1).divide,
          CLKOUT3_PHASE      => 0.000,
          CLKOUT3_DUTY_CYCLE => 0.500,
          CLKOUT4_DIVIDE     => g_aux_pll_cfg(2).divide,
          CLKOUT4_PHASE      => 0.000,
          CLKOUT4_DUTY_CYCLE => 0.500,
          CLKOUT5_DIVIDE     => g_aux_pll_cfg(3).divide,
          CLKOUT5_PHASE      => 0.000,
          CLKOUT5_DUTY_CYCLE => 0.500,
          ----
          CLKIN_PERIOD       => 8.0,
          REF_JITTER         => 0.016)
        port map (
          CLKFBOUT => clk_sys_fb,
          CLKOUT0  => clk_sys,
          CLKOUT1  => clk_pll_aux(0), -- required for 500MHz generation for
          -- Cute-WR. This is because 500MHz goes then to BUFPLL which can input
          -- only CLKOUT0/1 from PLL_BASE.
          CLKOUT2  => clk_pllref_buf_int2,
          CLKOUT3  => clk_pll_aux(1),
          CLKOUT4  => clk_pll_aux(2),
          CLKOUT5  => clk_pll_aux(3),
          LOCKED   => pll_sys_locked,
          RST      => pll_arst,
          CLKFBIN  => clk_sys_fb,
          CLKIN    => clk_pllref_buf_int1);

      -- System PLL input clock buffer
      cmp_clk_sys_buf_i : BUFG
        port map (
          O => clk_pllref_buf_int1,
          I => clk_125m_pllref_i);

      -- PLL aux clocks buffers
      gen_auxclk_bufs: for I in 0 to 3 generate
        -- Aux PLL_BASE clocks with BUFG enabled
        gen_auxclk_bufg_en: if g_aux_pll_cfg(I).enabled = TRUE and g_aux_pll_cfg(I).bufg_en = TRUE generate
          cmp_auxclk_bufg : BUFG
            port map (
              O => clk_pll_aux_o(I),
              I => clk_pll_aux(I));
        end generate;
        -- Aux PLL_BASE clocks with BUFG disabled
        gen_auxclk_no_bufg: if g_aux_pll_cfg(I).enabled = TRUE and g_aux_pll_cfg(I).bufg_en = FALSE generate
          clk_pll_aux_o(I) <= clk_pll_aux(I);
        end generate;
        -- Disabled aux PLL_BASE clocks
        gen_auxclk_disabled: if g_aux_pll_cfg(I).enabled = FALSE generate
          clk_pll_aux_o(I) <= '0';
        end generate;
      end generate;

      -- System PLL output clock buffer
      cmp_clk_sys_buf_o : BUFG
        port map (
          O => clk_sys_out,
          I => clk_sys);

      -- System PLL output clock buffer
      cmp_clk_ref_buf_o : BUFG
        port map (
          O => clk_pllref_buf,
          I => clk_pllref_buf_int2);

      clk_20m_o        <= clk_20m_vcxo_buf;
      clk_ref_o        <= (others=>clk_pllref_buf);
      clk_ref_locked_o <= (others=>'1');
      pll_locked_o     <= pll_sys_locked and pll_dmtd_locked;
      pll_aux_locked_o <= pll_sys_locked;

      -- DMTD PLL
      cmp_dmtd_clk_pll : PLL_BASE
        generic map (
          BANDWIDTH          => "OPTIMIZED",
          CLK_FEEDBACK       => "CLKFBOUT",
          COMPENSATION       => "INTERNAL",
          DIVCLK_DIVIDE      => 1,
          CLKFBOUT_MULT      => 50,
          CLKFBOUT_PHASE     => 0.000,
          CLKOUT0_DIVIDE     => 16,
          CLKOUT0_PHASE      => 0.000,
          CLKOUT0_DUTY_CYCLE => 0.500,
          CLKIN_PERIOD       => 50.0,
          REF_JITTER         => 0.016)
        port map (
          CLKFBOUT => clk_dmtd_fb,
          CLKOUT0  => clk_dmtd,
          LOCKED   => pll_dmtd_locked,
          RST      => pll_arst,
          CLKFBIN  => clk_dmtd_fb,
          CLKIN    => clk_20m_vcxo_buf);

      -- DMTD PLL input clock buffer
      cmp_clk_dmtd_buf_i : BUFG
        port map (
          O => clk_20m_vcxo_buf,
          I => clk_20m_vcxo_i);

      -- DMTD PLL output clock buffer
      cmp_clk_dmtd_buf_o : BUFG
        port map (
          O => clk_dmtd_o,
          I => clk_dmtd);

      gen_spartan6_ext_ref_pll : if (g_with_external_clock_input = TRUE) generate

        signal clk_ext_fbi  : std_logic;
        signal clk_ext_fbo  : std_logic;
        signal clk_ext_buf  : std_logic;
        signal clk_ext_mul  : std_logic;
        signal clk_ext_stat : std_logic_vector(7 downto 0);
        signal pll_ext_rst  : std_logic;

      begin  --gen_spartan6_ext_ref_pll

        -- External reference DCM
        cmp_ext_ref_pll : DCM_SP
          generic map
          (CLKDV_DIVIDE       => 2.000,
           CLKFX_DIVIDE       => 2,
           CLKFX_MULTIPLY     => 25,
           CLKIN_DIVIDE_BY_2  => FALSE,
           CLKIN_PERIOD       => 100.0,
           CLKOUT_PHASE_SHIFT => "NONE",
           CLK_FEEDBACK       => "1X",
           DESKEW_ADJUST      => "SYSTEM_SYNCHRONOUS",
           PHASE_SHIFT        => 0,
           STARTUP_WAIT       => FALSE)
          port map
          -- Input clock
          (CLKIN    => clk_ext_buf,
           CLKFB    => clk_ext_fbi,
           -- Output clocks
           CLK0     => clk_ext_fbo,
           CLKFX    => clk_ext_mul,
           -- Ports for dynamic phase shift
           PSCLK    => '0',
           PSEN     => '0',
           PSINCDEC => '0',
           PSDONE   => open,
           -- Other control and status signals
           LOCKED   => clk_ext_mul_locked_o,
           STATUS   => clk_ext_stat,
           RST      => pll_ext_rst,
           -- Unused pin, tie low
           DSSEN    => '0');

        clk_ext_mul_stopped_o <= clk_ext_stat(1);

        -- External reference input buffer
        cmp_clk_ext_buf_i : BUFG
          port map
          (O => clk_ext_buf,
           I => clk_ext_i);

        clk_ext_o <= clk_ext_buf;

        -- External reference feedback buffer
        cmp_clk_ext_buf_fb : BUFG
          port map
          (O => clk_ext_fbi,
           I => clk_ext_fbo);

        -- External reference output buffer
        cmp_clk_ext_buf_o : BUFG
          port map
          (O => clk_ext_mul_o,
           I => clk_ext_mul);

        cmp_extend_ext_reset : gc_extend_pulse
          generic map (
            g_width => 1000)
          port map (
            clk_i      => clk_sys_out,
            rst_n_i    => pll_sys_locked,
            pulse_i    => clk_ext_rst_i,
            extended_o => pll_ext_rst);

      end generate gen_spartan6_ext_ref_pll;

    end generate gen_spartan6_default_plls;

    ---------------------------------------------------------------------------
    --   Virtex 5 PLLs
    ---------------------------------------------------------------------------
    gen_virtex5_default_plls : if (g_fpga_family = "virtex5") generate

      signal clk_sys_fb       : std_logic;
      signal clk_dmtd         : std_logic;
      signal clk_dmtd_fb      : std_logic;
      signal pll_dmtd_locked  : std_logic;
      signal clk_20m_vcxo_buf : std_logic;

    begin  --gen_virtex5_default_plls

      -- System PLL
      cmp_sys_clk_pll : PLL_BASE
        generic map (
          BANDWIDTH          => "OPTIMIZED",
          CLK_FEEDBACK       => "CLKFBOUT",
          COMPENSATION       => "INTERNAL",
          DIVCLK_DIVIDE      => 1,
          CLKFBOUT_MULT      => 4,
          CLKFBOUT_PHASE     => 0.000,
          CLKOUT0_DIVIDE     => 8,
          CLKOUT0_PHASE      => 0.000,
          CLKOUT0_DUTY_CYCLE => 0.500,
          CLKIN_PERIOD       => 8.0,
          REF_JITTER         => 0.016)
        port map (
          CLKFBOUT => clk_sys_fb,
          CLKOUT0  => clk_sys,
          LOCKED   => pll_sys_locked,
          RST      => pll_arst,
          CLKFBIN  => clk_sys_fb,
          CLKIN    => clk_pllref_buf);

      -- System PLL input clock buffer
      cmp_clk_sys_buf_i : BUFG
        port map (
          O => clk_pllref_buf,
          I => clk_125m_pllref_i);

      -- System PLL output clock buffer
      cmp_clk_sys_buf_o : BUFG
        port map (
          O => clk_sys_out,
          I => clk_sys);

      clk_ref_o(0)     <= clk_pllref_buf;
      clk_ref_locked_o <= (others=>'1');
      pll_locked_o     <= pll_sys_locked and pll_dmtd_locked;

      -- DMTD PLL
      cmp_dmtd_clk_pll : PLL_BASE
        generic map (
          BANDWIDTH          => "OPTIMIZED",
          CLK_FEEDBACK       => "CLKFBOUT",
          COMPENSATION       => "INTERNAL",
          DIVCLK_DIVIDE      => 1,
          CLKFBOUT_MULT      => 25,
          CLKFBOUT_PHASE     => 0.000,
          CLKOUT0_DIVIDE     => 8,
          CLKOUT0_PHASE      => 0.000,
          CLKOUT0_DUTY_CYCLE => 0.500,
          CLKIN_PERIOD       => 50.0,
          REF_JITTER         => 0.016)
        port map (
          CLKFBOUT => clk_dmtd_fb,
          CLKOUT0  => clk_dmtd,
          LOCKED   => pll_dmtd_locked,
          RST      => pll_arst,
          CLKFBIN  => clk_dmtd_fb,
          CLKIN    => clk_20m_vcxo_buf);

      -- DMTD PLL input clock buffer
      cmp_clk_dmtd_buf_i : BUFG
        port map (
          O => clk_20m_vcxo_buf,
          I => clk_20m_vcxo_i);

      -- DMTD PLL output clock buffer
      cmp_clk_dmtd_buf_o : BUFG
        port map (
          O => clk_dmtd_o,
          I => clk_dmtd);

    end generate gen_virtex5_default_plls;

    ---------------------------------------------------------------------------
    --   Kintex7, Artix7 PLLs
    ---------------------------------------------------------------------------
    gen_kintex7_artix7_default_plls : if (g_fpga_family = "kintex7" or g_fpga_family = "artix7") generate

      signal clk_sys_fb       : std_logic;
      signal clk_dmtd         : std_logic;
      signal clk_dmtd_fb      : std_logic;
      signal pll_dmtd_locked  : std_logic;

    begin
      -- System PLL (125 MHz -> 62.5 MHz)
      cmp_sys_clk_pll : MMCME2_ADV
        generic map (
          BANDWIDTH            => "OPTIMIZED",
          CLKOUT4_CASCADE      => false,
          COMPENSATION         => "ZHOLD",
          STARTUP_WAIT         => false,
          DIVCLK_DIVIDE        => 1,
          CLKFBOUT_MULT_F      => 8.000,     -- 125 MHz x 8.
          CLKFBOUT_PHASE       => 0.000,
          CLKFBOUT_USE_FINE_PS => false,

          CLKOUT0_DIVIDE_F    => 16.000,     -- 62.5 MHz sys clock
          CLKOUT0_PHASE       => 0.000,
          CLKOUT0_DUTY_CYCLE  => 0.500,
          CLKOUT0_USE_FINE_PS => false,

          CLKIN1_PERIOD => 8.000,            -- 8 ns means 125 MHz
          REF_JITTER1   => 0.010)
        port map (
          -- Output clocks
          CLKFBOUT     => clk_sys_fb,
          CLKOUT0      => clk_sys,
          -- Input clock control
          CLKFBIN      => clk_sys_fb,
          CLKIN1       => clk_pllref_buf,
          CLKIN2       => '0',
          -- Tied to always select the primary input clock
          CLKINSEL     => '1',
          -- Ports for dynamic reconfiguration
          DADDR        => (others => '0'),
          DCLK         => '0',
          DEN          => '0',
          DI           => (others => '0'),
          DO           => open,
          DRDY         => open,
          DWE          => '0',
          -- Ports for dynamic phase shift
          PSCLK        => '0',
          PSEN         => '0',
          PSINCDEC     => '0',
          PSDONE       => open,
          -- Other control and status signals
          LOCKED       => pll_sys_locked,
          CLKINSTOPPED => open,
          CLKFBSTOPPED => open,
          PWRDWN       => '0',
          RST          => pll_arst);

      -- System PLL output clock buffer
      cmp_clk_sys_buf_o : BUFG
      port map (
        I => clk_sys,
        O => clk_sys_out);

      pll_locked_o   <= pll_dmtd_locked and pll_sys_locked;

      gen_kintex7_artix7_dmtd_pll : if (g_direct_dmtd = FALSE) generate

        signal clk_20m_vcxo_buf : std_logic;
        signal clk_dmtd_fb      : std_logic;

      begin
      -- DMTD PLL (20 MHz -> ~62,5 MHz)
      cmp_dmtd_clk_pll : MMCME2_ADV
        generic map (
          BANDWIDTH            => "OPTIMIZED",
          CLKOUT4_CASCADE      => false,
          COMPENSATION         => "ZHOLD",
          STARTUP_WAIT         => false,
          DIVCLK_DIVIDE        => 1,
          CLKFBOUT_MULT_F      => 50.000,    -- 20 MHz -> 1 GHz
          CLKFBOUT_PHASE       => 0.000,
          CLKFBOUT_USE_FINE_PS => false,
          CLKOUT0_DIVIDE_F     => 16.000,    -- 1GHz/16 -> 62.5 MHz
          CLKOUT0_PHASE        => 0.000,
          CLKOUT0_DUTY_CYCLE   => 0.500,
          CLKOUT0_USE_FINE_PS  => false,
          CLKOUT1_DIVIDE       => 16,        -- 1GHz/16 -> 62.5 MHz
          CLKOUT1_PHASE        => 0.000,
          CLKOUT1_DUTY_CYCLE   => 0.500,
          CLKOUT1_USE_FINE_PS  => false,
          CLKIN1_PERIOD        => 50.000,    -- 50ns for 20 MHz
          REF_JITTER1          => 0.010)
        port map (
          -- Output clocks
          CLKFBOUT     => clk_dmtd_fb,
          CLKOUT0      => clk_dmtd,
          -- Input clock control
          CLKFBIN      => clk_dmtd_fb,
          CLKIN1       => clk_20m_vcxo_buf,
          CLKIN2       => '0',
          -- Tied to always select the primary input clock
          CLKINSEL     => '1',
          -- Ports for dynamic reconfiguration
          DADDR        => (others => '0'),
          DCLK         => '0',
          DEN          => '0',
          DI           => (others => '0'),
          DO           => open,
          DRDY         => open,
          DWE          => '0',
          -- Ports for dynamic phase shift
          PSCLK        => '0',
          PSEN         => '0',
          PSINCDEC     => '0',
          PSDONE       => open,
          -- Other control and status signals
          LOCKED       => pll_dmtd_locked,
          CLKINSTOPPED => open,
          CLKFBSTOPPED => open,
          PWRDWN       => '0',
          RST          => pll_arst);

      -- DMTD PLL input clock buffer
      cmp_clk_dmtd_buf_i : BUFG
        port map (
          O => clk_20m_vcxo_buf,
          I => clk_20m_vcxo_i);

      end generate gen_kintex7_artix7_dmtd_pll;

      gen_kintex7_artix7_direct_dmtd : if (g_direct_dmtd = TRUE) generate

      begin
      -- DMTD Div2 (124.9920 MHz -> 62,496 MHz)
        process(clk_125m_dmtd_i)
        begin
          if rising_edge(clk_125m_dmtd_i) then
            clk_dmtd <= not clk_dmtd;
          end if;
        end process;

        pll_dmtd_locked <= '1';
      end generate gen_kintex7_artix7_direct_dmtd;

      -- DMTD PLL output clock buffer
      cmp_clk_dmtd_buf_o : BUFG
        port map (
          O => clk_dmtd_o,
          I => clk_dmtd);

    end generate gen_kintex7_artix7_default_plls;

  end generate gen_default_plls;

  -- If external PLLs are used, just copy clock inputs to outputs
  gen_custom_plls : if (g_use_default_plls = FALSE) generate

    clk_sys_out      <= clk_sys_i;
    clk_dmtd_o       <= clk_dmtd_i;
    clk_pllref_buf   <= clk_ref_i;

    pll_sys_locked   <= clk_sys_locked_i;
    pll_locked_o     <= clk_sys_locked_i and clk_dmtd_locked_i;

  end generate gen_custom_plls;

  -- always pass ext reference reset input to output, even when not used
  clk_ext_rst_o <= clk_ext_rst_i;

  -----------------------------------------------------------------------------
  -- Transceiver PHY
  -----------------------------------------------------------------------------

  gen_phy_spartan6 : if(g_fpga_family = "spartan6") generate

    signal clk_gtp       : std_logic_vector(2-1 downto 0);

    signal pad_txn_out : std_logic_vector(2-1 downto 0);
    signal pad_txp_out : std_logic_vector(2-1 downto 0);
    signal pad_rxn_in  : std_logic_vector(2-1 downto 0);
    signal pad_rxp_in  : std_logic_vector(2-1 downto 0);

  begin

    cmp_ibufgds_gtp0 : IBUFGDS
      generic map (
        DIFF_TERM    => TRUE,
        IBUF_LOW_PWR => TRUE,
        IOSTANDARD   => "DEFAULT")
      port map (
        O  => clk_gtp(0),
        I  => clk_gtp_ref0_p_i,
        IB => clk_gtp_ref0_n_i);

    cmp_ibufgds_gtp1 : IBUFGDS
    generic map (
      DIFF_TERM    => TRUE,
      IBUF_LOW_PWR => TRUE,
      IOSTANDARD   => "DEFAULT")
    port map (
      O  => clk_gtp(1),
      I  => clk_gtp_ref1_p_i,
      IB => clk_gtp_ref1_n_i);        

    cmp_gtp : wr_gtp_phy_spartan6
      generic map (
        g_simulation => g_simulation,
        g_enable_ch0 => g_gtp_enable_ch0,
        g_enable_ch1 => g_gtp_enable_ch1)
      port map (
        gtp0_clk_i         => clk_gtp(0),
        ch0_ref_clk_i      => clk_pllref_buf,
        ch0_tx_data_i      => phy8_in(0).tx_data,
        ch0_tx_k_i         => phy8_in(0).tx_k(0),
        ch0_tx_disparity_o => phy8_out(0).tx_disparity,
        ch0_tx_enc_err_o   => phy8_out(0).tx_enc_err,
        ch0_rx_data_o      => phy8_out(0).rx_data,
        ch0_rx_rbclk_o     => phy8_out(0).rx_clk,
        ch0_rx_k_o         => phy8_out(0).rx_k(0),
        ch0_rx_enc_err_o   => phy8_out(0).rx_enc_err,
        ch0_rx_bitslide_o  => phy8_out(0).rx_bitslide,
        ch0_rst_i          => phy8_in(0).rst,
        ch0_loopen_i       => phy8_in(0).loopen,
        ch0_loopen_vec_i   => phy8_in(0).loopen_vec,
        ch0_tx_prbs_sel_i  => phy8_in(0).tx_prbs_sel,
        ch0_rdy_o          => phy8_out(0).rdy,
        ch0_ref_sel_pll    => std_logic_vector(to_unsigned(g_phy_refclk_sel, 3)),
        gtp1_clk_i         => clk_gtp(1),
        ch1_ref_clk_i      => clk_pllref_buf,
        ch1_tx_data_i      => phy8_in(1).tx_data,
        ch1_tx_k_i         => phy8_in(1).tx_k(0),
        ch1_tx_disparity_o => phy8_out(1).tx_disparity,
        ch1_tx_enc_err_o   => phy8_out(1).tx_enc_err,
        ch1_rx_data_o      => phy8_out(1).rx_data,
        ch1_rx_rbclk_o     => phy8_out(1).rx_clk,
        ch1_rx_k_o         => phy8_out(1).rx_k(0),
        ch1_rx_enc_err_o   => phy8_out(1).rx_enc_err,
        ch1_rx_bitslide_o  => phy8_out(1).rx_bitslide,
        ch1_rst_i          => phy8_in(1).rst,
        ch1_loopen_i       => phy8_in(1).loopen,
        ch1_loopen_vec_i   => phy8_in(1).loopen_vec,
        ch1_tx_prbs_sel_i  => phy8_in(1).tx_prbs_sel,
        ch1_rdy_o          => phy8_out(1).rdy,
        ch1_ref_sel_pll    => std_logic_vector(to_unsigned(g_phy_refclk_sel, 3)),
        pad_txn0_o         => pad_txn_out(0),
        pad_txp0_o         => pad_txp_out(0),
        pad_rxn0_i         => pad_rxn_in(0),
        pad_rxp0_i         => pad_rxp_in(0),
        pad_txn1_o         => pad_txn_out(1),
        pad_txp1_o         => pad_txp_out(1),
        pad_rxn1_i         => pad_rxn_in(1),
        pad_rxp1_i         => pad_rxp_in(1)
        );

    gen_gtp_ch0 : if (g_gtp_enable_ch0 = 1 and g_gtp_enable_ch1 = 0) generate
      phy8_in(0)                <= phy8_i(0);
      phy8_o(0)                 <= phy8_out(0);
      phy8_out(0).ref_clk       <= clk_pllref_buf;
      phy8_out(0).sfp_tx_fault  <= sfp_tx_fault_i(0);
      phy8_out(0).sfp_los       <= sfp_los_i(0);
      sfp_txp_o(0)              <= pad_txp_out(0);
      sfp_txn_o(0)              <= pad_txn_out(0);
      pad_rxp_in(0)             <= sfp_rxp_i(0);
      pad_rxn_in(0)             <= sfp_rxn_i(0);
      sfp_tx_disable_o(0)       <= phy8_in(0).sfp_tx_disable;
      phy16_o(0)                <= c_dummy_phy16_to_wrc;
    end generate gen_gtp_ch0;

    gen_gtp_ch1 : if (g_gtp_enable_ch0 = 0 and g_gtp_enable_ch1 = 1) generate
      phy8_in(1)                <= phy8_i(0);
      phy8_o(0)                 <= phy8_out(1);
      phy8_out(1).ref_clk       <= clk_pllref_buf;
      phy8_out(1).sfp_tx_fault  <= sfp_tx_fault_i(0);
      phy8_out(1).sfp_los       <= sfp_los_i(0);
      sfp_txp_o(0)              <= pad_txp_out(1);
      sfp_txn_o(0)              <= pad_txn_out(1);
      pad_rxp_in(1)             <= sfp_rxp_i(0);
      pad_rxn_in(1)             <= sfp_rxn_i(0);
      sfp_tx_disable_o(0)       <= phy8_in(0).sfp_tx_disable;
      phy16_o(0)                <= c_dummy_phy16_to_wrc;
    end generate gen_gtp_ch1;

    gen_gtp_ch01 : if (g_gtp_enable_ch0 = 1 and g_gtp_enable_ch1 = 1) generate
      phy8_in                   <= phy8_i;
      phy8_o                    <= phy8_out;
      phy8_out(0).ref_clk       <= clk_pllref_buf;
      phy8_out(0).sfp_tx_fault  <= sfp_tx_fault_i(0);
      phy8_out(0).sfp_los       <= sfp_los_i(0);
      phy8_out(1).ref_clk       <= clk_pllref_buf;
      phy8_out(1).sfp_tx_fault  <= sfp_tx_fault_i(1);
      phy8_out(1).sfp_los       <= sfp_los_i(1);
      sfp_txp_o                 <= pad_txp_out;
      sfp_txn_o                 <= pad_txn_out;
      pad_rxp_in                <= sfp_rxp_i;
      pad_rxn_in                <= sfp_rxn_i;
      sfp_tx_disable_o(0)       <= phy8_in(0).sfp_tx_disable;
      sfp_tx_disable_o(1)       <= phy8_in(1).sfp_tx_disable;
      phy16_o(0)                <= c_dummy_phy16_to_wrc;
      phy16_o(1)                <= c_dummy_phy16_to_wrc;
    end generate gen_gtp_ch01;

  end generate gen_phy_spartan6;

  ---------------------------------------------------------------------------
  --   Virtex5 PHY
  ---------------------------------------------------------------------------

  gen_phy_virtex5 : if(g_fpga_family = "virtex5") generate
    
    signal clk_gtp     : std_logic_vector(2-1 downto 0);

    signal pad_txp_out : std_logic_vector(g_num_phys-1 downto 0);
    signal pad_txn_out : std_logic_vector(g_num_phys-1 downto 0);
    signal pad_rxp_in : std_logic_vector(g_num_phys-1 downto 0);
    signal pad_rxn_in : std_logic_vector(g_num_phys-1 downto 0);

  begin

    cmp_ibufgds_gtp0 : IBUFGDS
      generic map (
        DIFF_TERM    => FALSE,     -- ?: Tom's true, VXS: false
        IBUF_LOW_PWR => TRUE,      -- ?: Tom's commented out, VXS: true
        IOSTANDARD   => "DEFAULT") -- OK
      port map (
        O  => clk_gtp(0),
        I  => clk_gtp_ref0_p_i,
        IB => clk_gtp_ref0_n_i);

    cmp_ibufgds_gtp1 : IBUFGDS
      generic map (
        DIFF_TERM    => FALSE,     -- ?: Tom's true, VXS: false
        IBUF_LOW_PWR => TRUE,      -- ?: Tom's commented out, VXS: true
        IOSTANDARD   => "DEFAULT") -- OK
      port map (
        O  => clk_gtp(1),
        I  => clk_gtp_ref1_p_i,
        IB => clk_gtp_ref1_n_i);

    cmp_gtp : wr_gtp_phy_virtex5
      generic map (
        g_simulation => g_simulation,
        g_enable_ch0 => g_gtp_enable_ch0,
        g_enable_ch1 => g_gtp_enable_ch1)
      port map (
        gtp_clk_i          => clk_gtp(0),
        ch01_ref_clk_i     => clk_pllref_buf,
        ch0_tx_data_i      => phy8_in(0).tx_data,
        ch0_tx_k_i         => phy8_in(0).tx_k(0),
        ch0_tx_disparity_o => phy8_out(0).tx_disparity,
        ch0_tx_enc_err_o   => phy8_out(0).tx_enc_err,
        ch0_rx_data_o      => phy8_out(0).rx_data,
        ch0_rx_rbclk_o     => phy8_out(0).rx_clk,
        ch0_rx_k_o         => phy8_out(0).rx_k(0),
        ch0_rx_enc_err_o   => phy8_out(0).rx_enc_err,
        ch0_rx_bitslide_o  => phy8_out(0).rx_bitslide,
        ch0_rst_i          => phy8_in(0).rst,
        ch0_loopen_i       => phy8_in(0).loopen,
        ch0_rdy_o          => phy8_out(0).rdy,
        ch1_tx_data_i      => phy8_in(1).tx_data,
        ch1_tx_k_i         => phy8_in(1).tx_k(0),
        ch1_tx_disparity_o => phy8_out(1).tx_disparity,
        ch1_tx_enc_err_o   => phy8_out(1).tx_enc_err,
        ch1_rx_data_o      => phy8_out(1).rx_data,
        ch1_rx_rbclk_o     => phy8_out(1).rx_clk,
        ch1_rx_k_o         => phy8_out(1).rx_k(0),
        ch1_rx_enc_err_o   => phy8_out(1).rx_enc_err,
        ch1_rx_bitslide_o  => phy8_out(1).rx_bitslide,
        ch1_rst_i          => phy8_in(1).rst,
        ch1_loopen_i       => phy8_in(1).loopen,
        ch1_rdy_o          => phy8_out(1).rdy,
        pad_txn0_o         => pad_txn_out(0),
        pad_txp0_o         => pad_txp_out(0),
        pad_rxn0_i         => pad_rxn_in(0),
        pad_rxp0_i         => pad_rxp_in(0),
        pad_txn1_o         => pad_txn_out(1),
        pad_txp1_o         => pad_txp_out(1),
        pad_rxn1_i         => pad_rxn_in(1),
        pad_rxp1_i         => pad_rxp_in(1)
        );

    gen_gtp_ch0 : if (g_gtp_enable_ch0 = 1 and g_gtp_enable_ch1 = 0) generate
      phy8_out(0).ref_clk      <= clk_pllref_buf;
      phy8_out(0).sfp_tx_fault <= sfp_tx_fault_i(0);
      phy8_out(0).sfp_los      <= sfp_los_i(0);
      phy8_in(0)               <= phy8_in(0);
      phy8_o(0)                <= phy8_out(0);
      sfp_txp_o(0)             <= pad_txp_out(0);
      sfp_txn_o(0)             <= pad_txn_out(0);
      pad_rxp_in(0)            <= sfp_rxp_i(0);
      pad_rxn_in(0)            <= sfp_rxn_i(0);
      sfp_tx_disable_o(0)      <= phy8_in(0).sfp_tx_disable;
    end generate gen_gtp_ch0;

    gen_gtp_ch1 : if (g_gtp_enable_ch0 = 0 and g_gtp_enable_ch1 = 1) generate
      phy8_out(1).ref_clk      <= clk_pllref_buf;
      phy8_out(1).sfp_tx_fault <= sfp_tx_fault_i(0);
      phy8_out(1).sfp_los      <= sfp_los_i(0);
      phy8_in(1)               <= phy8_in(0);
      phy8_o(0)                <= phy8_out(1);
      sfp_txp_o(0)             <= pad_txp_out(1);
      sfp_txn_o(0)             <= pad_txn_out(1);
      pad_rxp_in(1)            <= sfp_rxp_i(0);
      pad_rxn_in(1)            <= sfp_rxn_i(0);
      sfp_tx_disable_o(0)      <= phy8_in(1).sfp_tx_disable;
    end generate gen_gtp_ch1;

    gen_gtp_ch01 : if (g_gtp_enable_ch0 = 1 and g_gtp_enable_ch1 = 1) generate
      phy8_in                   <= phy8_i;
      phy8_o                    <= phy8_out;
      phy8_out(0).ref_clk       <= clk_pllref_buf;
      phy8_out(0).sfp_tx_fault  <= sfp_tx_fault_i(0);
      phy8_out(0).sfp_los       <= sfp_los_i(0);
      phy8_out(1).ref_clk       <= clk_pllref_buf;
      phy8_out(1).sfp_tx_fault  <= sfp_tx_fault_i(1);
      phy8_out(1).sfp_los       <= sfp_los_i(1);
      sfp_txp_o                 <= pad_txp_out;
      sfp_txn_o                 <= pad_txn_out;
      pad_rxp_in                <= sfp_rxp_i;
      pad_rxn_in                <= sfp_rxn_i;
      sfp_tx_disable_o(0)       <= phy8_in(0).sfp_tx_disable;
      sfp_tx_disable_o(1)       <= phy8_in(1).sfp_tx_disable;
      phy16_o(0)                <= c_dummy_phy16_to_wrc;
      phy16_o(1)                <= c_dummy_phy16_to_wrc;
    end generate gen_gtp_ch01;

  end generate gen_phy_virtex5;

  ---------------------------------------------------------------------------
  --   Kintex7 PHY
  ---------------------------------------------------------------------------
  gen_phy_kintex7 : if (g_fpga_family = "kintex7") generate

    signal clk_ref          : std_logic;
    signal clk_gtx_buf : std_logic;
    signal clk_ref_locked   : std_logic;

  begin

    -- Dedicated GTX clock.
    cmp_gtp_dedicated_clk : IBUFDS_GTE2
      generic map(
        CLKCM_CFG    => true,
        CLKRCV_TRST  => true,
        CLKSWING_CFG => "11")
      port map (
        O     => clk_gtx_buf,
        ODIV2 => open,
        CEB   => '0',
        I     => clk_gtp_ref0_p_i,
        IB    => clk_gtp_ref0_n_i);

    -- System PLL input clock buffer
    cmp_clk_sys_buf_i : BUFG
      port map (
        I => clk_gtx_buf,
        O => clk_pllref_buf);

    cmp_gtx: wr_gtx_phy_family7
      generic map(
        g_simulation => g_simulation)
      port map(
        clk_gtx_i      => clk_gtx_buf,
        tx_out_clk_o   => clk_ref,
        tx_data_i      => phy16_i(0).tx_data,
        tx_k_i         => phy16_i(0).tx_k,
        tx_disparity_o => phy16_o(0).tx_disparity,
        tx_enc_err_o   => phy16_o(0).tx_enc_err,
        rx_rbclk_o     => phy16_o(0).rx_clk,
        rx_data_o      => phy16_o(0).rx_data,
        rx_k_o         => phy16_o(0).rx_k,
        rx_enc_err_o   => phy16_o(0).rx_enc_err,
        rx_bitslide_o  => phy16_o(0).rx_bitslide,
        rst_i          => phy16_i(0).rst,
        loopen_i       => phy16_i(0).loopen_vec,
        tx_prbs_sel_i  => phy16_i(0).tx_prbs_sel,
        rdy_o          => phy16_o(0).rdy,

        pad_txn_o => sfp_txn_o(0),
        pad_txp_o => sfp_txp_o(0),
        pad_rxn_i => sfp_rxn_i(0),
        pad_rxp_i => sfp_rxp_i(0),

        tx_locked_o   => clk_ref_locked);

    clk_ref_o(0)            <= clk_ref;
    clk_ref_locked_o(0)     <= clk_ref_locked;
    phy16_o(0).ref_clk      <= clk_ref;
    phy16_o(0).sfp_tx_fault <= sfp_tx_fault_i(0);
    phy16_o(0).sfp_los      <= sfp_los_i(0);
    sfp_tx_disable_o(0)     <= phy16_i(0).sfp_tx_disable;

    phy8_o <= (others=>c_dummy_phy8_to_wrc);

  end generate gen_phy_kintex7;

  ---------------------------------------------------------------------------
  --   Artix7 PHY
  ---------------------------------------------------------------------------
  gen_phy_artix7 : if (g_fpga_family = "artix7") generate

    signal clk_gtp_ref0          : std_logic;
    signal clk_gtp_ref1          : std_logic;
    signal clk_gtp_ref0_div2     : std_logic;     
    signal clk_gtp_ref1_div2     : std_logic;     
    signal clk_gtp_ref0_bufg     : std_logic;
    signal clk_gtp_ref0_div2_bufg: std_logic;
    signal clk_gtp_ref1_bufg     : std_logic;
    signal clk_gtp_ref1_div2_bufg: std_logic;
    signal clk_ref               : std_logic_vector(g_num_phys-1 downto 0);
    signal pll_locked            : std_logic_vector(g_num_phys-1 downto 0);
    signal clk_tx                : std_logic_vector(g_num_phys-1 downto 0);

  begin


    cmp_gtp_ref0_dedicated_clk : IBUFDS_GTE2
      generic map(
        CLKCM_CFG    => true,
        CLKRCV_TRST  => true,
        CLKSWING_CFG => "11")
      port map (
        O     => clk_gtp_ref0,
        ODIV2 => clk_gtp_ref0_div2,
        CEB   => '0',
        I     => clk_gtp_ref0_p_i,
        IB    => clk_gtp_ref0_n_i);

    -- System PLL input clock buffer
    cmp_clk_gtp_ref0_bufg : BUFG
      port map (
        I => clk_gtp_ref0,
        O => clk_gtp_ref0_bufg);

    clk_gtp_ref0_o      <= clk_gtp_ref0;
    clk_gtp_ref0_bufg_o <= clk_gtp_ref0_bufg;

    cmp_gtp_ref1_dedicated_clk : IBUFDS_GTE2
      generic map(
        CLKCM_CFG    => true,
        CLKRCV_TRST  => true,
        CLKSWING_CFG => "11")
      port map (
        O     => clk_gtp_ref1,
        ODIV2 => clk_gtp_ref1_div2,
        CEB   => '0',
        I     => clk_gtp_ref1_p_i,
        IB    => clk_gtp_ref1_n_i);

    -- System PLL input clock buffer
    cmp_clk_gtp_ref1_bufg : BUFG
      port map (
        I => clk_gtp_ref1_div2,
        O => clk_gtp_ref1_div2_bufg
      );

    cmp_gtp: wr_gtp_phy_family7
      generic map(
        g_simulation => g_simulation,
        g_gtrefclk_src => g_gtrefclk_src, 
        g_num_phys   => g_num_phys)
      port map(
        areset_i            => pll_arst,
        clk_ref_i           => clk_ref,
        gtrefclk0_i         => clk_gtp_ref0,
        gtrefclk1_i         => clk_gtp_ref1,
        clk_tx_o            => clk_tx,
        pll_locked_o        => pll_locked,
        sfp_rxn_i           => sfp_rxn_i,
        sfp_rxp_i           => sfp_rxp_i,
        sfp_txn_o           => sfp_txn_o,
        sfp_txp_o           => sfp_txp_o,
        phy16_o             => phy16_o,
        phy16_i             => phy16_i,
        PLL0OUTCLK_OUT      => PLL0OUTCLK_OUT,
        PLL0OUTREFCLK_OUT   => PLL0OUTREFCLK_OUT,
        PLL0LOCK_OUT        => PLL0LOCK_OUT,
        PLL0LOCKDETCLK_IN   => PLL0LOCKDETCLK_IN,
        PLL0REFCLKLOST_OUT  => PLL0REFCLKLOST_OUT,
        PLL0RESET_IN        => PLL0RESET_IN
        );

    GEN_PHY: for i in 0 to g_num_phys-1 generate

      phy16_o(i).ref_clk      <= clk_tx(i);
      phy16_o(i).sfp_tx_fault <= sfp_tx_fault_i(i);
      phy16_o(i).sfp_los      <= sfp_los_i(i);
      sfp_tx_disable_o(i)     <= phy16_i(i).sfp_tx_disable;

      GEN_REF_TXOUT:if(g_ref_clk_sel(i)='0') generate
        clk_ref(i)            <= clk_tx(i);
        clk_ref_locked_o(i)   <= pll_locked(i);
      end generate GEN_REF_TXOUT;

      GEN_REF_GTP_DIV2:if(g_ref_clk_sel(i)='1') generate

        GEN_REF_PLL0:if(g_gtrefclk_src(i)='0') generate
            clk_ref(i)           <= clk_gtp_ref0_div2_bufg;
            clk_ref_locked_o(i)  <= clk_gtp_ref0_locked_i;
        end generate GEN_REF_PLL0;

        GEN_REF_PLL1:if(g_gtrefclk_src(i)='1') generate
            clk_ref(i)           <= clk_gtp_ref1_div2_bufg;
            clk_ref_locked_o(i)  <= clk_gtp_ref1_locked_i;
        end generate GEN_REF_PLL1;

      end generate GEN_REF_GTP_DIV2;

    end generate GEN_PHY;
    
    clk_ref_o      <= clk_ref;
    phy8_o         <= (others=>c_dummy_phy8_to_wrc);

  end generate gen_phy_artix7;

  gen_no_ext_ref_pll : if (g_with_external_clock_input = FALSE) generate
    clk_ext_o             <= '0';
    clk_ext_mul_o         <= '0';
    clk_ext_mul_locked_o  <= '1';
    clk_ext_mul_stopped_o <= '1';
  end generate gen_no_ext_ref_pll;

  gen_with_ext_ref_pll : if (g_with_external_clock_input = TRUE) generate
    clk_ext_mul_locked_o  <= clk_ext_locked_i;
    clk_ext_mul_stopped_o <= clk_ext_stopped_i;
    cmp_clk_ext_mul_buf : BUFG
      port map (
        I => clk_ext_mul_i,
        O => clk_ext_mul_o
      );
    cmp_clk_ext_buf : BUFG
    port map (
      I => clk_ext_i,
      O => clk_ext_o
    );
  end generate gen_with_ext_ref_pll;

end architecture rtl;
