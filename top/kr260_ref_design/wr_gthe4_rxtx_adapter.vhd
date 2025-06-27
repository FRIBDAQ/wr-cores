library ieee;
use ieee.std_logic_1164.all;

use work.gencores_pkg.all;
use work.disparity_gen_pkg.all;

entity wr_gthe4_rxtx_adapter is
  port (
    -- data input (16 bits, not 8b10b-encoded)
    tx_data_i : in std_logic_vector(15 downto 0);

    -- 1 when tx_data_i contains a control code, 0 when it's a data byte
    tx_k_i : in std_logic_vector(1 downto 0);

    -- disparity of the currently transmitted 8b10b code (1 = plus, 0 = minus).
    -- Necessary for the PCS to generate proper frame termination sequences.
    -- Generated for the 2nd byte (LSB) of tx_data_i.
    tx_disparity_o : out std_logic;

    -- Encoding error indication (1 = error, 0 = no error)
    tx_enc_err_o : out std_logic;

    -- RX path, synchronous to ch0_rx_rbclk_o.

    -- RX recovered clock
    -- rx_rbclk_o : out std_logic;

    -- 8b10b-decoded data output. The data output must be kept invalid before
    -- the transceiver is locked on the incoming signal to prevent the EP from
    -- detecting a false carrier.
    rx_data_o : out std_logic_vector(15 downto 0);

    -- 1 when the byte on rx_data_o is a control code
    rx_k_o : out std_logic_vector(1 downto 0);

    -- encoding error indication
    rx_enc_err_o : out std_logic;

    --  When gthe4 is ready and synced.
    --  Asynchronous input.
    serdes_ready_a_i : in std_logic;

    --  When gthe4 alignment is done.
    rx_synced_i : in std_logic;

    gth_rx_data_i : in std_logic_vector(15 downto 0);
    gth_tx_data_o : out std_logic_vector(15 downto 0);
    gth_rx_k_i : in std_logic_vector(1 downto 0);
    gth_tx_k_o : out std_logic_vector(1 downto 0);

    gth_rx_clk_i : in std_logic;
    gth_tx_clk_i : in std_logic
   );
end wr_gthe4_rxtx_adapter;

architecture rtl of wr_gthe4_rxtx_adapter is
  signal serdes_ready_txclk, serdes_ready_rxclk : std_logic;

  signal cur_disp : t_8b10b_disparity;
begin
  gth_tx_k_o <= tx_k_i(0) & tx_k_i(1);
  gth_tx_data_o <= tx_data_i(7 downto 0) & tx_data_i(15 downto 8);

  U_Sync_Serdes_RDY1 : entity work.gc_sync
    port map (
      clk_i      => gth_rx_clk_i,
      rst_n_a_i  => '1',
      d_i        => serdes_ready_a_i,
      q_o        => serdes_ready_rxclk);

  U_Sync_Serdes_RDY2 : entity work.gc_sync
    port map (
      clk_i      => gth_tx_clk_i,
      rst_n_a_i  => '1',
      d_i        => serdes_ready_a_i,
      q_o        => serdes_ready_txclk);
  
  p_gen_rx_outputs : process(gth_rx_clk_i)
  begin
    if rising_edge(gth_rx_clk_i) then
      if serdes_ready_rxclk = '1' and rx_synced_i = '1' then
        rx_data_o    <= gth_rx_data_i(7 downto 0) & gth_rx_data_i(15 downto 8);
        rx_k_o       <= gth_rx_k_i(0) & gth_rx_k_i(1);
        rx_enc_err_o <= '0';  --rx_disp_err(0) or rx_disp_err(1) or rx_code_err(0) or rx_code_err(1);
      else
        rx_data_o    <= (others => '1');
        rx_k_o       <= (others => '1');
        rx_enc_err_o <= '1';
      end if;
    end if;
  end process;

  p_gen_tx_disparity : process(gth_tx_clk_i)
  begin
    if rising_edge(gth_tx_clk_i) then
      if serdes_ready_txclk = '0' then
        cur_disp <= RD_MINUS;
      else
        cur_disp <= f_next_8b10b_disparity16(cur_disp, tx_k_i, tx_data_i);
      end if;
    end if;
  end process;

  tx_disparity_o <= to_std_logic(cur_disp);

  tx_enc_err_o <= '0';
end rtl;


