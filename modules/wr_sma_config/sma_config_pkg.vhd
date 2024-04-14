library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.wishbone_pkg.all;
use work.sma_config_wbgen2_pkg.all;


package sma_config_pkg is

  constant c_DATA_W : integer := 8; -- parallel data width going to serdes
  constant c_HALF   : integer := 25;-- default high/low width for 10MHz

  component sma_config_wb is
    port (
      rst_n_i                                  : in     std_logic;
      clk_sys_i                                : in     std_logic;
      wb_adr_i                                 : in     std_logic_vector(3 downto 0);
      wb_dat_i                                 : in     std_logic_vector(31 downto 0);
      wb_dat_o                                 : out    std_logic_vector(31 downto 0);
      wb_cyc_i                                 : in     std_logic;
      wb_sel_i                                 : in     std_logic_vector(3 downto 0);
      wb_stb_i                                 : in     std_logic;
      wb_we_i                                  : in     std_logic;
      wb_ack_o                                 : out    std_logic;
      wb_stall_o                               : out    std_logic;
      regs_i                                   : in     t_sma_config_in_registers;
      regs_o                                   : out    t_sma_config_out_registers
    );
  end component;

  component oserdes_8_to_1 is
  generic(
    sys_w : integer := 1;
    dev_w : integer := 8); 
  port(
    DATA_OUT_FROM_DEVICE : in  std_logic_vector(dev_w-1 downto 0); 
    DATA_OUT_TO_PINS_P   : out std_logic_vector(sys_w-1 downto 0); 
    DATA_OUT_TO_PINS_N   : out std_logic_vector(sys_w-1 downto 0); 
    CLK_IN     : in std_logic;
    CLK_DIV_IN : in std_logic;
    IO_RESET   : in std_logic);
  end component;


  component fine_delay_ctrl is
  generic (
      g_project_name        : string := "NORMAL"
  );
  port (
      rst_sys_n_i       : in  std_logic;
      clk_sys_i         : in  std_logic;
    
      fine_dly_req_i    : in  std_logic;
      fine_dly_sel_i    : in  std_logic;
      fine_dly_values_i : in  std_logic_vector(8 downto 0);
      fine_dly_busy_o   : out std_logic;

      delay_en_o        : out std_logic;
      delay_sload_o     : out std_logic;
      delay_sdin_o      : out std_logic;
      delay_sclk_o      : out std_logic
      );
  end component;

  component utc_coding is
  port(
    clk_ref_i : in std_logic;
    rst_n_i   : in std_logic;
    pps_i     : in std_logic;
    pps_valid_i : in std_logic;
    tm_utc_i    : in std_logic_vector(39 downto 0);
    tm_serial_o : out std_logic
  ); 
  end component;  

end package;

--package body shine_config_pkg is



--end package body;
