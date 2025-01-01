-- vim: set syntax=vhdl et sw=4 ts=4:

library ieee;
use ieee.std_logic_1164.all;
use work.util.all;

entity axis_dummy_wrapper_a is
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
end entity;

architecture axis_dummy_wrapper_a of axis_dummy_wrapper_a is
begin
    axis_dummy : entity work.axis_dummy
         generic map(
            value => x"01234567")
        port map (
            clk  => clk,
            rstn => rstn,
            --
            axis_bunch_i.data  => axis_bunch_data_i,
            axis_bunch_i.keep  => axis_bunch_keep_i,
            axis_bunch_i.last  => axis_bunch_last_i,
            axis_bunch_i.valid => axis_bunch_valid_i,
            axis_ready_o => axis_ready_o,
            --
            axis_bunch_o.data  => axis_bunch_data_o,
            axis_bunch_o.keep  => axis_bunch_keep_o,
            axis_bunch_o.last  => axis_bunch_last_o,
            axis_bunch_o.valid => axis_bunch_valid_o,
            axis_ready_i => axis_ready_i,
            --
            pcie_id_i => pcie_id_i);
end architecture;