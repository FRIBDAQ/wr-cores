-------------------------------------------------------------------------------
-- SPDX-FileCopyrightText: 2010 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+
-------------------------------------------------------------------------------
-- Title      : Mini Embedded DMA Network Interface Controller
-- Project    : WhiteRabbit Core
-------------------------------------------------------------------------------
-- File       : wrsw_mini_nic.vhd
-- Author     : Grzegorz Daniluk, Tomasz Wlostowski
-- Company    : CERN BE-Co-HT
-- Created    : 2010-07-26
-- Last update: 2018-03-19
-- Platform   : FPGA-generic
-- Standard   : VHDL
-------------------------------------------------------------------------------
-- Description: Module implements a simple NIC with DMA controller. It
-- sends/receives the packets using WR switch fabric interface (see the
-- wrsw_endpoint.vhd for the details). Packets are stored and read from the
-- system memory via simple memory bus. WR endpoint-compatible TX timestamping
-- unit is also included.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2010-07-26  1.0      twlostow        Created
-- 2010-08-16  1.0      twlostow        Bugfixes, linux compatibility added
-- 2011-08-03  2.0      greg.d          rewritten to use pipelined Wishbone
-- 2011-10-45  2.1      twlostow        bugfixes...
-- 2016-10-27  3.0      greg.d          rewritten with Tx/Rx FIFOs
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

use work.wr_fabric_pkg.all;
use work.wishbone_pkg.all;

entity wr_mini_nic is
  generic (
    g_interface_mode       : t_wishbone_interface_mode      := CLASSIC;
    g_address_granularity  : t_wishbone_address_granularity := WORD;
    g_tx_fifo_size         : integer                        := 1024;
    g_rx_fifo_size         : integer                        := 2048;
    g_buffer_little_endian : boolean                        := false);

  port (
    clk_sys_i : in std_logic;
    rst_n_i   : in std_logic;

-------------------------------------------------------------------------------
-- Pipelined Wishbone interface
-------------------------------------------------------------------------------

    -- WBP Master (TX)
    src_dat_o   : out std_logic_vector(15 downto 0);
    src_adr_o   : out std_logic_vector(1 downto 0);
    src_sel_o   : out std_logic_vector(1 downto 0);
    src_cyc_o   : out std_logic;
    src_stb_o   : out std_logic;
    src_we_o    : out std_logic;
    src_stall_i : in  std_logic;
    src_err_i   : in  std_logic;
    src_ack_i   : in  std_logic;

    -- WBP Slave (RX)
    snk_dat_i   : in  std_logic_vector(15 downto 0);
    snk_adr_i   : in  std_logic_vector(1 downto 0);
    snk_sel_i   : in  std_logic_vector(1 downto 0);
    snk_cyc_i   : in  std_logic;
    snk_stb_i   : in  std_logic;
    snk_we_i    : in  std_logic;
    snk_stall_o : out std_logic;
    snk_err_o   : out std_logic;
    snk_ack_o   : out std_logic;

-------------------------------------------------------------------------------
-- TXTSU i/f
-------------------------------------------------------------------------------

    txtsu_port_id_i     : in  std_logic_vector(4 downto 0);
    txtsu_frame_id_i    : in  std_logic_vector(16 - 1 downto 0);
    txtsu_tsval_i       : in  std_logic_vector(28 + 4 - 1 downto 0);
    txtsu_tsincorrect_i : in  std_logic;
    txtsu_stb_i         : in  std_logic;
    txtsu_ack_o         : out std_logic;

-------------------------------------------------------------------------------
-- Wishbone slave
-------------------------------------------------------------------------------    

    wb_cyc_i   : in  std_logic;
    wb_stb_i   : in  std_logic;
    wb_we_i    : in  std_logic;
    wb_sel_i   : in  std_logic_vector(c_wishbone_data_width/8-1 downto 0);
    wb_adr_i   : in  std_logic_vector(c_wishbone_address_width-1 downto 0);
    wb_dat_i   : in  std_logic_vector(c_wishbone_data_width-1 downto 0);
    wb_dat_o   : out std_logic_vector(c_wishbone_data_width-1 downto 0);
    wb_ack_o   : out std_logic;
    wb_stall_o : out std_logic;

-------------------------------------------------------------------------------
-- Interrupt output
-------------------------------------------------------------------------------

    int_o   : out std_logic
    );
end wr_mini_nic;

architecture behavioral of wr_mini_nic is
  signal wb_in  : t_wishbone_master_in;
  signal wb_out : t_wishbone_master_out;

  signal snk_rty : std_logic;
begin  -- wrapper
  U_Slave_Adapter : wb_slave_adapter
    generic map (
      g_master_use_struct  => true,
      g_master_mode        => CLASSIC,
      g_master_granularity => BYTE,
      g_slave_use_struct   => false,
      g_slave_mode         => g_interface_mode,
      g_slave_granularity  => g_address_granularity)
    port map (
      clk_sys_i  => clk_sys_i,
      rst_n_i    => rst_n_i,
      sl_adr_i   => wb_adr_i,
      sl_dat_i   => wb_dat_i,
      sl_sel_i   => wb_sel_i,
      sl_cyc_i   => wb_cyc_i,
      sl_stb_i   => wb_stb_i,
      sl_we_i    => wb_we_i,
      sl_dat_o   => wb_dat_o,
      sl_ack_o   => wb_ack_o,
      sl_stall_o => wb_stall_o,
      master_i   => wb_in,
      master_o   => wb_out);

  inst_minic : entity work.xwr_mini_nic
    generic map (
      g_tx_fifo_size         => g_tx_fifo_size,
      g_rx_fifo_size         => g_rx_fifo_size,
      g_buffer_little_endian => g_buffer_little_endian)
    port map (
      clk_sys_i           => clk_sys_i,
      rst_n_i             => rst_n_i,
      src_o.dat           => src_dat_o,
      src_o.adr           => src_adr_o,
      src_o.sel           => src_sel_o,
      src_o.cyc           => src_cyc_o,
      src_o.stb           => src_stb_o,
      src_o.we            => src_we_o,
      src_i.stall         => src_stall_i,
      src_i.err           => src_err_i,
      src_i.ack           => src_ack_i,
      src_i.rty           => '0',
      snk_i.dat           => snk_dat_i,
      snk_i.adr           => snk_adr_i,
      snk_i.sel           => snk_sel_i,
      snk_i.cyc           => snk_cyc_i,
      snk_i.stb           => snk_stb_i,
      snk_i.we            => snk_we_i,
      snk_o.stall         => snk_stall_o,
      snk_o.err           => snk_err_o,
      snk_o.ack           => snk_ack_o,
      snk_o.rty           => snk_rty,
      txtsu_port_id_i     => txtsu_port_id_i,
      txtsu_frame_id_i    => txtsu_frame_id_i,
      txtsu_tsval_i       => txtsu_tsval_i,
      txtsu_tsincorrect_i => txtsu_tsincorrect_i,
      txtsu_stb_i         => txtsu_stb_i,
      txtsu_ack_o         => txtsu_ack_o,
      wb_i                => wb_out,
      wb_o                => wb_in,
      int_o               => int_o);
end behavioral;
