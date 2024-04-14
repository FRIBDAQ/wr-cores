library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.wishbone_pkg.all;
use work.gencores_pkg.all;
use work.sma_config_wbgen2_pkg.all;
use work.sma_config_pkg.all;

library UNISIM;
use UNISIM.vcomponents.all;

entity xwr_sma_config is
generic (
    g_interface_mode      : t_wishbone_interface_mode      := PIPELINED;
    g_address_granularity : t_wishbone_address_granularity := WORD
);
port (
    rst_n_i      : in std_logic;
    clk_sys_i    : in std_logic;

    clk_serdes_i : in std_logic;

    pps_csync_i     : in std_logic;
    pps_valid_i     : in std_logic;
    tm_tai_i        : in std_logic_vector(39 downto 0);
    
    sync_data_o_p  : out std_logic_vector(1 downto 0);
    sync_data_o_n  : out std_logic_vector(1 downto 0);

    fdly_en_o      : out std_logic;
    fdly_sload_o   : out std_logic;
    fdly_sdin_o    : out std_logic;
    fdly_sclk_o    : out std_logic;

    slave_i   : in  t_wishbone_slave_in := cc_dummy_slave_in;
    slave_o   : out t_wishbone_slave_out
);

attribute maxdelay : string;
attribute maxdelay of pps_csync_i : signal is "1000 ps";

end xwr_sma_config;

architecture behav of xwr_sma_config is

  signal rst_sys_n  : std_logic;

  signal rst_oserdes_pll : std_logic;
  signal pll_500m_locked : std_logic;
  signal clk_500m_fb : std_logic;
  signal clk_500m : std_logic;


  signal rst_oserdes : std_logic;


  signal sd_out0_p   : std_logic_vector(0 downto 0);
  signal sd_out0_n   : std_logic_vector(0 downto 0);

  signal sd_out1_p   : std_logic_vector(0 downto 0);
  signal sd_out1_n   : std_logic_vector(0 downto 0);

  signal customed_sd_data   : std_logic_vector(c_DATA_W-1 downto 0);
  signal pps_sd_data        : std_logic_vector(c_DATA_W-1 downto 0);
  signal utc_coding_sd_data : std_logic_vector(c_DATA_W-1 downto 0);


  signal ch0_sd_data : std_logic_vector(c_DATA_W-1 downto 0);
  signal ch1_sd_data : std_logic_vector(c_DATA_W-1 downto 0);

  signal wb_in  : t_wishbone_slave_in;
  signal wb_out : t_wishbone_slave_out;

  signal ch0_sel : std_logic_vector(7 downto 0);
  signal ch1_sel : std_logic_vector(7 downto 0);

  signal cus_high_len: unsigned(28 downto 0);
  signal cus_low_len : unsigned(28 downto 0);
  signal cus_shift   : unsigned(28 downto 0);
  signal cus_pps_valid_d  : std_logic;
  signal cus_realign  : std_logic;
  signal cus_new_freq : std_logic;

  signal utc_clk_shift    : unsigned(25 downto 0);
  signal utc_phase_shift  : unsigned(2 downto 0);
  signal utc_pps_valid_d  : std_logic;
  signal utc_realign  : std_logic;
  signal utc_new_freq : std_logic;
  signal utc_serial : std_logic;

  signal pps_clk_shift    : unsigned(25 downto 0);
  signal pps_high_len     : unsigned(25 downto 0);
  signal pps_phase_shift  : unsigned(2 downto 0);
  signal pps_valid_d  : std_logic;
  signal pps_realign  : std_logic;
  signal pps_new_freq : std_logic;
  signal pps_serial : std_logic;

  signal wb_regs_in  : t_sma_config_in_registers;
  signal wb_regs_out : t_sma_config_out_registers;

  signal fine_dly_req    : std_logic; 
  signal fine_dly_sel    : std_logic; 
  signal fine_dly_busy   : std_logic; 
  signal fine_dly_values : std_logic_vector(8 downto 0);

  signal sma0_fdly : std_logic_vector(8 downto 0);
  signal sma1_fdly : std_logic_vector(8 downto 0);

  signal fdly_en      : std_logic;
  signal fdly_sload   : std_logic;
  signal fdly_sdin    : std_logic;
  signal fdly_sclk    : std_logic;

  signal tm_utc_int  : std_logic_vector(39 downto 0);

 
  function f_parallel_gen_1 (rest: integer; v_bit: std_logic) return std_logic_vector is
    variable result : std_logic_vector(7 downto 0);
  begin
    for i in 0 to 7 loop
        if(i<rest) then
            result(i) := v_bit;
        else 
            result(i) := not v_bit;
        end if;
    end loop;
    return result;
  end function;

 
  function f_parallel_gen_2 (rest: integer; v_bit: std_logic; index: integer) return std_logic_vector is
    variable result : std_logic_vector(7 downto 0);
  begin
    result := (others => v_bit);
    for i in 0 to 7 loop
        if(i>rest-1 and i< index) then
            result(i) := not v_bit;
        end if;
    end loop;
    return result;
  end function;

  attribute KEEP : string;
  attribute KEEP of cus_low_len  : signal is "TRUE";
  attribute KEEP of cus_high_len : signal is "TRUE";
  

begin

    rst_oserdes_pll <= not rst_sys_n;

    U_Sync_reset_sysclk : gc_sync_ffs
    generic map (
      g_sync_edge => "positive")
    port map (
      clk_i    => clk_sys_i,
      rst_n_i  => '1',
      data_i   => rst_n_i,
      synced_o => rst_sys_n);

    ----------------------------------------------------------------
    --                       Wishbone Aapter                      --
    ----------------------------------------------------------------

    U_Adapter : wb_slave_adapter
    generic map (
        g_master_use_struct  => true,
        g_master_mode        => CLASSIC,
        g_master_granularity => WORD,
        g_slave_use_struct   => true,
        g_slave_mode         => g_interface_mode,
        g_slave_granularity  => g_address_granularity
    )
    port map (
        clk_sys_i => clk_sys_i,
        rst_n_i   => rst_sys_n,
        slave_i   => slave_i,
        slave_o   => slave_o,
        master_i  => wb_out,
        master_o  => wb_in
    );

    U_WB_IF: sma_config_wb
    port map (
        rst_n_i   => rst_sys_n,
        clk_sys_i => clk_sys_i,
        wb_adr_i  => wb_in.adr(3 downto 0),
        wb_dat_i  => wb_in.dat,
        wb_dat_o  => wb_out.dat,
        wb_cyc_i  => wb_in.cyc,
        wb_sel_i  => wb_in.sel,
        wb_stb_i  => wb_in.stb,
        wb_we_i   => wb_in.we,
        wb_ack_o  => wb_out.ack,
        wb_stall_o=> wb_out.stall,
        regs_i    => wb_regs_in,
        regs_o    => wb_regs_out
    );
    wb_out.err <= '0';
    wb_out.rty <= '0';

    ----------------------------------------------------------------
    --                       Fdly Controller                      --
    ----------------------------------------------------------------
    P_FDLY_CTRL: process(clk_sys_i)
    begin
      if rising_edge(clk_sys_i) then
        if(rst_sys_n = '0') then 
          fine_dly_req <= '0';
          fine_dly_sel <= '0';
        else 
          if(wb_regs_out.sma0_fdly_load_o = '1' and fine_dly_busy = '0') then 
            fine_dly_req <= '1';
            fine_dly_sel <= '0';
            fine_dly_values <= wb_regs_out.sma0_fdly_o;
          elsif(wb_regs_out.sma1_fdly_load_o = '1' and fine_dly_busy = '0') then 
            fine_dly_req <= '1';
            fine_dly_sel <= '1';
            fine_dly_values <= wb_regs_out.sma1_fdly_o;
          else 
            fine_dly_req <= '0';
            fine_dly_values <= (others => '0');
          end if;
        end if;
      end if;
    end process;

    P_FDLY_RD: process(clk_sys_i)
    begin
      if rising_edge(clk_sys_i) then
        if(rst_sys_n = '0') then
          sma0_fdly <= (others => '0');
          sma1_fdly <= (others => '0');
        else
          if(fine_dly_req = '1') then
            if(fine_dly_sel = '0') then
              sma0_fdly <= fine_dly_values;
            else
              sma1_fdly <= fine_dly_values;
            end if;
          end if;
        end if;
      end if;
    end process;

    wb_regs_in.sma0_fdly_i <= sma0_fdly;
    wb_regs_in.sma1_fdly_i <= sma1_fdly;

    U_FDLY_CTRL: fine_delay_ctrl
    port map(
      rst_sys_n_i       => rst_sys_n,
      clk_sys_i         => clk_sys_i,

      fine_dly_req_i    => fine_dly_req,
      fine_dly_sel_i    => fine_dly_sel,
      fine_dly_values_i => fine_dly_values,
      fine_dly_busy_o   => fine_dly_busy,

      delay_en_o        => fdly_en,
      delay_sload_o     => fdly_sload,
      delay_sdin_o      => fdly_sdin,
      delay_sclk_o      => fdly_sclk
    );

    fdly_en_o      <= fdly_en;
    fdly_sload_o   <= fdly_sload;
    fdly_sdin_o    <= fdly_sdin;
    fdly_sclk_o    <= fdly_sclk;

    ----------------------------------------------------------------
    --                      Customed Generator                    --
    ----------------------------------------------------------------
    process(clk_sys_i)
    begin
        if rising_edge(clk_sys_i) then
        -- if cus_new_freq or pll lost lock,
        -- force alignment to next PPS
            if(rst_sys_n = '0' or cus_new_freq = '1') then  
                cus_pps_valid_d <= '0';
            elsif(pps_csync_i = '1') then
                cus_pps_valid_d <= pps_valid_i;
            end if;
        end if;
    end process;
    
    cus_realign <= (not cus_pps_valid_d) and pps_valid_i and pps_csync_i;

    process(clk_sys_i)
    begin
        if rising_edge(clk_sys_i) then
            if (rst_sys_n = '0') then
                cus_high_len <= to_unsigned(c_HALF, cus_high_len'length);
                cus_low_len  <= to_unsigned(c_HALF, cus_low_len'length);
                cus_shift    <= to_unsigned(0, cus_shift'length);
                cus_new_freq <= '0';
            elsif wb_regs_out.cus_prh_load_o = '1' then
                cus_high_len <= unsigned(wb_regs_out.cus_prh_o);
                cus_new_freq <= '1';
            elsif wb_regs_out.cus_prl_load_o = '1' then
                cus_low_len  <= unsigned(wb_regs_out.cus_prl_o);
                cus_new_freq <= '1';
            elsif wb_regs_out.cus_csr_load_o = '1' then
                cus_shift    <= unsigned(wb_regs_out.cus_csr_o);
                cus_new_freq <= '1';
            else
                cus_new_freq <= '0';
            end if;
        end if;
    end process;

    wb_regs_in.cus_prh_i <= std_logic_vector(cus_high_len);
    wb_regs_in.cus_prl_i <= std_logic_vector(cus_low_len);
    wb_regs_in.cus_csr_i <= std_logic_vector(cus_shift);
  
    process(clk_sys_i)
        variable rest   : integer range 0 to 536870911;
        variable rest_d : integer range 0 to 536870911;
        variable v_bit  : std_logic;
    begin
        if rising_edge(clk_sys_i) then
            if (rst_sys_n='0' or cus_realign='1') then
                rest := to_integer(cus_shift);
                rest_d := rest + to_integer(cus_high_len);
                customed_sd_data <= (others => '0');
                v_bit := '0';
            else
                if(rest > 7) then
                    customed_sd_data <= (others => v_bit);
                    rest := rest - 8;
                else
                    if(rest_d > 7) then
                        customed_sd_data <= f_parallel_gen_1(rest,v_bit);
                        rest := rest_d-8;
                        v_bit := not v_bit;
                    else 
                        customed_sd_data <= f_parallel_gen_2(rest,v_bit,rest_d);
                        if(v_bit = '1')then
                            rest := rest_d+to_integer(cus_high_len)-8;
                        else
                            rest := rest_d+to_integer(cus_low_len)-8;
                        end if;
                    end if;
                end if;

                if(v_bit = '1')then
                    rest_d := rest + to_integer(cus_low_len);
                else
                    rest_d := rest + to_integer(cus_high_len);
                end if;
                --for i in 0 to c_DATA_W-1 loop
                --    if(rest /= 0) then
                --        customed_sd_data(i) <= v_bit;
                --        rest := rest - 1;
                --    elsif(v_bit = '1') then
                --        customed_sd_data(i) <= '0';
                --        v_bit := '0';          
                --        rest := to_integer(cus_low_len-1); 
                --    elsif(v_bit = '0') then
                --        customed_sd_data(i) <= '1';
                --        v_bit := '1';
                --        rest := to_integer(cus_high_len-1);
                --    end if;
                --end loop;
            end if;
        end if;
    end process;


    ----------------------------------------------------------------
    --                          UTC Coding                        --
    ----------------------------------------------------------------
    process(clk_sys_i)
    begin
        if rising_edge(clk_sys_i) then
        -- if utc_new_freq or pll lost lock,
        -- force alignment to next PPS
            if(rst_sys_n = '0' or utc_new_freq = '1') then  
                utc_pps_valid_d <= '0';
            elsif(pps_csync_i = '1') then
                utc_pps_valid_d <= pps_valid_i;
            end if;
        end if;
    end process;
    
    utc_realign <= (not utc_pps_valid_d) and pps_valid_i and pps_csync_i;

    process(clk_sys_i)
    begin
        if rising_edge(clk_sys_i) then
            if (rst_sys_n = '0') then
                utc_clk_shift     <= to_unsigned(0, utc_clk_shift'length);
                utc_phase_shift   <= to_unsigned(0, utc_phase_shift'length);
                utc_new_freq      <= '0';
            elsif wb_regs_out.utc_csr_load_o = '1' then
                utc_clk_shift   <= unsigned(wb_regs_out.utc_csr_o(28 downto 3));
                utc_phase_shift <= unsigned(wb_regs_out.utc_csr_o(2 downto 0));
                utc_new_freq  <= '1';
            else
                utc_new_freq  <= '0';
            end if;
        end if;
    end process;

    wb_regs_in.utc_csr_i(28 downto 3) <= std_logic_vector(utc_clk_shift);
    wb_regs_in.utc_csr_i(2 downto 0) <= std_logic_vector(utc_phase_shift);

    process(clk_sys_i)
        type utc_state is (wait_pps, idle, wt_utc, tx_utc);
        variable state_u      : utc_state;
        variable clk_rest   : integer range 0 to 62499999;
        variable phase_rest : integer range 0 to 7;
        variable cnt        : integer range 0 to 40;
        variable v_bit      : std_logic;
    begin
        if rising_edge(clk_sys_i) then
            if (rst_sys_n='0' or utc_realign='1') then                
                clk_rest   := to_integer(utc_clk_shift);
                phase_rest := to_integer(utc_phase_shift);        
                cnt        := 0;
                state_u      := wait_pps;
                v_bit      := '0';
                utc_serial  <= '0';
                tm_utc_int <= (others => '0');
                utc_coding_sd_data <= (others => '0');
            else
                case state_u is
                    when wait_pps =>                      
                        utc_serial   <= '0';
                        if (pps_csync_i = '1' and pps_valid_i = '1') then
                            tm_utc_int <= tm_tai_i;
                            if(utc_clk_shift = 0)then
                              clk_rest  := 0;
                              state_u     := wt_utc;
                              utc_serial <= '1';
                            else
                              clk_rest  := to_integer(utc_clk_shift) - 1;
                              state_u     := idle;  
                              utc_serial <= '0';
                            end if;
                            phase_rest := to_integer(utc_phase_shift);                                    
                        end if;

                    when idle =>
                        if (clk_rest /= 0)then
                            clk_rest := clk_rest - 1;
                            utc_serial   <= '0';                            
                        else
                            state_u     := wt_utc;
                            utc_serial <= '1';
                        end if;
                    
                    when wt_utc =>
                        utc_serial   <= '0';
                        cnt         := 40;
                        state_u       := tx_utc;

                    when tx_utc =>
                        utc_serial <= tm_utc_int(tm_utc_int'high);
                        tm_utc_int <= tm_utc_int(tm_utc_int'high-1 downto 0) & '0';
                        if cnt = 0 then
                            state_u := wait_pps;
                        else
                            cnt := cnt -1;
                        end if;
                    when others => state_u := wait_pps;
                end case;

                for i in 0 to c_DATA_W-1 loop
                    if(i < phase_rest) then
                        utc_coding_sd_data(i) <= v_bit;                      
                    else 
                        utc_coding_sd_data(i) <= utc_serial;
                        v_bit := utc_serial;
                    end if;
                end loop;                
            end if;
        end if;
    end process;

    ----------------------------------------------------------------
    --                             PPS                            --
    ----------------------------------------------------------------
    process(clk_sys_i)
    begin
        if rising_edge(clk_sys_i) then
        -- if pps_new_freq or pll lost lock,
        -- force alignment to next PPS
            if(rst_sys_n = '0' or pps_new_freq = '1') then  
                pps_valid_d <= '0';
            elsif(pps_csync_i = '1') then
                pps_valid_d <= pps_valid_i;
            end if;
        end if;
    end process;
    
    pps_realign <= (not pps_valid_d) and pps_valid_i and pps_csync_i;

    process(clk_sys_i)
    begin
        if rising_edge(clk_sys_i) then
            if (rst_sys_n = '0') then
                pps_clk_shift     <= to_unsigned(0, pps_clk_shift'length);
                pps_phase_shift   <= to_unsigned(0, pps_phase_shift'length);
                pps_high_len      <= to_unsigned(8, pps_high_len'length);
                pps_new_freq      <= '0';
            elsif wb_regs_out.pps_csr_load_o = '1' then
                pps_clk_shift   <= unsigned(wb_regs_out.pps_csr_o(28 downto 3));
                pps_phase_shift <= unsigned(wb_regs_out.pps_csr_o(2 downto 0));
                pps_new_freq  <= '1';
            elsif wb_regs_out.pps_prh_load_o = '1' then
                pps_high_len <= unsigned(wb_regs_out.pps_prh_o(25 downto 0));
                pps_new_freq  <= '1';
            else
                pps_new_freq  <= '0';
            end if;
        end if;
    end process;

    wb_regs_in.pps_csr_i(28 downto 3) <= std_logic_vector(pps_clk_shift);
    wb_regs_in.pps_csr_i(2 downto 0) <= std_logic_vector(pps_phase_shift);
    wb_regs_in.pps_prh_i(25 downto 0) <= std_logic_vector(pps_high_len);

    process(clk_sys_i)
        type pps_state is (wait_pps, cdelay, last);
        variable state_p    : pps_state;
        variable clk_rest   : integer range 0 to 62499999;
        variable phase_rest : integer range 0 to 7;
        variable v_bit      : std_logic;
    begin
        if rising_edge(clk_sys_i) then
            if (rst_sys_n='0' or pps_realign='1') then                
                clk_rest   := to_integer(pps_clk_shift);
                phase_rest := to_integer(pps_phase_shift);        
                state_p    := wait_pps;
                v_bit      := '0';
                pps_serial <= '0';
                pps_sd_data <= (others => '0');
            else
                case state_p is
                    when wait_pps =>                      
                        pps_serial   <= '0';
                        if (pps_csync_i = '1') then
                            if(pps_clk_shift = 0)then
                              clk_rest  := to_integer(pps_high_len)-1;
                              state_p     := last;
                              pps_serial <= '1';
                            else
                              clk_rest  := to_integer(pps_clk_shift) - 1;
                              state_p     := cdelay;  
                              pps_serial <= '0';
                            end if;
                            phase_rest := to_integer(pps_phase_shift);                                    
                        end if;

                    when cdelay =>
                        if (clk_rest /= 0)then
                            clk_rest := clk_rest - 1;
                            pps_serial   <= '0';                            
                        else
                            clk_rest  := to_integer(pps_high_len)-1;
                            state_p     := last;
                            pps_serial <= '1';
                        end if;
                    
                    when last =>
                        if (clk_rest /= 0)then
                            clk_rest   := clk_rest - 1;
                            pps_serial <= '1';                            
                        else
                            pps_serial <= '0';
                            state_p     := wait_pps;
                        end if;
                   
                    when others => state_p := wait_pps;
                end case;

                for i in 0 to c_DATA_W-1 loop
                    if(i < phase_rest) then
                        pps_sd_data(i) <= v_bit;                      
                    else 
                        pps_sd_data(i) <= pps_serial;
                        v_bit := pps_serial;
                    end if;
                end loop;                
            end if;
        end if;
    end process;



    ----------------------------------------------------------------
    --                            Serdes                          --
    ----------------------------------------------------------------
    P_LOAD_CFG: process(clk_sys_i)
    begin
        if rising_edge(clk_sys_i) then
            if (rst_sys_n = '0') then
                ch0_sel <= (others => '0');
                ch1_sel <= (others => '0');
            elsif wb_regs_out.sma0_mux_load_o = '1' then
                ch0_sel <= wb_regs_out.sma0_mux_o;
            elsif wb_regs_out.sma1_mux_load_o= '1' then
                ch1_sel <= wb_regs_out.sma1_mux_o;                
            end if;
        end if;
    end process;

    wb_regs_in.sma0_mux_i <= ch0_sel;
    wb_regs_in.sma1_mux_i <= ch1_sel;

    P_CH0_MUX: process(clk_sys_i)
    begin
        if rising_edge(clk_sys_i) then
            if (rst_sys_n = '0') then
                ch0_sd_data <= "00000000";
            else
                case ch0_sel is
                    when "00000000" =>
                      ch0_sd_data <= pps_sd_data;
                    when "00000001" =>
                      ch0_sd_data <= utc_coding_sd_data;
                    when "00000010" => 
                      ch0_sd_data <= customed_sd_data;
                    when others =>
                      ch0_sd_data <= (others => '0');
                end case;
            end if;
        end if;
    end process;

    P_utc_MUX: process(clk_sys_i)
    begin
        if rising_edge(clk_sys_i) then
            if (rst_sys_n = '0') then
                ch1_sd_data <= "00000000";
            else
                case ch1_sel is
                    when "00000000" =>
                      ch1_sd_data <= pps_sd_data;
                    when "00000001" =>
                      ch1_sd_data <= utc_coding_sd_data;
                    when "00000010" => 
                      ch1_sd_data <= customed_sd_data;
                    when others =>
                      ch1_sd_data <= (others => '0');
                end case;
            end if;
        end if;
    end process;

    cmp_oserdes_clk_pll : MMCME2_ADV
        generic map (
            BANDWIDTH            => "OPTIMIZED",
            CLKOUT4_CASCADE      => false,
            COMPENSATION         => "ZHOLD",
            STARTUP_WAIT         => false,
            DIVCLK_DIVIDE        => 1,
            CLKFBOUT_MULT_F      => 8.000,    -- 125 MHz -> 1 GHz
            CLKFBOUT_PHASE       => 0.000,
            CLKFBOUT_USE_FINE_PS => false,
            CLKOUT0_DIVIDE_F     => 2.000,    -- 1GHz/2 -> 500 MHz
            CLKOUT0_PHASE        => 0.000,
            CLKOUT0_DUTY_CYCLE   => 0.500,
            CLKOUT0_USE_FINE_PS  => false,
            CLKOUT1_DIVIDE       => 2,        -- 1GHz/2 -> 500 MHz
            CLKOUT1_PHASE        => 0.000,
            CLKOUT1_DUTY_CYCLE   => 0.500,
            CLKOUT1_USE_FINE_PS  => false,
            CLKIN1_PERIOD        => 8.000,    -- 8ns for 125 MHz
            REF_JITTER1          => 0.010)
        port map (
          -- Output clocks
          CLKFBOUT     => clk_500m_fb,
          CLKOUT0      => clk_500m,
          -- Input clock control
          CLKFBIN      => clk_500m_fb,
          CLKIN1       => clk_serdes_i,
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
          LOCKED       => pll_500m_locked,
          CLKINSTOPPED => open,
          CLKFBSTOPPED => open,
          PWRDWN       => '0',
          RST          => rst_oserdes_pll);


    rst_oserdes <= not pll_500m_locked;

    U_10MHZ_SERDES: oserdes_8_to_1
    generic map(
        dev_w => c_DATA_W)
    port map(
        DATA_OUT_FROM_DEVICE => ch0_sd_data,
        DATA_OUT_TO_PINS_P   => sd_out0_p,
        DATA_OUT_TO_PINS_N   => sd_out0_n,
        CLK_IN               => clk_500m,
        CLK_DIV_IN           => clk_sys_i,
        IO_RESET             => rst_oserdes
    );
    sync_data_o_p(0)  <= sd_out0_p(0);
    sync_data_o_n(0)  <= sd_out0_n(0);

    U_PPS_SERDES: oserdes_8_to_1
    generic map(
        dev_w => c_DATA_W)
    port map(
        DATA_OUT_FROM_DEVICE => ch1_sd_data,
        DATA_OUT_TO_PINS_P   => sd_out1_p,
        DATA_OUT_TO_PINS_N   => sd_out1_n,
        CLK_IN               => clk_500m,
        CLK_DIV_IN           => clk_sys_i,
        IO_RESET             => rst_oserdes
    );

    sync_data_o_p(1)  <= sd_out1_p(0);
    sync_data_o_n(1)  <= sd_out1_n(0);

end behav;
