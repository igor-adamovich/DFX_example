-- vim: set syntax=vhdl et sw=4 ts=4:

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.vcomponents.all;
use work.address;
use work.util.all;

entity top is
    port (
        pcie_clk_p : in  std_logic;
        pcie_clk_n : in  std_logic;
        pcie_rstn  : in  std_logic;
        pcie_txp   : out std_logic_vector(3 downto 0);
        pcie_txn   : out std_logic_vector(3 downto 0);
        pcie_rxp   : in  std_logic_vector(3 downto 0);
        pcie_rxn   : in  std_logic_vector(3 downto 0);
        --
        ext_clk : in std_logic);
end entity;

architecture top of top is
    component axis_dummy_wrapper_a is
        port (
            clk, rstn : in std_logic;
            --
            axis_bunch_data_i  : in  data64_t;
            axis_bunch_keep_i  : in  data8_t;
            axis_bunch_last_i  : in  std_logic;
            axis_bunch_valid_i : in  std_logic;
            axis_ready_o       : out std_logic;
            --
            axis_bunch_data_o  : out data64_t;
            axis_bunch_keep_o  : out data8_t;
            axis_bunch_last_o  : out std_logic;
            axis_bunch_valid_o : out std_logic;
            axis_ready_i       : in  std_logic;
            --
            pcie_id_i : in data16_t);
    end component;

    component pcie_x4
        port (
            sys_clk   : in std_logic;
            sys_rst_n : in std_logic;
            --
            pci_exp_txp : out std_logic_vector(3 downto 0);
            pci_exp_txn : out std_logic_vector(3 downto 0);
            pci_exp_rxp : in  std_logic_vector(3 downto 0);
            pci_exp_rxn : in  std_logic_vector(3 downto 0);
            --
            user_clk_out   : out std_logic;
            user_reset_out : out std_logic;
            user_lnk_up    : out std_logic;
            user_app_rdy   : out std_logic;
            --
            s_axis_tx_tdata  : in  std_logic_vector(63 downto 0);
            s_axis_tx_tkeep  : in  std_logic_vector(7 downto 0);
            s_axis_tx_tlast  : in  std_logic;
            s_axis_tx_tuser  : in  std_logic_vector(3 downto 0);
            s_axis_tx_tvalid : in  std_logic;
            s_axis_tx_tready : out std_logic;
            m_axis_rx_tdata  : out std_logic_vector(63 downto 0);
            m_axis_rx_tkeep  : out std_logic_vector(7 downto 0);
            m_axis_rx_tlast  : out std_logic;
            m_axis_rx_tuser  : out std_logic_vector(21 downto 0);
            m_axis_rx_tvalid : out std_logic;
            m_axis_rx_tready : in  std_logic;
            --
            tx_buf_av                                  : out std_logic_vector(5 downto 0);
            tx_cfg_req                                 : out std_logic;
            tx_err_drop                                : out std_logic;
            cfg_status                                 : out std_logic_vector(15 downto 0);
            cfg_command                                : out std_logic_vector(15 downto 0);
            cfg_dstatus                                : out std_logic_vector(15 downto 0);
            cfg_dcommand                               : out std_logic_vector(15 downto 0);
            cfg_lstatus                                : out std_logic_vector(15 downto 0);
            cfg_lcommand                               : out std_logic_vector(15 downto 0);
            cfg_dcommand2                              : out std_logic_vector(15 downto 0);
            cfg_pcie_link_state                        : out std_logic_vector(2 downto 0);
            cfg_pmcsr_pme_en                           : out std_logic;
            cfg_pmcsr_powerstate                       : out std_logic_vector(1 downto 0);
            cfg_pmcsr_pme_status                       : out std_logic;
            cfg_received_func_lvl_rst                  : out std_logic;
            cfg_interrupt                              : in  std_logic;
            cfg_interrupt_rdy                          : out std_logic;
            cfg_interrupt_assert                       : in  std_logic;
            cfg_interrupt_di                           : in  std_logic_vector(7 downto 0);
            cfg_interrupt_do                           : out std_logic_vector(7 downto 0);
            cfg_interrupt_mmenable                     : out std_logic_vector(2 downto 0);
            cfg_interrupt_msienable                    : out std_logic;
            cfg_interrupt_msixenable                   : out std_logic;
            cfg_interrupt_msixfm                       : out std_logic;
            cfg_interrupt_stat                         : in  std_logic;
            cfg_pciecap_interrupt_msgnum               : in  std_logic_vector(4 downto 0);
            cfg_to_turnoff                             : out std_logic;
            cfg_bus_number                             : out std_logic_vector(7 downto 0);
            cfg_device_number                          : out std_logic_vector(4 downto 0);
            cfg_function_number                        : out std_logic_vector(2 downto 0);
            cfg_bridge_serr_en                         : out std_logic;
            cfg_slot_control_electromech_il_ctl_pulse  : out std_logic;
            cfg_root_control_syserr_corr_err_en        : out std_logic;
            cfg_root_control_syserr_non_fatal_err_en   : out std_logic;
            cfg_root_control_syserr_fatal_err_en       : out std_logic;
            cfg_root_control_pme_int_en                : out std_logic;
            cfg_aer_rooterr_corr_err_reporting_en      : out std_logic;
            cfg_aer_rooterr_non_fatal_err_reporting_en : out std_logic;
            cfg_aer_rooterr_fatal_err_reporting_en     : out std_logic;
            cfg_aer_rooterr_corr_err_received          : out std_logic;
            cfg_aer_rooterr_non_fatal_err_received     : out std_logic;
            cfg_aer_rooterr_fatal_err_received         : out std_logic;
            cfg_vc_tcvc_map                            : out std_logic_vector(6 downto 0));
    end component;

    component axis_interconnect_1x2
        port (
            aclk    : in std_logic;
            aresetn : in std_logic;
            --
            s00_axis_aclk    : in  std_logic;
            s00_axis_aresetn : in  std_logic;
            s00_axis_tdest   : in  std_logic_vector(0 downto 0);
            s00_axis_tdata   : in  std_logic_vector(63 downto 0);
            s00_axis_tkeep   : in  std_logic_vector(7 downto 0);
            s00_axis_tlast   : in  std_logic;
            s00_axis_tvalid  : in  std_logic;
            s00_axis_tready  : out std_logic;
            s00_decode_err   : out std_logic;
            --
            m00_axis_aclk    : in  std_logic;
            m00_axis_aresetn : in  std_logic;
            m00_axis_tdest   : out std_logic_vector(0 downto 0);
            m00_axis_tdata   : out std_logic_vector(31 downto 0);
            m00_axis_tkeep   : out std_logic_vector(3 downto 0);
            m00_axis_tlast   : out std_logic;
            m00_axis_tvalid  : out std_logic;
            m00_axis_tready  : in  std_logic;
            --
            m01_axis_aclk    : in  std_logic;
            m01_axis_aresetn : in  std_logic;
            m01_axis_tdest   : out std_logic_vector(0 downto 0);
            m01_axis_tdata   : out std_logic_vector(63 downto 0);
            m01_axis_tkeep   : out std_logic_vector(7 downto 0);
            m01_axis_tlast   : out std_logic;
            m01_axis_tvalid  : out std_logic;
            m01_axis_tready  : in  std_logic);
    end component;

    component axis_interconnect_2x1
        port (
            aclk    : in std_logic;
            aresetn : in std_logic;
            --
            m00_axis_aclk        : in  std_logic;
            m00_axis_aresetn     : in  std_logic;
            m00_axis_tdata       : out std_logic_vector(63 downto 0);
            m00_axis_tkeep       : out std_logic_vector(7 downto 0);
            m00_axis_tlast       : out std_logic;
            m00_axis_tvalid      : out std_logic;
            m00_axis_tready      : in  std_logic;
            --
            s00_axis_aclk        : in  std_logic;
            s00_axis_aresetn     : in  std_logic;
            s00_axis_tdata       : in  std_logic_vector(31 downto 0);
            s00_axis_tkeep       : in  std_logic_vector(3 downto 0);
            s00_axis_tlast       : in  std_logic;
            s00_axis_tvalid      : in  std_logic;
            s00_axis_tready      : out std_logic;
            s00_arb_req_suppress : in  std_logic;
            --
            s01_axis_aclk        : in  std_logic;
            s01_axis_aresetn     : in  std_logic;
            s01_axis_tdata       : in  std_logic_vector(63 downto 0);
            s01_axis_tkeep       : in  std_logic_vector(7 downto 0);
            s01_axis_tlast       : in  std_logic;
            s01_axis_tvalid      : in  std_logic;
            s01_axis_tready      : out std_logic;
            s01_arb_req_suppress : in  std_logic);
    end component;

    signal axis_clk, axis_rstn : std_logic;
    signal axis_pcie_rx_bunch, axis_pcie_tx_bunch : axis_bunch64_t;
    signal axis_pcie_rx_ready, axis_pcie_tx_ready : std_logic;
    signal axis_pcie_rx_dest : std_logic_vector(0 downto 0);
    signal pcie_id : data16_t;

    signal clk, rstn : std_logic;

    signal axis_bar0_rx_bunch, axis_bar0_tx_bunch : axis_bunch32_t;
    signal axis_bar0_rx_ready, axis_bar0_tx_ready : std_logic;
    signal axis_bar2_rx_bunch, axis_bar2_tx_bunch : axis_bunch64_t;
    signal axis_bar2_rx_ready, axis_bar2_tx_ready : std_logic;
    signal axis_bar2_enable : std_logic;
begin
    pcie : block
        signal pcie_sys_clk, pcie_sys_rstn, axis_rst, pcie_lnk_up : std_logic;
        signal axis_pcie_rx_user : std_logic_vector(21 downto 0);
    begin
        pcie_clk_buf : IBUFDS_GTE2
            port map (
                O     => pcie_sys_clk,
                ODIV2 => open,
                CEB   => '0',
                I     => pcie_clk_p,
                IB    => pcie_clk_n);

        pcie_rstn_buf : IBUF
            port map (
                O => pcie_sys_rstn,
                I => pcie_rstn);

        pcie : pcie_x4
            port map (
                sys_clk   => pcie_sys_clk,
                sys_rst_n => pcie_sys_rstn,
                --
                pci_exp_txp => pcie_txp,
                pci_exp_txn => pcie_txn,
                pci_exp_rxp => pcie_rxp,
                pci_exp_rxn => pcie_rxn,
                --
                user_clk_out   => axis_clk,
                user_reset_out => axis_rst,
                user_lnk_up    => pcie_lnk_up,
                user_app_rdy   => open,
                --
                s_axis_tx_tdata  => axis_pcie_tx_bunch.data,
                s_axis_tx_tkeep  => axis_pcie_tx_bunch.keep,
                s_axis_tx_tlast  => axis_pcie_tx_bunch.last,
                s_axis_tx_tuser  => (others => '0'),
                s_axis_tx_tvalid => axis_pcie_tx_bunch.valid,
                s_axis_tx_tready => axis_pcie_tx_ready,
                m_axis_rx_tdata  => axis_pcie_rx_bunch.data,
                m_axis_rx_tkeep  => axis_pcie_rx_bunch.keep,
                m_axis_rx_tlast  => axis_pcie_rx_bunch.last,
                m_axis_rx_tuser  => axis_pcie_rx_user,
                m_axis_rx_tvalid => axis_pcie_rx_bunch.valid,
                m_axis_rx_tready => axis_pcie_rx_ready,
                --
                tx_buf_av                                  => open,
                tx_cfg_req                                 => open,
                tx_err_drop                                => open,
                cfg_status                                 => open,
                cfg_command                                => open,
                cfg_dstatus                                => open,
                cfg_dcommand                               => open,
                cfg_lstatus                                => open,
                cfg_lcommand                               => open,
                cfg_dcommand2                              => open,
                cfg_pcie_link_state                        => open,
                cfg_pmcsr_pme_en                           => open,
                cfg_pmcsr_powerstate                       => open,
                cfg_pmcsr_pme_status                       => open,
                cfg_received_func_lvl_rst                  => open,
                cfg_interrupt                              => '0',
                cfg_interrupt_rdy                          => open,
                cfg_interrupt_assert                       => '0',
                cfg_interrupt_di                           => (others => '0'),
                cfg_interrupt_do                           => open,
                cfg_interrupt_mmenable                     => open,
                cfg_interrupt_msienable                    => open,
                cfg_interrupt_msixenable                   => open,
                cfg_interrupt_msixfm                       => open,
                cfg_interrupt_stat                         => '0',
                cfg_pciecap_interrupt_msgnum               => (others => '0'),
                cfg_to_turnoff                             => open,
                cfg_bus_number                             => pcie_id(15 downto 8),
                cfg_device_number                          => pcie_id(7 downto 3),
                cfg_function_number                        => pcie_id(2 downto 0),
                cfg_bridge_serr_en                         => open,
                cfg_slot_control_electromech_il_ctl_pulse  => open,
                cfg_root_control_syserr_corr_err_en        => open,
                cfg_root_control_syserr_non_fatal_err_en   => open,
                cfg_root_control_syserr_fatal_err_en       => open,
                cfg_root_control_pme_int_en                => open,
                cfg_aer_rooterr_corr_err_reporting_en      => open,
                cfg_aer_rooterr_non_fatal_err_reporting_en => open,
                cfg_aer_rooterr_fatal_err_reporting_en     => open,
                cfg_aer_rooterr_corr_err_received          => open,
                cfg_aer_rooterr_non_fatal_err_received     => open,
                cfg_aer_rooterr_fatal_err_received         => open,
                cfg_vc_tcvc_map                            => open);

        axis_rstn <= not axis_rst;
        axis_pcie_rx_dest <= axis_pcie_rx_user(4 downto 4);
    end block;

    interconnect_1x2 : axis_interconnect_1x2
        port map (
            aclk    => axis_clk,
            aresetn => axis_rstn,
            --
            s00_axis_aclk    => axis_clk,
            s00_axis_aresetn => axis_rstn,
            s00_axis_tdest   => axis_pcie_rx_dest,
            s00_axis_tdata   => axis_pcie_rx_bunch.data,
            s00_axis_tkeep   => axis_pcie_rx_bunch.keep,
            s00_axis_tlast   => axis_pcie_rx_bunch.last,
            s00_axis_tvalid  => axis_pcie_rx_bunch.valid,
            s00_axis_tready  => axis_pcie_rx_ready,
            s00_decode_err   => open,
            --
            m00_axis_aclk    => clk,
            m00_axis_aresetn => rstn,
            m00_axis_tdest   => open,
            m00_axis_tdata   => axis_bar0_rx_bunch.data,
            m00_axis_tkeep   => axis_bar0_rx_bunch.keep,
            m00_axis_tlast   => axis_bar0_rx_bunch.last,
            m00_axis_tvalid  => axis_bar0_rx_bunch.valid,
            m00_axis_tready  => axis_bar0_rx_ready,
            --
            m01_axis_aclk    => axis_clk,
            m01_axis_aresetn => axis_rstn,
            m01_axis_tdest   => open,
            m01_axis_tdata   => axis_bar2_rx_bunch.data,
            m01_axis_tkeep   => axis_bar2_rx_bunch.keep,
            m01_axis_tlast   => axis_bar2_rx_bunch.last,
            m01_axis_tvalid  => axis_bar2_rx_bunch.valid,
            m01_axis_tready  => axis_bar2_rx_ready);

    interconnect_2x1 : axis_interconnect_2x1
        port map (
            aclk    => axis_clk,
            aresetn => axis_rstn,
            --
            m00_axis_aclk    => axis_clk,
            m00_axis_aresetn => axis_rstn,
            m00_axis_tdata   => axis_pcie_tx_bunch.data,
            m00_axis_tkeep   => axis_pcie_tx_bunch.keep,
            m00_axis_tlast   => axis_pcie_tx_bunch.last,
            m00_axis_tvalid  => axis_pcie_tx_bunch.valid,
            m00_axis_tready  => axis_pcie_tx_ready,
            --
            s00_axis_aclk        => clk,
            s00_axis_aresetn     => rstn,
            s00_axis_tdata       => axis_bar0_tx_bunch.data,
            s00_axis_tkeep       => axis_bar0_tx_bunch.keep,
            s00_axis_tlast       => axis_bar0_tx_bunch.last,
            s00_axis_tvalid      => axis_bar0_tx_bunch.valid,
            s00_axis_tready      => axis_bar0_tx_ready,
            s00_arb_req_suppress => '0',
            --
            s01_axis_aclk        => axis_clk,
            s01_axis_aresetn     => axis_rstn,
            s01_axis_tdata       => axis_bar2_tx_bunch.data,
            s01_axis_tkeep       => axis_bar2_tx_bunch.keep,
            s01_axis_tlast       => axis_bar2_tx_bunch.last,
            s01_axis_tvalid      => axis_bar2_tx_bunch.valid,
            s01_axis_tready      => axis_bar2_tx_ready,
            s01_arb_req_suppress => '0');

    config_core : entity work.config_core
        port map (
            ext_clk   => ext_clk,
            axis_rstn => axis_rstn,
            --
            clk_o  => clk,
            rstn_o => rstn,
            --
            axis_bunch_i => axis_bar0_rx_bunch,
            axis_ready_o => axis_bar0_rx_ready,
            axis_bunch_o => axis_bar0_tx_bunch,
            axis_ready_i => axis_bar0_tx_ready,
            --
            pcie_id_i => pcie_id,
            --
            axis_enable_o => axis_bar2_enable);

    dummy : block
        signal axis_dummy_pre_rstn, axis_dummy_rstn : std_logic;
        signal axis_dummy_rx_bunch, axis_dummy_tx_bunch : axis_bunch64_t;
        signal axis_dummy_rx_ready, axis_dummy_tx_ready : std_logic;
    begin
        axis_dummy_pre_rstn <= axis_rstn and axis_bar2_enable;

        axis_rstn_sync : entity work.sync_rstn
            port map (
                clk  => axis_clk,
                rstn => axis_dummy_pre_rstn,
                --
                rstn_o => axis_dummy_rstn);

        axis_dummy_rx_bunch <= axis_bar2_rx_bunch and axis_dummy_rstn;
        axis_bar2_rx_ready  <= axis_dummy_rx_ready and axis_dummy_rstn;
        axis_bar2_tx_bunch  <= axis_dummy_tx_bunch and axis_dummy_rstn;
        axis_dummy_tx_ready <= axis_bar2_tx_ready and axis_dummy_rstn;

        axis_dummy : axis_dummy_wrapper_a
            port map (
                clk  => axis_clk,
                rstn => axis_dummy_rstn,
                --
                axis_bunch_data_i  => axis_dummy_rx_bunch.data,
                axis_bunch_keep_i  => axis_dummy_rx_bunch.keep,
                axis_bunch_last_i  => axis_dummy_rx_bunch.last,
                axis_bunch_valid_i => axis_dummy_rx_bunch.valid,
                axis_ready_o       => axis_dummy_rx_ready,
                --
                axis_bunch_data_o  => axis_dummy_tx_bunch.data,
                axis_bunch_keep_o  => axis_dummy_tx_bunch.keep,
                axis_bunch_last_o  => axis_dummy_tx_bunch.last,
                axis_bunch_valid_o => axis_dummy_tx_bunch.valid,
                axis_ready_i       => axis_dummy_tx_ready,
                --
                pcie_id_i => pcie_id);
        end block;
end architecture;
