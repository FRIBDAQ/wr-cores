-------------------------------------------------------------------------------
-- SPDX-FileCopyrightText: 2010 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+
-------------------------------------------------------------------------------
-- Title      : 1000base-X MAC/Endpoint
-- Project    : White Rabbit 
-------------------------------------------------------------------------------
-- File       : endpoint_pkg.vhd
-- Author     : Tomasz Wlostowski
-- Company    : CERN BE-CO-HT
-- Created    : 2010-04-26
-- Last update: 2023-03-13
-- Platform   : FPGA-generic
-- Standard   : VHDL '93
-------------------------------------------------------------------------------
-- Description: Public package for the WR Endpoint. Contains public data
-- structures and component declarations.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wishbone_pkg.all;
use work.wr_fabric_pkg.all;

package endpoint_pkg is

  function f_pcs_data_width(pcs_16 : boolean) return integer;
  function f_pcs_k_width(pcs_16 : boolean) return integer;
  function f_pcs_bts_width(pcs_16 : boolean) return integer;
  function f_pcs_clock_rate(pcs_16 : boolean) return integer;

  type t_txtsu_timestamp is record
    stb       : std_logic;
    tsval     : std_logic_vector(31 downto 0);
    port_id   : std_logic_vector(5 downto 0);
    frame_id  : std_logic_vector(15 downto 0);
    incorrect : std_logic;
  end record;

  type t_txtsu_timestamp_array is array(integer range <>) of t_txtsu_timestamp;

  -- Endpoint's internal fabric used to connect the submodules with each other.
  -- Easier to handle than pipelined Wishbone.
  type t_ep_internal_fabric is record
    sof                : std_logic;
    eof                : std_logic;
    error              : std_logic;
    dvalid             : std_logic;
    bytesel            : std_logic;
    has_rx_timestamp   : std_logic;
    rx_timestamp_valid : std_logic;
    data               : std_logic_vector(15 downto 0);
    addr               : std_logic_vector(1 downto 0);
  end record;
  type t_fab_pipe is array(integer range <>) of t_ep_internal_fabric;

  -----------------------------
  -- Phy i/f types
  -----------------------------
  -- 8-bit Serdes
  type t_phy_8bits_to_wrc is record
    ref_clk        : std_logic;
    tx_disparity   : std_logic;
    tx_enc_err     : std_logic;
    rx_data        : std_logic_vector(7 downto 0);
    rx_clk         : std_logic;
    rx_sampled_clk : std_logic;
    rx_k           : std_logic_vector(0 downto 0);
    rx_enc_err     : std_logic;
    rx_bitslide    : std_logic_vector(3 downto 0);
    rdy            : std_logic;
    sfp_tx_fault   : std_logic;
    sfp_los        : std_logic;
  end record;
  type t_phy_8bits_from_wrc is record
    rst            : std_logic;
    loopen         : std_logic;
    tx_data        : std_logic_vector(7 downto 0);
    tx_k           : std_logic_vector(0 downto 0);
    loopen_vec     : std_logic_vector(2 downto 0);
    tx_prbs_sel    : std_logic_vector(2 downto 0);
    sfp_tx_disable : std_logic;
  end record;

  constant c_dummy_phy8_to_wrc : t_phy_8bits_to_wrc :=
    ('0', '0', '0', (others=>'0'), '0', '0', (others=>'0'), '0',
    (others=>'0'), '0', '0', '0');
  constant c_dummy_phy8_from_wrc : t_phy_8bits_from_wrc :=
    ('0', '0', (others=>'0'), (others=>'0'), (others=>'0'),
    (others=>'0'), '0');

  -- 16-bit Serdes
  type t_phy_16bits_to_wrc is record
    ref_clk        : std_logic;
    tx_disparity   : std_logic;
    tx_enc_err     : std_logic;
    rx_data        : std_logic_vector(15 downto 0);
    rx_clk         : std_logic;
    rx_sampled_clk : std_logic;
    rx_k           : std_logic_vector(1 downto 0);
    rx_enc_err     : std_logic;
    rx_bitslide    : std_logic_vector(4 downto 0);
    rdy            : std_logic;
    sfp_tx_fault   : std_logic;
    sfp_los        : std_logic;
  end record;

  type t_phy_16bits_from_wrc is record
    rst            : std_logic;
    loopen         : std_logic;
    tx_data        : std_logic_vector(15 downto 0);
    tx_k           : std_logic_vector(1 downto 0);
    loopen_vec     : std_logic_vector(2 downto 0);
    tx_prbs_sel    : std_logic_vector(2 downto 0);
    sfp_tx_disable : std_logic;
  end record;

  constant c_dummy_phy16_to_wrc : t_phy_16bits_to_wrc :=
    ('0', '0', '0', (others=>'0'), '0', '0', (others=>'0'), '0',
    (others=>'0'), '0', '0', '0');
  constant c_dummy_phy16_from_wrc : t_phy_16bits_from_wrc :=
    ('0', '0', (others=>'0'), (others=>'0'), (others=>'0'),
    (others=>'0'), '0');


  -- debug CS types
  type t_dbg_ep_rxpcs is record
    fsm : std_logic_vector(2 downto 0);
  end record;

  type t_dbg_ep_pcs is record
    rx : t_dbg_ep_rxpcs;
  end record;

  type t_dbg_rtu_extract is record
    in_packet : std_logic;
    in_header : std_logic;
    rtu_rq_valid_basic : std_logic;
    rtu_rq_valid_tagged : std_logic;
    rtu_rq_abort  : std_logic;
  end record;

  type t_dbg_ep_rxpath is record
    fab_pipe  : t_fab_pipe(9 downto 0);
    dreq_pipe : std_logic_vector(9 downto 0);
    pcs_fifo_afull : std_logic;
    pcs_fifo_empty : std_logic;
    pcs_fifo_full  : std_logic;
    rxbuf_full     : std_logic;
    rtu_extract    : t_dbg_rtu_extract;
  end record;

  type t_dbg_ep is record
    pcs    : t_dbg_ep_pcs;
    rxpath : t_dbg_ep_rxpath;
  end record;
  ------------------------------------

  constant c_epevents_sz  : integer := 29;  --how many events the endpoint generates

  constant c_xwr_endpoint_sdb : t_sdb_device := (
    abi_class     => x"0000",              -- undocumented device
    abi_ver_major => x"01",
    abi_ver_minor => x"01",
    wbd_endian    => c_sdb_endian_big,
    wbd_width     => x"7",                 -- 8/16/32-bit port granularity
    sdb_component => (
      addr_first  => x"0000000000000000",
      addr_last   => x"000000000000007f",
      product     => (
        vendor_id => x"000000000000CE42",  -- CERN
        device_id => x"650c2d4f",
        version   => x"00000002",
        date      => x"20121116",
        name      => "WR-Endpoint        ")));

end endpoint_pkg;

package body endpoint_pkg is

  function f_pcs_data_width(pcs_16 : boolean)
    return integer is
  begin
    if (pcs_16) then
      return 16;
    else
      return 8;
    end if;
  end function;

  function f_pcs_k_width(pcs_16 : boolean)
    return integer is
  begin
    if (pcs_16) then
      return 2;
    else
      return 1;
    end if;
  end function;

  function f_pcs_bts_width(pcs_16 : boolean)
    return integer is
  begin
    if (pcs_16) then
      return 5;
    else
      return 4;
    end if;
  end function;

  function f_pcs_clock_rate(pcs_16 : boolean)
    return integer is
  begin
    if (pcs_16) then
      return 62500000;
    else
      return 125000000;
    end if;
  end function;

end package body endpoint_pkg;
