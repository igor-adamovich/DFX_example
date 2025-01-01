-- vim: set syntax=vhdl et sw=4 ts=4:

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.util.all;

entity axis_dummy is
    generic (
        value : data32_t := x"01234567");
    port (
        clk, rstn : in std_logic;
        --
        axis_bunch_i : in  axis_bunch64_t;
        axis_ready_o : out std_logic;
        axis_bunch_o : out axis_bunch64_t;
        axis_ready_i : in  std_logic;
        --
        pcie_id_i : in data16_t);
end entity;

architecture axis_dummy of axis_dummy is
    type State is (Idle, Recv, Send1, Send2, Send3);

    type FullState is record
        st   : State;
        send : std_logic;
        len  : std_logic_vector(9 downto 0);
        h4dw : std_logic;
        hdr  : data32_t;
    end record;

    type Result is record
        st           : FullState;
        axis_ready_o : std_logic;
        axis_bunch_o : axis_bunch64_t;
    end record;

    signal st : FullState;
    signal res : Result;

    function nextState (st : FullState; pcie_id_i : data16_t; axis_bunch_i : axis_bunch64_t; axis_ready_i : std_logic) return Result is
        variable res : Result := (st, '0', nothing);
    begin
        if st.st = Idle then
            res.axis_ready_o := '1';
            if axis_bunch_i.valid = '1' then
                res.st.st := Recv;
                res.st.len  := axis_bunch_i.data(9 downto 0);
                res.st.h4dw := axis_bunch_i.data(29);
                res.st.hdr(31 downto 8) := axis_bunch_i.data(63 downto 40);
                if axis_bunch_i.data(31 downto 30) = 0 and axis_bunch_i.data(28 downto 24) = 0 and axis_bunch_i.data(9 downto 0) /= 0 then
                    res.st.send := '1';
                else
                    res.st.send := '0';
                end if;
            end if;
        elsif st.st = Recv then
            res.axis_ready_o := '1';
            if axis_bunch_i.valid = '1' then
                if st.h4dw = '1' then
                    res.st.hdr(7 downto 0) := "0" & axis_bunch_i.data(38 downto 32);
                else
                    res.st.hdr(7 downto 0) := "0" & axis_bunch_i.data(6 downto 0);
                end if;
                if axis_bunch_i.last = '1' then
                    if st.send = '1' then
                        res.st.st := Send1;
                    else
                        res.st.st := Idle;
                    end if;
                end if;
            end if;
        elsif st.st = Send1 then
            if axis_ready_i = '1' then
                res.st.st := Send2;
            end if;
            res.axis_bunch_o := (pcie_id_i & "000" & "0" & st.len & "00"   &   "010" & "01010" & "0" & "000" & "0" & "0" & "0" & "0" & "0" & "0" & "00" & "00" & st.len, "11111111", '0', '1');
        elsif st.st = Send2 then
            if axis_ready_i = '1' then
                if st.len = 1 then
                    res.st.st := Idle;
                else
                    res.st.st  := Send3;
                    res.st.len := st.len-1;
                end if;
            end if;
            res.axis_bunch_o := (value   &   st.hdr, "11111111", to_stdl(st.len = 1), '1');
        elsif st.st = Send3 then
            if axis_ready_i = '1' then
                if st.len <= 2 then
                    res.st.st := Idle;
                else
                    res.st.len := st.len-2;
                end if;
            end if;
            res.axis_bunch_o := (value   &   value, ("1111" and to_stdl(st.len /= 1)) & "1111", to_stdl(st.len <= 2), '1');
        end if;
        return res;
    end function;
begin
    process (clk, rstn)
    begin
        if rstn = '0' then
            st <= (Idle, uninitl, uninit(10), uninitl, uninit32);
        elsif rising_edge(clk) then
            st <= res.st;
        end if;
    end process;

    res <= nextState(st, pcie_id_i, axis_bunch_i, axis_ready_i);

    axis_ready_o <= res.axis_ready_o;
    axis_bunch_o <= res.axis_bunch_o;
end architecture;
