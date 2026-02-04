-------------------------------------------------------------------------------
-- SPDX-FileCopyrightText: 2026 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+
-------------------------------------------------------------------------------
--  10G RX filter
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.epx_pkg.all;

entity epx_rx_filter is
  port (
    clk_i : in std_logic;
    rst_n_i : in std_logic;

    --  Local ethernet address.
    my_addr_i : in std_logic_vector(47 downto 0);

    --  Incoming frame
    data_i : out std_logic_vector(63 downto 0);
    valid_i : out std_logic;
    start_i : out std_logic;
    last_i : out std_logic;
    err_i : out std_logic;

    --  Filter result: a pulse which must appear before last_i.
    --  Frame is for the core (ptp, icmp, arp, udp...)
    filter_cpu_o : out std_logic;
    --  Frame is not for the core.
    filter_usr_o : out std_logic
  );
end epx_rx_filter;

architecture arch of epx_rx_filer is
  type t_fsm_state is (S_IDLE, S_MAC0, S_MAC1);
  signal state : t_fsm_state;

  constant c_TY_IP : std_logic_vector(15 downto 0) := x"0800";
  constant c_TY_ARP : std_logic_vector(15 downto 0) := x"0806";
  constant c_TY_TAG : std_logic_vector(15 downto 0) := x"8100";

  constant c_IPVER : std_logic_vector(7 downto 0) := x"45";

  constant c_PROTO_ICMP : std_logic_vector(7 downto 0) := x"01";
  constant c_PROTO_UDP : std_logic_vector(7 downto 0) := x"11";

  constant c_PORT_DHCP_CLT : std_logic_vector(15 downto 0) := x"0044"; -- 68
  constant c_PORT_DHCP_SRV : std_logic_vector(15 downto 0) := x"0043"; -- 67

  --  Destination address
  signal da : std_logic_vector(47 downto 0);
  signal is_da_local, is_da_bcast, is_da_ptp : boolean;

  --  Ethertype
  signal ty, tag_ty : std_logic_vector(15 downto 0);
  signal is_ty_ip, is_ty_arp, is_ty_ptp : boolean;
  signal is_ty_tagged : boolean;

  signal ipver, tagged_ipver : std_logic_vector(7 downto 0);
  signal proto, tagged_proto : std_logic_vector(7 downto 0);

  signal is_proto_udp, is_proto_icmp : boolean;
  signal is_dhcp : boolean;
begin
  --  Beat 1:
  --  SA1 SA0 DA5 DA4 DA3 DA2 DA1 DA0
  da <= data_i( 7 downto  0)
        & data_i(15 downto  8)
        & data_i(23 downto 16)
        & data_i(31 downto 24)
        & data_i(39 downto 32)
        & data_i(47 downto 40);

  --  Beat 2: S_MAC1
  --  TOS IPV TY1 TY0 SA5 SA4 SA3 SA2
  --  PR1 PR0 TY1 TY0 SA5 SA4 SA3 SA2  (priority for tagged frames)
  ty <= data_i(39 downto 32) & data_i(47 downto 40);
  ipver <= data_i(56 downto 48);

  --  Beat 3 (not tagged): S_PROTO
  --  PROTO TTL FRAG0 FRAG1 ID0 ID1 LEN0 LEN1
  proto <= data_i(63 downto 56);

  --  Beat 3 (tagged)
  --  ID0 ID1 LEN0 LEN1 TOS IPV TY1 TY0
  tagged_ty <= data_i(7 downto 0) & data_i(15 downto 8);
  tagged_ipver <= data_i(23 downto 16);

  --  Beat 4 (not tagged): S_IP_ADDR
  --  DA2 DA3 SA0 SA1 SA2 SA3 CHK0 CHK1

  --  Beat 4 (tagged)
  --  SA2 SA3 CHK0 CHK1 PROTO TTL FRAG0 FRAG1
  tagged_proto <= data_i(31 downto 24);

  --  Beat 5 (not tagged): S_UDP IP + UDP
  --  LEN0 LEN1 DP0 DP1 SP0 SP1 DA0 DA1
  udp_dport <= data_i(39 downto 32) & data_i(47 downto 40);
  udp_sport <= data_i(23 downto 16) & data_i(31 downto 24);

  --  Beat 5 (tagged)
  --  SP0 SP1 DA0 DA1 DA2 DA3 SA0 SA1

  --  Beat 6 (tagged)
  --  DATA1 DATA0 CHK0 CHK1 LEN0 LEN1 DP0 DP1
  process(clk_i)
  begin
    if rising_edge(clk_i) then
      filter_cpu_o <= '0';
      filter_usr_o <= '0';

      if rst_n_i = '0' then
        state <= S_IDLE;
      elsif valid_i = '1' then
        if err_i = '1' then
          state <= S_IDLE;
        else
          case state is
            when S_IDLE =>
              if start_i = '1' then
                state <= S_MAC1;
                --  First 8 bytes:
                --  DA[47:0], SA[15:0]
                --  Destination address
                is_da_local <= da = my_addr_i;
                is_da_bcast <= da = x"ff_ff_ff_ff_ff_ff";
                --  PTP UDP: use multicast addresses
                --  224.0.1.129 for end to end
                --  224.0.0.107 for peer to peer (FIXME: add)
                is_da_ptp <= da = x"01_00_5e_00_01_81";
              end if;
            when S_MAC1 =>
              --  Second 8 bytes:
              --  SA[47:16], ETHTYP[15:0]
              if ty = c_TY_TAG then
                is_ty_tagged <= true;
                state <= S_TAG;
              else
                is_ty_tagged <= false;
                state <= S_PROTO;
              end if;
              is_ty_arp <= ty = c_TY_ARP;
              is_ty_ip <= (ty = c_TY_IP) and (ipver = c_IPVER);

            when S_PROTO =>
              is_proto_udp <= is_ty_ip and (proto = c_PROTO_UDP);
              is_proto_icmp <= is_ty_icmp and (proto = c_PROTO_ICMP);
              state <= S_IP_ADDR;

            when S_IP_ADDR =>
              state <= S_UDP;

            when S_UDP =>
              is_dhcp <= is_proto_udp and (udp_dport = c_PROT_DHCP_CLT);
          end case;
        end if;
      end if;
    end if;
  end process;
end arch;
