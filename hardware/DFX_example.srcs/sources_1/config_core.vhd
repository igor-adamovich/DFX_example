-- vim: set syntax=vhdl et sw=4 ts=4:

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.address;
use work.util.all;

entity config_core is
    port (
        ext_clk   : in std_logic;
        axis_rstn : in std_logic;
        --
        clk_o  : out std_logic;
        rstn_o : out std_logic;
        --
        axis_bunch_i : in  axis_bunch32_t;
        axis_ready_o : out std_logic;
        axis_bunch_o : out axis_bunch32_t;
        axis_ready_i : in  std_logic;
        --
        pcie_id_i : in data16_t;
        --
        axis_enable_o : out std_logic);
end entity;

architecture config_core of config_core is
    signal clk, rstn : std_logic;

    signal req : rld32req_t;
    signal res : rld32res_t;
begin
    core : block
        component clk_wiz
            port (
                clk_out : out std_logic;
                resetn  : in  std_logic;
                locked  : out std_logic;
                clk_in  : in  std_logic);
        end component;

        signal clk_locked, arstn : std_logic;
    begin
        clock : clk_wiz
            port map (
                clk_out => clk,
                resetn  => axis_rstn,
                locked  => clk_locked,
                clk_in  => ext_clk);

        arstn <= axis_rstn and clk_locked;

        rstn_sync : entity work.sync_rstn
            port map (
                clk  => clk,
                rstn => arstn,
                --
                rstn_o => rstn);

        clk_o  <= clk;
        rstn_o <= rstn;
    end block;

    axis2rld : entity work.axis2rld
        generic map (
            wait_width => 8)
        port map (
            clk  => clk,
            rstn => rstn,
            --
            axis_bunch_i => axis_bunch_i,
            axis_ready_o => axis_ready_o,
            axis_bunch_o => axis_bunch_o,
            axis_ready_i => axis_ready_i,
            --
            pcie_id_i => pcie_id_i,
            --
            rld_req_o => req,
            rld_res_i => res);

    registers : block
        signal axis_enable : std_logic;
        signal req_reg     : rld32req_t;
        signal res_reg     : rld32res_t;
    begin
        process (clk, rstn)
        begin
            if rstn = '0' then
                axis_enable <= '1';
                req_reg <= nothing;
                res_reg <= nothing;
            elsif rising_edge(clk) then
                req_reg <= req;
                if req_reg.addr = address.registers then
                    res_reg <= (extend32(axis_enable), req_reg.re);
                    if req_reg.we = '1' then
                        axis_enable <= req_reg.data(0);
                    end if;
                else
                    res_reg <= nothing;
                end if;
            end if;
        end process;

        res <= res_reg;
        axis_enable_o <= axis_enable;
    end block;

    icape : entity work.icape
        port map (
            clk   => clk,
            rstn  => rstn,
            --
            req_i => req);
end architecture;
