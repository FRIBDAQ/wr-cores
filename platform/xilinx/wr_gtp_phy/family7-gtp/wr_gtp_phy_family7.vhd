-------------------------------------------------------------------------------
-- Title      : Deterministic Xilinx GTP wrapper - artix-7 top module
-- Project    : White Rabbit Switch
-------------------------------------------------------------------------------
-- File       : wr_gtp_phy_family7.vhd
-- Author     : Peter Jansweijer, Rick Lohlefink, Tomasz Wlostowski
-- Company    : Nikhef, CERN BE-CO-HT
-- Created    : 2016-05-19
-- Last update: 2016-05-19
-- Platform   : FPGA-generic
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Dual channel wrapper for Xilinx Artix-7 GTP adapted for
-- deterministic delays at 1.25 Gbps.
-------------------------------------------------------------------------------
--
-- Copyright (c) 2009-2011 CERN / BE-CO-HT
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
--
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author    Description
-- 2016-05-19  0.1      PeterJ    Initial release based on "wr_gtx_phy_kintex7.vhd"
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.gencores_pkg.all;

library unisim;
use unisim.vcomponents.all;

library work;

use work.disparity_gen_pkg.all;
use work.endpoint_pkg.all;
use work.wr_gtp_phy_pkg.all;

entity wr_gtp_phy_family7 is
  generic (
    -- set to non-zero value to speed up the simulation by reducing some delays
    g_simulation     : integer := 0;
    g_gtrefclk_src   : std_logic_vector(3 downto 0);
    g_num_phys       : integer := 1
  );
  port (
    areset_i         : in   std_logic;
    clk_ref_i        : in   std_logic_vector(g_num_phys-1 downto 0):=(others=>'0');
    -- Dedicated reference 125 MHz clock for the GTP transceiver
    gtrefclk0_i      : in   std_logic:='0';
    gtrefclk1_i      : in   std_logic:='0';

    -- TX path, synchronous to clk_tx_o (62.5 MHz):
    clk_tx_o         : out  std_logic_vector(g_num_phys-1 downto 0);
    pll_locked_o     : out  std_logic_vector(g_num_phys-1 downto 0);

    phy16_o          : out t_phy_16bits_to_wrc_array(g_num_phys-1 downto 0);
    phy16_i          : in  t_phy_16bits_from_wrc_array(g_num_phys-1 downto 0):=(others=>c_dummy_phy16_from_wrc);

    sfp_rxn_i        : in   std_logic_vector(g_num_phys-1 downto 0):=(others=>'0');
    sfp_rxp_i        : in   std_logic_vector(g_num_phys-1 downto 0):=(others=>'0');
    sfp_txn_o        : out  std_logic_vector(g_num_phys-1 downto 0);
    sfp_txp_o        : out  std_logic_vector(g_num_phys-1 downto 0);

    PLL0OUTCLK_OUT     : out std_logic;
    PLL0OUTREFCLK_OUT  : out std_logic;
    PLL0LOCK_OUT       : out std_logic;
    PLL0LOCKDETCLK_IN  : in  std_logic;
    PLL0REFCLKLOST_OUT : out std_logic;
    PLL0RESET_IN       : in  std_logic
  );
end entity wr_gtp_phy_family7;

--------------------------------------------------------------------------------
-- Object        : Architecture work.wr_gtp_phy_family7.structure
-- Last modified : Mon Nov 23 12:54:18 2015.
--------------------------------------------------------------------------------

architecture structure of wr_gtp_phy_family7 is

  constant REQ_DELAY           : integer := 500;                      -- unit = ns
  constant CLK_PER             : integer := 16;                       -- unit = ns
  constant INITIAL_WAIT_CYCLES : integer := REQ_DELAY / CLK_PER;      -- Required 500 ns divided by RefClk period
  constant TOTAL_DELAY         : integer := INITIAL_WAIT_CYCLES + 10; -- Add 10 clock cycles as delay to be sure
  
  constant c_rxcdrlock_max     : integer := 3;
  constant c_reset_cnt_max     : integer := 32;                       -- Reset pulse width 32 * 16 = 512 ns
  
  type state_type is (init, count, count_done, wait_reset);
  type state_type_array is array(integer range <>) of state_type;
  signal state : state_type_array(g_num_phys-1 downto 0);
  
  signal areset             : std_logic_vector(g_num_phys-1 downto 0);
  signal rst_synced         : std_logic_vector(g_num_phys-1 downto 0);
  signal rst_int            : std_logic_vector(g_num_phys-1 downto 0);
  signal gttxreset          : std_logic_vector(g_num_phys-1 downto 0);

  signal PLL_RESET          : std_logic_vector(g_num_phys-1 downto 0);
  signal clk_tx_buf         : std_logic_vector(g_num_phys-1 downto 0);
  signal pll_locked         : std_logic_vector(g_num_phys-1 downto 0);
  signal pll_refclklost     : std_logic_vector(g_num_phys-1 downto 0);
  signal pll_locked_n       : std_logic_vector(g_num_phys-1 downto 0);

  signal PLL0REFCLKSEL      : std_logic_vector(2 downto 0);
  signal PLL1REFCLKSEL      : std_logic_vector(2 downto 0);
  signal PLL0PD             : std_logic;
  signal PLL1PD             : std_logic;
  signal PLL0RESET          : std_logic;
  signal PLL1RESET          : std_logic;
  signal PLL0LOCK           : std_logic;
  signal PLL1LOCK           : std_logic;
  signal PLL0REFCLKLOST     : std_logic;
  signal PLL1REFCLKLOST     : std_logic;

  signal GT_CHANNEL_SIG_i   : t_gtpe2_channel_in_array(g_num_phys-1 downto 0);
  signal GT_CHANNEL_SIG_o   : t_gtpe2_channel_out_array(g_num_phys-1 downto 0);

  type t_GTP_signals is record
    RXOUTCLK_BUF         : std_logic;
    RXSLIDE              : std_logic;
    GTRXRESET_forced     : std_logic;
    GTRXRESET            : std_logic;
    rst_synced           : std_logic;
    rst_int              : std_logic;
    rx_lost_lock         : std_logic;
    serdes_ready         : std_logic;
    rx_synced            : std_logic;
    rst_done             : std_logic;
    rst_done_n           : std_logic;
    CUR_DISP             : t_8b10b_disparity;
  end record;

  type t_gs is array(integer range <>) of t_GTP_signals;
  signal gs : t_gs(g_num_phys-1 downto 0);  

  component whiterabbit_gtpe2_channel_wrapper is
  generic
  (
      PLL0_FBDIV                     : integer := 4;
      PLL0_FBDIV_45                  : integer := 5;
      PLL0_REFCLK_DIV                : integer := 1;
      PLL1_FBDIV                     : integer := 4;
      PLL1_FBDIV_45                  : integer := 5;
      PLL1_REFCLK_DIV                : integer := 1;
      g_num_phys                     : integer := 1;
      -- Simulation attributes
      EXAMPLE_SIMULATION             : integer  := 0;      -- Set to 1 for simulation
      WRAPPER_SIM_GTRESET_SPEEDUP    : string := "FALSE" -- Set to "true" to speed up sim reset
  );
  port
  (
      GT_CHANNEL_SIG_i         : in  t_gtpe2_channel_in_array(g_num_phys-1 downto 0);
      GT_CHANNEL_SIG_o         : out t_gtpe2_channel_out_array(g_num_phys-1 downto 0);

      GTREFCLK0                : in  std_logic;
      GTREFCLK1                : in  std_logic;
      PLL0REFCLKSEL            : in  std_logic_vector:="001";
      PLL1REFCLKSEL            : in  std_logic_vector:="010";
      PLL0PD                   : in  std_logic:='0';
      PLL1PD                   : in  std_logic:='0';
      PLL0RESET                : in  std_logic:='0';
      PLL1RESET                : in  std_logic:='0';
      PLL0LOCK                 : out std_logic;
      PLL1LOCK                 : out std_logic;
      PLL0REFCLKLOST           : out std_logic;
      PLL1REFCLKLOST           : out std_logic;

      PLL0OUTCLK_OUT           : out std_logic;
      PLL0OUTREFCLK_OUT        : out std_logic;
      PLL0LOCK_OUT             : out std_logic;
      PLL0LOCKDETCLK_IN        : in  std_logic;
      PLL0REFCLKLOST_OUT       : out std_logic;
      PLL0RESET_IN             : in  std_logic
  );
  end component whiterabbit_gtpe2_channel_wrapper;
  
  component gtp_bitslide is
  generic (
    g_simulation             :    integer;
    g_target                 :    string := "artix7"
  );
  port (
    gtp_rst_i                : in  std_logic;
    gtp_rx_clk_i             : in  std_logic;
    gtp_rx_comma_det_i       : in  std_logic;
    gtp_rx_byte_is_aligned_i : in  std_logic;
    serdes_ready_i           : in  std_logic;
    gtp_rx_slide_o           : out std_logic;
    gtp_rx_cdr_rst_o         : out std_logic;
    bitslide_o               : out std_logic_vector(4 downto 0);
    synced_o                 : out std_logic
  );
  end component;

  function f_to_bool(x : integer) return string is
    begin
      if(x /= 0) then
        return "TRUE";
      else
        return "FALSE";
      end if;
    end f_to_bool;

begin

  gen_RESET: for i in 0 to (g_num_phys-1) generate

    areset(i) <= areset_i or phy16_i(i).rst;
    -- PLL reset
    U_EdgeDet_areset_i : gc_sync_ffs port map (
      clk_i     => clk_ref_i(i),
      rst_n_i   => '1',
      data_i    => areset(i),
      ppulse_o  => rst_synced(i));

    process(clk_ref_i(i), rst_synced(i))
      variable reset_cnt      : integer range 0 to c_reset_cnt_max;
    begin
      if(rst_synced(i) = '1') then
        reset_cnt := 0;
        rst_int(i) <= '1';
      elsif rising_edge(clk_ref_i(i)) then
        if reset_cnt /= c_reset_cnt_max then
          reset_cnt := reset_cnt + 1;
          rst_int(i) <= '1';
        else
          rst_int(i) <= '0';
        end if;
      end if;
    end process;  

  -- ug482 "GTP Transceiver TX/RX Reset in Response to Completion of Configuration"
  --   1. Wait a minimum of 500 ns after configuration is complete
    process(clk_ref_i(i), rst_int(i)) is
      variable reset_counter : integer range 0 to TOTAL_DELAY := 0;
    begin
      if rst_int(i) = '1' then
        state(i) <= init;
      elsif rising_edge(clk_ref_i(i)) then
        case state(i) is
          when init =>
            reset_counter := 0;
            state(i) <= count;
          when count =>
            if reset_counter = TOTAL_DELAY then
              reset_counter := 0;
              state(i) <= count_done;
            else
              reset_counter := reset_counter + 1;
              state(i) <= count;
            end if;
          when count_done =>
            state(i) <= wait_reset;
          when wait_reset =>
            state(i) <= wait_reset;
        end case;
      end if;
    end process;

  end generate gen_RESET;

  PLL0REFCLKSEL   <= "001";
  PLL1REFCLKSEL   <= "010";

  PLL0PD          <= '0';
  PLL1PD          <= '0';

  PLL1RESET          <= PLL_RESET(0);
  gen_SYSCLKSEL: for i in 0 to g_num_phys-1 generate
    
    PLL_RESET(i)    <= '1' when state(i) = count_done else '0';

    gen_refclk_pll0 : if(g_gtrefclk_src(i)='0') generate
      pll_locked(i)      <= PLL0LOCK;
      pll_locked_o(i)    <= PLL0LOCK;
      pll_locked_n(i)    <= not pll_locked(i);
      pll_refclklost(i)  <= PLL0REFCLKLOST;
      GT_CHANNEL_SIG_i(i).RXSYSCLKSEL <= "00";
      GT_CHANNEL_SIG_i(i).TXSYSCLKSEL <= "00";
    end generate gen_refclk_pll0;

    gen_refclk_pll1 : if(g_gtrefclk_src(i)='1') generate
      pll_locked(i)      <= PLL1LOCK;
      pll_locked_o(i)    <= PLL1LOCK;
      pll_locked_n(i)    <= not pll_locked(i);
      pll_refclklost(i)  <= PLL1REFCLKLOST;
      GT_CHANNEL_SIG_i(i).RXSYSCLKSEL <= "11";
      GT_CHANNEL_SIG_i(i).TXSYSCLKSEL <= "11";
    end generate gen_refclk_pll1;
  
  end generate gen_SYSCLKSEL;


  U_GTP_INST : whiterabbit_gtpe2_channel_wrapper
  generic map
  (
    -- Simulation attributes
    g_num_phys                   => g_num_phys,
    EXAMPLE_SIMULATION           => g_simulation,
    WRAPPER_SIM_GTRESET_SPEEDUP  => f_to_bool(g_simulation)
  )
  port map
  (
    GT_CHANNEL_SIG_i         =>  GT_CHANNEL_SIG_i,
    GT_CHANNEL_SIG_o         =>  GT_CHANNEL_SIG_o,

    GTREFCLK0                =>  gtrefclk0_i,
    GTREFCLK1                =>  gtrefclk1_i,
    PLL0REFCLKSEL            =>  PLL0REFCLKSEL,
    PLL1REFCLKSEL            =>  PLL1REFCLKSEL,
    PLL0RESET                =>  PLL0RESET,
    PLL1RESET                =>  PLL1RESET,
    PLL0PD                   =>  PLL0PD,
    PLL1PD                   =>  PLL1PD,
    PLL0LOCK                 =>  PLL0LOCK,
    PLL1LOCK                 =>  PLL1LOCK,
    PLL0REFCLKLOST           =>  PLL0REFCLKLOST,
    PLL1REFCLKLOST           =>  PLL1REFCLKLOST,
    PLL0OUTCLK_OUT           =>  PLL0OUTCLK_OUT,
    PLL0OUTREFCLK_OUT        =>  PLL0OUTREFCLK_OUT,
    PLL0LOCK_OUT             =>  PLL0LOCK_OUT,
    PLL0LOCKDETCLK_IN        =>  PLL0LOCKDETCLK_IN,
    PLL0REFCLKLOST_OUT       =>  PLL0REFCLKLOST_OUT,
    PLL0RESET_IN             =>  PLL0RESET_IN
  );

gen_GTP: for i in 0 to (g_num_phys-1) generate

  clk_tx_o(i)    <=  clk_tx_buf(i);

  U_BUF_TxOutClk: BUFG
    port map(
      I => GT_CHANNEL_SIG_o(i).TXOUTCLK,
      O => clk_tx_buf(i));

  -- LPDC signals
  gttxreset(i)                               <= pll_locked_n(i) or phy16_i(i).lpc_ctrl(0);
  phy16_o(i).lpc_stat(0)                     <= GT_CHANNEL_SIG_o(i).TXRESETDONE;

  GT_CHANNEL_SIG_i(i).RST_IN                 <= '1' when state(i) = count_done else '0';
  GT_CHANNEL_SIG_i(i).DRPCLK_IN              <=  clk_ref_i(i);
  GT_CHANNEL_SIG_i(i).DRPDI_IN               <=  (others => '0');
  GT_CHANNEL_SIG_i(i).DRPEN_IN               <=  '0';
  GT_CHANNEL_SIG_i(i).DRPWE_IN               <=  '0';
  GT_CHANNEL_SIG_i(i).LOOPBACK               <=  phy16_i(i).loopen_vec;
  GT_CHANNEL_SIG_i(i).RXUSERRDY              <=  pll_locked(i);
  GT_CHANNEL_SIG_i(i).RXUSRCLK               <=  gs(i).RXOUTCLK_BUF;
  GT_CHANNEL_SIG_i(i).RXUSRCLK2              <=  gs(i).RXOUTCLK_BUF;
  GT_CHANNEL_SIG_i(i).GTPRXN                 <=  sfp_rxn_i(i);
  GT_CHANNEL_SIG_i(i).GTPRXP                 <=  sfp_rxp_i(i);
  GT_CHANNEL_SIG_i(i).RXSLIDE                <=  gs(i).RXSLIDE;
  GT_CHANNEL_SIG_i(i).RXLPMHFHOLD            <=  '0';
  GT_CHANNEL_SIG_i(i).RXLPMLFHOLD            <=  '0';
  GT_CHANNEL_SIG_i(i).GTRXRESET              <=  gs(i).GTRXRESET;
  GT_CHANNEL_SIG_i(i).GTTXRESET              <=  gttxreset(i);
  GT_CHANNEL_SIG_i(i).TXUSERRDY              <=  pll_locked(i);
  GT_CHANNEL_SIG_i(i).TXDATA(15 downto 0)    <=  phy16_i(i).tx_data(7 downto 0) & phy16_i(i).tx_data(15 downto 8);
  GT_CHANNEL_SIG_i(i).TXUSRCLK               <=  clk_tx_buf(i);
  GT_CHANNEL_SIG_i(i).TXUSRCLK2              <=  clk_tx_buf(i);
  GT_CHANNEL_SIG_i(i).TXCHARISK(1 downto 0)  <=  phy16_i(i).tx_k(0) & phy16_i(i).tx_k(1);
  GT_CHANNEL_SIG_i(i).TXPRBSSEL              <=  phy16_i(i).tx_prbs_sel;

  sfp_txn_o(i)                               <=  GT_CHANNEL_SIG_o(i).GTPTXN;
  sfp_txp_o(i)                               <=  GT_CHANNEL_SIG_o(i).GTPTXP;
 
  -- 7-Series GTP RXCDRLOCK is reserved (ug482 Table 4.11) and can not be used for detection of proper RX lock.
  -- Instead use GT_RXNOTINTABLE (i.e. RXNOTINTABLE) to check integrity of the received characters.
  process(gs(i).RXOUTCLK_BUF, gs(i).rst_int) is
  begin
    if gs(i).rst_int = '1' then
      gs(i).rx_lost_lock <= '1';
    elsif rising_edge(gs(i).RXOUTCLK_BUF) then
      if gs(i).rx_synced = '1' then
        if GT_CHANNEL_SIG_o(i).RXNOTINTABLE(1 downto 0) > "00" then
          gs(i).rx_lost_lock <= '1';
        else
          gs(i).rx_lost_lock <= '0';
        end if;
      else
        gs(i).rx_lost_lock <= '0';
      end if;
    end if;
  end process;

  U_BUF_RxRecClk: BUFG
    port map(
      I => GT_CHANNEL_SIG_o(i).RXOUTCLK,
      O => gs(i).RXOUTCLK_BUF);

  U_Bitslide : gtp_bitslide
  generic map (
    g_simulation             =>  g_simulation,
    g_target                 =>  ("artix7")
  )
  port map (
    gtp_rst_i                =>  gs(i).rst_done_n,
    gtp_rx_clk_i             =>  gs(i).RXOUTCLK_BUF,
    gtp_rx_comma_det_i       =>  GT_CHANNEL_SIG_o(i).RXCOMMADET,
    gtp_rx_byte_is_aligned_i =>  GT_CHANNEL_SIG_o(i).RXBYTEISALIGNED,
    serdes_ready_i           =>  gs(i).serdes_ready,
    gtp_rx_slide_o           =>  gs(i).RXSLIDE,
    gtp_rx_cdr_rst_o         =>  gs(i).GTRXRESET_forced,
    bitslide_o               =>  phy16_o(i).rx_bitslide,
    synced_o                 =>  gs(i).rx_synced
  );

  gs(i).serdes_ready     <= not gs(i).rx_lost_lock and pll_locked(i) and GT_CHANNEL_SIG_o(i).TXRESETDONE and GT_CHANNEL_SIG_o(i).RXRESETDONE;
  gs(i).rst_done         <= GT_CHANNEL_SIG_o(i).TXRESETDONE and GT_CHANNEL_SIG_o(i).RXRESETDONE;
  gs(i).rst_done_n       <= not gs(i).rst_done;
  gs(i).GTRXRESET        <= pll_locked_n(i) or gs(i).GTRXRESET_forced;
  phy16_o(i).rdy         <= gs(i).serdes_ready;
  phy16_o(i).tx_enc_err  <= '0';
  phy16_o(i).rx_clk      <= gs(i).RXOUTCLK_BUF;
  phy16_o(i).tx_disparity <= to_std_logic(gs(i).CUR_DISP);

  p_gen_rx_outputs : process(gs(i).RXOUTCLK_BUF, gs(i).rst_done_n)
  begin
    if(gs(i).rst_done_n = '1') then
      phy16_o(i).rx_data <= (others => '0');
      phy16_o(i).rx_k        <= (others => '0');
      phy16_o(i).rx_enc_err  <= '0';
    elsif rising_edge(gs(i).RXOUTCLK_BUF) then
      if(gs(i).serdes_ready = '1' and gs(i).rx_synced = '1') then
        phy16_o(i).rx_data    <= GT_CHANNEL_SIG_o(i).RXDATA(7 downto 0) & GT_CHANNEL_SIG_o(i).RXDATA(15 downto 8);
        phy16_o(i).rx_k       <= GT_CHANNEL_SIG_o(i).RXCHARISK(0) & GT_CHANNEL_SIG_o(i).RXCHARISK(1);
        phy16_o(i).rx_enc_err <= GT_CHANNEL_SIG_o(i).RXDISPERR(0) or GT_CHANNEL_SIG_o(i).RXDISPERR(1) or GT_CHANNEL_SIG_o(i).RXNOTINTABLE(0) or GT_CHANNEL_SIG_o(i).RXNOTINTABLE(1);
      else
        phy16_o(i).rx_data    <= (others => '1');
        phy16_o(i).rx_k       <= (others => '1');
        phy16_o(i).rx_enc_err <= '1';
      end if;
    end if;
  end process;

  p_gen_tx_disparity : process(clk_tx_buf, gs(i).rst_done_n)
  begin
    if rising_edge(clk_tx_buf(i)) then
      if gs(i).rst_done_n = '1' then
        gs(i).CUR_DISP <= RD_MINUS;
      else
        gs(i).CUR_DISP <= f_next_8b10b_disparity16(gs(i).CUR_DISP, phy16_i(i).tx_k, phy16_i(i).tx_data);
      end if;
    end if;
  end process;

end generate gen_GTP;

end architecture structure ; -- of wr_gtp_phy_family7

