-------------------------------------------------------------------------------
-- Title      : WRPC Wrapper for CTS derived from SPEC package
-- Project    : WR PTP Core for CTS board
-------------------------------------------------------------------------------
-- File       : wr_cts_pkg.vhd
-- Author(s)  : Greg Daniluk <grzegorz.daniluk@cern.ch>
--              Genie Jhang <changj@frib.msu.edu>
-- Company    : CERN (BE-CO-HT)
--              FRIB
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Copyright (c) 2020 CERN
-- Copyright (c) 2024 FRIB
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

library work;
use work.wishbone_pkg.all;
use work.wrcore_pkg.all;
use work.wr_fabric_pkg.all;
use work.endpoint_pkg.all;
use work.wr_board_pkg.all;
use work.wr_xilinx_pkg.all;
use work.streamers_pkg.all;

package wr_cts_pkg is

  component xwrc_board_cts is
    generic(
      g_simulation                : integer              := 0;
      g_aux_clks                  : integer              := 0;
      g_fabric_iface              : t_board_fabric_iface := plain;
      g_streamers_op_mode         : t_streamers_op_mode  := TX_AND_RX;
      g_tx_streamer_params        : t_tx_streamer_params := c_tx_streamer_params_defaut;
      g_rx_streamer_params        : t_rx_streamer_params := c_rx_streamer_params_defaut;
      g_dpram_initf               : string               := "default_xilinx";
      g_diag_id                   : integer              := 0;
      g_diag_ver                  : integer              := 0;
      g_diag_ro_size              : integer              := 0;
      g_diag_rw_size              : integer              := 0;
      g_aux_sdb                   : t_sdb_device         := c_wrc_periph3_sdb
    );
    port (
      areset_n_i             : in  std_logic;
      areset_edge_n_i        : in  std_logic := '1';
      wr_clk_helper_125m_p_i : in  std_logic;
      wr_clk_helper_125m_n_i : in  std_logic;
      wr_clk_main_125m_p_i   : in  std_logic;
      wr_clk_main_125m_n_i   : in  std_logic;
      wr_clk_sfp_125m_p_i    : in  std_logic;
      wr_clk_sfp_125m_n_i    : in  std_logic;
      clk_aux_i              : in  std_logic_vector(g_aux_clks-1 downto 0) := (others => '0');
      clk_sys_62m5_o      : out std_logic;
      clk_ref_125m_o      : out std_logic;
      rst_sys_62m5_n_o    : out std_logic;
      rst_ref_125m_n_o    : out std_logic;
      plldac_sclk_o       : out std_logic;
      plldac_din_o        : out std_logic;
      pll25dac_cs_n_o     : out std_logic;
      pll20dac_cs_n_o     : out std_logic;
      sfp_txp_o           : out std_logic;
      sfp_txn_o           : out std_logic;
      sfp_rxp_i           : in  std_logic;
      sfp_rxn_i           : in  std_logic;
      sfp_det_i           : in  std_logic := '1';
      sfp_sda_i           : in  std_logic;
      sfp_sda_o           : out std_logic;
      sfp_scl_i           : in  std_logic;
      sfp_scl_o           : out std_logic;
      sfp_rate_select_o   : out std_logic;
      sfp_tx_fault_i      : in  std_logic := '0';
      sfp_tx_disable_o    : out std_logic;
      sfp_los_i           : in  std_logic := '0';
      eeprom_sda_i        : in  std_logic;
      eeprom_sda_o        : out std_logic;
      eeprom_scl_i        : in  std_logic;
      eeprom_scl_o        : out std_logic;
      uart_rxd_i          : in  std_logic;
      uart_txd_o          : out std_logic;
      wb_slave_o          : out t_wishbone_slave_out;
      wb_slave_i          : in  t_wishbone_slave_in := cc_dummy_slave_in;
      aux_master_o        : out t_wishbone_master_out;
      aux_master_i        : in  t_wishbone_master_in := cc_dummy_master_in;
      wrf_src_o           : out t_wrf_source_out;
      wrf_src_i           : in  t_wrf_source_in := c_dummy_src_in;
      wrf_snk_o           : out t_wrf_sink_out;
      wrf_snk_i           : in  t_wrf_sink_in   := c_dummy_snk_in;
      wrs_tx_data_i       : in  std_logic_vector(g_tx_streamer_params.data_width-1 downto 0) := (others => '0');
      wrs_tx_valid_i      : in  std_logic                                        := '0';
      wrs_tx_dreq_o       : out std_logic;
      wrs_tx_last_i       : in  std_logic                                        := '1';
      wrs_tx_flush_i      : in  std_logic                                        := '0';
      wrs_tx_cfg_i        : in  t_tx_streamer_cfg                                := c_tx_streamer_cfg_default;
      wrs_rx_first_o      : out std_logic;
      wrs_rx_last_o       : out std_logic;
      wrs_rx_data_o       : out std_logic_vector(g_rx_streamer_params.data_width-1 downto 0);
      wrs_rx_valid_o      : out std_logic;
      wrs_rx_dreq_i       : in  std_logic                                        := '0';
      wrs_rx_cfg_i        : in t_rx_streamer_cfg                                 := c_rx_streamer_cfg_default;
      wb_eth_master_o     : out t_wishbone_master_out;
      wb_eth_master_i     : in  t_wishbone_master_in := cc_dummy_master_in;
      aux_diag_i           : in  t_generic_word_array(g_diag_ro_size-1 downto 0) := (others => (others => '0'));
      aux_diag_o           : out t_generic_word_array(g_diag_rw_size-1 downto 0);
      tm_dac_value_o       : out std_logic_vector(31 downto 0);
      tm_dac_wr_o          : out std_logic_vector(g_aux_clks-1 downto 0);
      tm_clk_aux_lock_en_i : in  std_logic_vector(g_aux_clks-1 downto 0) := (others => '0');
      tm_clk_aux_locked_o  : out std_logic_vector(g_aux_clks-1 downto 0);
      timestamps_o        : out t_txtsu_timestamp;
      timestamps_ack_i    : in  std_logic := '1';
      abscal_txts_o       : out std_logic;
      abscal_rxts_o       : out std_logic;
      tm_link_up_o        : out std_logic;
      tm_time_valid_o     : out std_logic;
      tm_tai_o            : out std_logic_vector(39 downto 0);
      tm_cycles_o         : out std_logic_vector(27 downto 0);
      led_act_o           : out std_logic;
      led_link_o          : out std_logic;
      pps_p_o             : out std_logic;
      pps_led_o           : out std_logic;
      link_ok_o           : out std_logic);
  end component xwrc_board_cts;

end wr_cts_pkg;
