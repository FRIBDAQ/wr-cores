-- file: oserdes_8_to_1.vhd
-- (c) Copyright 2009 - 2011 Xilinx, Inc. All rights reserved.
-- 
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
-- 
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
-- 
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
-- 
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
------------------------------------------------------------------------------
-- User entered comments
------------------------------------------------------------------------------
-- None
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity oserdes_8_to_1_ultrascale is
  generic
  (-- width of the data for the system
    SYS_W         : integer := 1;
    -- width of the data for the device
    DEV_W         : integer := 8
  );
  port
  (
  -- From the device out to the system
  DATA_OUT_FROM_DEVICE    : in    std_logic_vector(DEV_W-1 downto 0); --parallel data input
  DATA_OUT_TO_PINS        : out   std_logic_vector(SYS_W-1 downto 0); --serial output
  -- Clock and reset signals
  CLK_IN               : in    std_logic; -- Fast clock from PLL/MMCM 
  CLK_DIV_IN           : in    std_logic; -- Slow clock from PLL/MMCM
  IO_RESET             : in    std_logic  -- Reset signal for IO circuit
  );
end oserdes_8_to_1_ultrascale;

architecture xilinx of oserdes_8_to_1_ultrascale is

  -- Before the buffer
  signal data_out_to_pins_int      : std_logic_vector(SYS_W-1 downto 0);
  -- Between the delay and serdes
  signal data_out_to_pins_predelay : std_logic_vector(SYS_W-1 downto 0);
  constant num_serial_bits         : integer := DEV_W/SYS_W;
  signal oserdes_d                : std_logic_vector(DEV_W-1 downto 0);

begin

  -- We have multiple bits- step over every bit, instantiating the required elements
  pins: for pin_count in 0 to SYS_W-1 generate
  begin
  
    DATA_OUT_TO_PINS(pin_count) <= data_out_to_pins_predelay(pin_count);

    -- OSERDESE3: Output SERial/DESerializer
    OSERDESE3_inst : OSERDESE3
    generic map (
       DATA_WIDTH => 8,                 -- Parallel Data Width (4-8)
       INIT => '0',                     -- Initialization value of the OSERDES flip-flops
       IS_CLKDIV_INVERTED => '0',       -- Optional inversion for CLKDIV
       IS_CLK_INVERTED => '0',          -- Optional inversion for CLK
       IS_RST_INVERTED => '0',          -- Optional inversion for RST
       SIM_DEVICE => "ULTRASCALE_PLUS"  -- Set the device version for simulation functionality (ULTRASCALE,
                                        -- ULTRASCALE_PLUS, ULTRASCALE_PLUS_ES1, ULTRASCALE_PLUS_ES2)
    )
    port map (
       OQ     => data_out_to_pins_predelay(pin_count), -- 1-bit output: Serial Output Data
       T_OUT  => open,      -- 1-bit output: 3-state control output to IOB
       CLK    => CLK_IN,    -- 1-bit input: High-speed clock
       CLKDIV => CLK_DIV_IN,-- 1-bit input: Divided Clock
       D      => oserdes_d, -- 8-bit input: Parallel Data Input
       RST    => IO_RESET,  -- 1-bit input: Asynchronous Reset
       T      => '0'        -- 1-bit input: Tristate input from fabric
    );

   -- Concatenate the serdes outputs together. Keep the timesliced
   --   bits together, and placing the earliest bits on the right
   --   ie, if data comes in 0, 1, 2, 3, 4, 5, 6, 7, ...
   --       the output will be 3210, 7654, ...
   -------------------------------------------------------------
    out_slices: for slice_count in 0 to num_serial_bits-1 generate 
      -- This places the first data in time on the right
      --oserdes_d(oserdes_d'length-slice_count-1) <= DATA_OUT_FROM_DEVICE(slice_count);
      -- To place the first data in time on the left, use the
      --   following code, instead
      oserdes_d(slice_count) <= DATA_OUT_FROM_DEVICE(slice_count);

    end generate out_slices;

  end generate pins;

end xilinx;
