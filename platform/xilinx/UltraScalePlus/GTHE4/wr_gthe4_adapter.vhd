library ieee;
use ieee.std_logic_1164.all;

entity wr_gthe4_adapter is
  port (
    -- Dedicated reference 125 MHz clock for the GTX transceiver
    -- clk_gth_i     : in std_logic;
    -- clk_freerun_i : in std_logic;

    -- TX path, synchronous to tx_out_clk_o (62.5 MHz):
    -- tx_out_clk_o : out std_logic;
    tx_locked_o  : out std_logic;

    -- data input (8 bits, not 8b10b-encoded)
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

    -- RX bitslide indication, indicating the delay of the RX path of the
    -- transceiver (in UIs). Must be valid when ch0_rx_data_o is valid.
    rx_bitslide_o : out std_logic_vector(4 downto 0);

    -- reset input, active hi
    rst_i    : in std_logic;

    --  GTH is ready.
    --  Clocked by gth_rx_clk_i
    rdy_o : out std_logic;
    
    --  Interface to gthe4
    gtwiz_userclk_tx_reset_o : out std_logic;
    gtwiz_userclk_tx_active_i : in std_logic;
    gtwiz_userclk_rx_reset_o : out std_logic;
    gtwiz_userclk_rx_active_i : in std_logic;
    gtwiz_buffbypass_tx_reset_o : out std_logic;
    gtwiz_buffbypass_tx_done_i : in std_logic;
    gtwiz_buffbypass_rx_reset_o : out std_logic;
    gtwiz_buffbypass_rx_start_user_o : out std_logic;
    gtwiz_buffbypass_rx_done_i : in std_logic;
    gtwiz_reset_all_o : out std_logic;
    gtwiz_reset_tx_done_i : in std_logic;
    gtwiz_reset_rx_done_i : in std_logic;

    gth_rx_data_i : in std_logic_vector(15 downto 0);
    gth_tx_data_o : out std_logic_vector(15 downto 0);
    gth_rx_slide_o : out std_logic;
    gth_rx_k_i : in std_logic_vector(1 downto 0);
    gth_tx_k_o : out std_logic_vector(1 downto 0);
    gth_rx_dec_err_i : in std_logic_vector(1 downto 0);
    gth_rx_disp_err_i : in std_logic_vector(1 downto 0);
    gth_rx_byte_aligned_i : in std_logic;
    gth_rx_comma_det_i : in std_logic;
    gth_rx_pma_reset_done_i : in std_logic;
    gth_tx_pma_reset_done_i : in std_logic;
    gth_rx_pcs_rst_o : out std_logic;

    gth_rx_clk_i : in std_logic;
    gth_tx_clk_i : in std_logic
   );
end wr_gthe4_adapter;

architecture rtl of wr_gthe4_adapter is
  signal serdes_ready_a, serdes_ready_rxclk : std_logic;
  signal rx_synced, rst_rxclk               : std_logic;

  signal rst_n : std_logic;
  signal gtwiz_buffbypass_tx_reset_pre, gtwiz_buffbypass_rx_reset_pre : std_logic;
begin

  rst_n <= not rst_i;

  --  Reset TX buffbypass on active tx_clk
  gtwiz_buffbypass_tx_reset_pre <= not gtwiz_userclk_tx_active_i;
  
  U_Sync1 : entity work.gc_sync
    port map (
      clk_i    => gth_tx_clk_i,
      rst_n_a_i  => rst_n,
      d_i   => gtwiz_buffbypass_tx_reset_pre,
      q_o => gtwiz_buffbypass_tx_reset_o);

  --  Reset RX buffbypass on active tx_clk
  gtwiz_buffbypass_rx_reset_pre <= not gtwiz_userclk_rx_active_i or not gtwiz_buffbypass_tx_done_i;
  
  U_Sync2 : entity work.gc_sync
    port map (
      clk_i    => gth_rx_clk_i,
      rst_n_a_i => rst_n,
      d_i   => gtwiz_buffbypass_rx_reset_pre,
      q_o => gtwiz_buffbypass_rx_reset_o);

  gtwiz_userclk_tx_reset_o <= not gth_tx_pma_reset_done_i;
  gtwiz_userclk_rx_reset_o <= not gth_rx_pma_reset_done_i;

  U_Sync_Reset : entity work.gc_sync
    port map (
      clk_i     => gth_rx_clk_i,
      rst_n_a_i => '1',
      d_i       => rst_i,
      q_o       => rst_rxclk);

  --  For gthe4, do not use byte_is_aligned to detect link down.
  --  Check for missing comma.
  U_Bitslide : entity work.gtp_bitslide
    generic map (
      g_simulation => 0,
      g_target     => "ultrascale",
      g_use_rx_byte_is_aligned => false)
    port map (
      gtp_rst_i                => rst_i,
      gtp_rx_clk_i             => gth_rx_clk_i,
      gtp_rx_comma_det_i       => gth_rx_comma_det_i,
      gtp_rx_byte_is_aligned_i => gth_rx_byte_aligned_i,
      serdes_ready_i           => serdes_ready_rxclk,
      gtp_rx_slide_o           => gth_rx_slide_o,
      gtp_rx_cdr_rst_o         => gth_rx_pcs_rst_o,
      bitslide_o               => rx_bitslide_o,
      synced_o                 => rx_synced);

  gtwiz_reset_all_o <= rst_i;

  serdes_ready_a <= not rst_i
     and gtwiz_reset_rx_done_i
     and gtwiz_buffbypass_rx_done_i and gtwiz_buffbypass_tx_done_i;

  U_Sync_Serdes_RDY1 : entity work.gc_sync
    port map (
      clk_i      => gth_rx_clk_i,
      rst_n_a_i  => '1',
      d_i        => serdes_ready_a,
      q_o        => serdes_ready_rxclk);

  inst_rxtx_adapter: entity work.wr_gthe4_rxtx_adapter
    port map (
          tx_data_i => tx_data_i,
          tx_k_i => tx_k_i,
          tx_disparity_o => tx_disparity_o,
          tx_enc_err_o => tx_enc_err_o,
          rx_data_o => rx_data_o,
          rx_k_o => rx_k_o,
          rx_enc_err_o => rx_enc_err_o,
          serdes_ready_a_i => serdes_ready_a,
          rx_synced_i => rx_synced,
          gth_rx_data_i => gth_rx_data_i,
          gth_tx_data_o => gth_tx_data_o,
          gth_rx_k_i => gth_rx_k_i,
          gth_tx_k_o => gth_tx_k_o,
          gth_rx_dec_err_i => gth_rx_dec_err_i,
          gth_rx_disp_err_i => gth_rx_disp_err_i,
          gth_rx_clk_i => gth_rx_clk_i,
          gth_tx_clk_i => gth_tx_clk_i
        );

  rdy_o        <= serdes_ready_rxclk and rx_synced;
  tx_locked_o  <= '1';
end rtl;


