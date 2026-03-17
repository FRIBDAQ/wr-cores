-------------------------------------------------------------------------------
-- SPDX-FileCopyrightText: 2011 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+
-------------------------------------------------------------------------------
-- Title      : RX OOB inserter
-- Project    : White Rabbit 
-------------------------------------------------------------------------------
-- File       : ep_rx_oob_insert.vhd
-- Author     : Tomasz Wlostowski
-- Company    : CERN BE-CO-HT
-- Platform   : FPGA-generic
-- Standard   : VHDL '93
-------------------------------------------------------------------------------
-- Doc: Insert an OOB beat at then end of the packet
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.endpoint_private_pkg.all;
use work.endpoint_pkg.all;
use work.ep_wbgen2_pkg.all;
use work.wr_fabric_pkg.all;


entity ep_rx_oob_insert is
  port(clk_sys_i : in std_logic;
       rst_n_i   : in std_logic;

       snk_fab_i  : in  t_ep_internal_fabric;
       snk_dreq_o : out std_logic;

       src_fab_o  : out t_ep_internal_fabric;
       src_dreq_i : in  std_logic;

       regs_i : in t_ep_out_registers
       );
end ep_rx_oob_insert;

architecture behavioral of ep_rx_oob_insert is

  type t_state is (WAIT_OOB, OOB);
  signal state : t_state;
begin
  snk_dreq_o                   <= src_dreq_i;
  src_fab_o.sof                <= snk_fab_i.sof;
  src_fab_o.eof                <= snk_fab_i.eof;
  src_fab_o.ERROR              <= snk_fab_i.ERROR;
  src_fab_o.bytesel            <= snk_fab_i.bytesel;
  src_fab_o.has_rx_timestamp   <= snk_fab_i.has_rx_timestamp;
  src_fab_o.rx_timestamp_valid <= snk_fab_i.rx_timestamp_valid;
  
  p_comb_src : process (state, snk_fab_i, regs_i)
  begin
    if(snk_fab_i.has_rx_timestamp = '1')then
      src_fab_o.data   <= c_WRF_OOB_TYPE_RX & (not snk_fab_i.rx_timestamp_valid) & "000000" & regs_i.ecr_portid_o;
      src_fab_o.dvalid <= '1';
      src_fab_o.addr   <= c_WRF_OOB;
    else
      if(state = WAIT_OOB) then
        src_fab_o.addr <= c_WRF_DATA;
      else
        src_fab_o.addr <= c_WRF_OOB;
      end if;
      src_fab_o.data   <= snk_fab_i.data;
      src_fab_o.dvalid <= snk_fab_i.dvalid;
    end if;
  end process;

  p_fsm : process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_n_i = '0' or regs_i.ecr_rx_en_o = '0' then
        state <= WAIT_OOB;
      else

        if(snk_fab_i.error = '1' or snk_fab_i.sof = '1') then
          state <= WAIT_OOB;
        else

          case state is
            when WAIT_OOB =>
              if(snk_fab_i.has_rx_timestamp = '1') then
                state <= OOB;
              end if;

            when OOB =>
              if(snk_fab_i.eof = '1') then
                state <= WAIT_OOB;
              end if;
              
          end case;
        end if;
      end if;
    end if;
  end process;
end behavioral;




