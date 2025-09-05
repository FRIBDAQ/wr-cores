-------------------------------------------------------------------------------
-- Title      : WhiteRabbit PTP Core
-- Project    : WhiteRabbit
-------------------------------------------------------------------------------
-- File       : wr_max_flash.vhd
-- Company    : CERN (BE-CO-HT)
-------------------------------------------------------------------------------
-- Description:
--
--  Emulate an SPI flash containing a simple sdb fs with
--  only a MAC address
--  Assume read by master on falling edge
--  To be connected on the SPI intreface of WR core
-------------------------------------------------------------------------------
--
-- Copyright (c) 2025 CERN
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
-------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity wr_mac_flash is
  port (
    --  Must be the same clock/reset as the wrpc sys clock.
    clk_i : in std_logic;
    rst_n_i : in std_logic;

    --  Mac address, set when mac_valid_i = '1'.
    --  mac_addr_i(47 downto 40) is the MSB.
    mac_addr_i  : in  std_logic_vector(47 downto 0);
    mac_valid_i : in std_logic;

    --  Slave SPI interface
    --  Note: the inputs are not resynchronized.
    spi_sclk_i : in  std_logic;
    spi_cs_n_i : in  std_logic;
    spi_mosi_i : in  std_logic;
    spi_miso_o : out std_logic);
end wr_mac_flash;

architecture arch of wr_mac_flash is
  subtype t_byte is std_logic_vector(7 downto 0);
  
  type t_mem8 is array(natural range <>) of t_byte;

  constant mem_hdr: t_mem8(0 to 127) :=
    (
      --  Header
      x"53", x"44", x"42", x"2d",  --  magic
      x"00", x"02", x"01", x"01",  --  records(2), version(1), bus_type(1)
      x"00", x"00", x"00", x"00",  --  Start Addr
      x"00", x"00", x"00", x"00",
      
      x"00", x"00", x"00", x"00",  --  Last Addr
      x"00", x"00", x"00", x"85",
      x"46", x"69", x"6c", x"65",  --  Vendor(FileData)
      x"44", x"61", x"74", x"61",
      
      x"2e", x"20", x"20", x"20",  --  Device(.)
      x"00", x"00", x"00", x"01",  --  version(1)
      x"00", x"00", x"00", x"00",  --  date(0)
      x"2e", x"20", x"20", x"20",  --  name(.)
      
      x"20", x"20", x"20", x"20",
      x"20", x"20", x"20", x"20",
      x"20", x"20", x"20", x"20",
      x"20", x"20", x"20", x"00",  --  record_type(0=interconnect)
      

      --  File 1
      x"00", x"00", x"00", x"00",  --  no magic
      x"00", x"00", x"00", x"06",  --  flags
      x"00", x"00", x"00", x"00",  --  Start Addr
      x"00", x"00", x"00", x"80",
      
      x"00", x"00", x"00", x"00",  --  Last Addr
      x"00", x"00", x"00", x"85",
      x"46", x"69", x"6c", x"65",  --  Vendor(FileData)
      x"44", x"61", x"74", x"61", 
             
      x"6d", x"61", x"63", x"2d",  --  Device(mac-)
      x"00", x"00", x"00", x"01",  --  Version(1)
      x"00", x"00", x"00", x"00",  --  date(0)
      x"6d", x"61", x"63", x"2d",  --  Name(mac-address)
      
      x"61", x"64", x"64", x"72",
      x"65", x"73", x"73", x"20",
      x"20", x"20", x"20", x"20",
      x"20", x"20", x"20", x"01"   --  Record-type(1:device)
    );

  signal bcount : natural range 0 to 23;
  type t_state is (S_CMD, S_DECODE, S_ADDR, S_DUMMY, S_READ, S_DAT, S_NONE);
  signal state : t_state;
  signal prev_sclk : std_logic;
  signal cmd : std_logic_vector(7 downto 0);
  signal addr : std_logic_vector(23 downto 0);
  signal spi_miso : std_logic;

  signal mem_mac : t_mem8(0 to 5);
  signal mem : t_byte;

  constant C_RSR : t_byte := x"05";  -- Read status register
  constant C_RID : t_byte := x"9f";  -- Read ID
  constant C_WEN : t_byte := x"06";  -- Write enable
  constant C_ERA : t_byte := x"d8";  -- Erase
  constant C_RD  : t_byte := x"0b";  -- Read
  constant C_WR  : t_byte := x"02";  -- Write

  constant C_RD1 : t_byte := x"81";  -- Fake command: dummy read cycles
  constant C_RD2 : t_byte := x"82";  -- Fake command: read data
begin

  spi_miso_o <= spi_miso;

  process (clk_i)
  begin
    if rising_edge(clk_i) then
      if addr(7) = '0' then
        mem <= mem_hdr(to_integer(unsigned(addr(6 downto 0))));
      else
        mem <= mem_mac(to_integer(unsigned(addr(2 downto 0))));
      end if;
    end if;
  end process;

  process(clk_i)
    variable dat : t_byte;
  begin
    if rising_edge(clk_i) then
      prev_sclk <= spi_sclk_i;

      if rst_n_i = '0' or spi_cs_n_i = '1' then
        bcount <= 0;
        state <= S_CMD;
        prev_sclk <= '0';
        spi_miso <= '0';
      else
        case state is
          when S_CMD =>
            if spi_sclk_i = '1' and prev_sclk = '0' then
              --  Read command
              cmd <= cmd(6 downto 0) & spi_mosi_i;
              if bcount = 7 then
                state <= S_DECODE;
                bcount <= 0;
              else
                bcount <= bcount + 1;
              end if;
            end if;
            spi_miso <= '0';
          when S_DECODE =>
            --  Decode immediately
            case cmd is
              when C_RSR =>
                --  TODO: maybe set program or erase failure bits ?
                state <= S_NONE;
              when C_RID =>
                --  TODO: maybe return a fake ID ?
                state <= S_NONE;
              when C_RD =>
                state <= S_ADDR;
                bcount <= 0;
              when others =>
                state <= S_NONE;
            end case;
          when S_NONE =>
            spi_miso <= '0';
          when S_ADDR =>
            spi_miso <= '0';
            --  Read address.
            if spi_sclk_i = '1' and prev_sclk = '0' then
              addr <= addr(22 downto 0) & spi_mosi_i;
              if bcount = 23 then
                state <= S_DUMMY;
                bcount <= 0;
              else
                bcount <= bcount + 1;
              end if;
            end if;
          when S_DUMMY =>
            --  read: dummy cycles
            if spi_sclk_i = '1' and prev_sclk = '0' then
              if bcount = 7 then
                state <= S_READ;
                bcount <= 0;
              else
                bcount <= bcount + 1;
              end if;
            end if;
          when S_READ =>
            --  read: return the data
            dat := mem;
            addr <= std_logic_vector(unsigned(addr) + 1);
            bcount <= 0;
            state <= S_DAT;
          when S_DAT =>
            --  Send content of dat.
            if spi_sclk_i = '0' and prev_sclk = '1' then
              --  MSB first
              spi_miso <= dat(7);
              dat := dat(6 downto 0) & '0';
              if bcount = 7 then
                --  Read next byte
                state <= S_READ;
              else
                bcount <= bcount + 1;
              end if;
            end if;
          when others =>
            spi_miso <= '0';
        end case;
      end if;
    end if;
  end process;

  process (clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        mem_mac <= (others => x"00");
      elsif mac_valid_i = '1' then
        for i in 0 to 5 loop
          mem_mac(i) <= mac_addr_i(47 - 8*i downto 40 - 8*i);
        end loop;
      end if;
    end if;
  end process;

  gen_ila: if false generate
    component ila_0
      port (
        clk    : in STD_LOGIC;
        probe0 : in STD_LOGIC_VECTOR(63 downto 0)
      );
    end component  ;
    signal s_bcount : std_logic_vector(4 downto 0);
  begin
    s_bcount <= std_logic_vector(to_unsigned(bcount, 5));

    inst_ila: ila_0
      port map (
        clk => clk_i,
        probe0(0) => spi_sclk_i,
        probe0(1) => spi_cs_n_i,
        probe0(2) => spi_mosi_i,
        probe0(3) => spi_miso,
        probe0(4) => '0',
        probe0(7 downto 5) => (others => '0'),
        probe0(15 downto 8) => cmd,
        probe0(39 downto 16) => addr,
        probe0(44 downto 40) => s_bcount,
        probe0(63 downto 45) => (others => '0')
      );
  end generate;
end arch;
