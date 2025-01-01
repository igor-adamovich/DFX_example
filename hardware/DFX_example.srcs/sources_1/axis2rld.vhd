-- vim: set syntax=vhdl et sw=4 ts=4:

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.util.all;

entity axis2rld is
    generic (
        wait_width : natural);
    port (
        clk, rstn : in std_logic;
        --
        axis_bunch_i : in  axis_bunch32_t;
        axis_ready_o : out std_logic;
        axis_bunch_o : out axis_bunch32_t;
        axis_ready_i : in  std_logic;
        --
        pcie_id_i : in data16_t;
        --
        rld_req_o : out rld32req_t;
        rld_res_i : in  rld32res_t);
end entity;

architecture axis2rld of axis2rld is
    type State is (Idle, Write2, Write3, Write4, Read2, Read3, ReadSend1, ReadSend2, ReadSend3, ReadSend4, Skip);

    type FullState is record
        st     : State;
        h4dw   : std_logic;
        len    : std_logic_vector(9 downto 0);
        left   : std_logic_vector(9 downto 0);
        header : data32_t;
        timer  : std_logic_vector(wait_width-1 downto 0);
        req    : rld32req_t;
        res    : rld32res_t;
    end record;

    type Result is record
        st           : FullState;
        axis_ready_o : std_logic;
        axis_bunch_o : axis_bunch32_t;
    end record;

    signal st : FullState;
    signal res : Result;

    function nextState (st : FullState; pcie_id_i : data16_t; axis_bunch_i : axis_bunch32_t; axis_ready_i : std_logic; rld_res_i : rld32res_t) return Result is
        variable res : Result := (st, '0', nothing);
    begin
        res.st.req.re := '0';
        res.st.req.we := '0';
        if st.res.valid = '0' then
            if st.timer /= 1 then
                res.st.res := rld_res_i;
            else
                res.st.res := (x"FFFFFFFF", '1');
            end if;
        end if;
        if st.timer /= 0 then
            if st.res.valid = '1' then
                res.st.timer := zero(wait_width);
            else
                res.st.timer := st.timer-1;
            end if;
        end if;
        if st.st = Idle then
            res.axis_ready_o := '1';
            if axis_bunch_i.valid = '1' then
                res.st.h4dw := axis_bunch_i.data(29);
                res.st.len  := axis_bunch_i.data(9 downto 0);
                res.st.left := axis_bunch_i.data(9 downto 0);
                if axis_bunch_i.data(31) = '0' and axis_bunch_i.data(28 downto 24) = 0 then
                    if axis_bunch_i.data(30) = '1' then
                        res.st.st := Write2;
                    else
                        res.st.st := Read2;
                    end if;
                else
                    res.st.st := Skip;
                end if;
            end if;
        elsif st.st = Write2 then
            res.axis_ready_o := '1';
            if axis_bunch_i.valid = '1' then
                res.st.st := Write3;
            end if;
        elsif st.st = Write3 then
            res.axis_ready_o := '1';
            if axis_bunch_i.valid = '1' then
                if st.h4dw = '1' then
                    res.st.h4dw := '0';
                else
                    res.st.st := Write4;
                    res.st.req.addr := axis_bunch_i.data(raddr_width+1 downto 2);
                end if;
            end if;
        elsif st.st = Write4 then
            res.axis_ready_o := '1';
            if axis_bunch_i.valid = '1' then
                if axis_bunch_i.last = '1' then
                    res.st.st := Idle;
                end if;
                res.st.req.data := reverse(8, axis_bunch_i.data);
                res.st.req.we   := '1';
            end if;
            if st.req.we = '1' then
                res.st.req.addr := st.req.addr+1;
            end if;
        elsif st.st = Read2 then
            res.axis_ready_o := '1';
            if axis_bunch_i.valid = '1' then
                res.st.st := Read3;
                res.st.header(31 downto 8) := axis_bunch_i.data(31 downto 8);
            end if;
        elsif st.st = Read3 then
            res.axis_ready_o := '1';
            if axis_bunch_i.valid = '1' then
                if st.h4dw = '1' then
                    res.st.h4dw := '0';
                else
                    res.st.st    := ReadSend1;
                    res.st.left  := st.left-1;
                    res.st.timer := (others => '1');
                    res.st.header(7 downto 0) := "0" & axis_bunch_i.data(6 downto 0);
                    res.st.req.addr := axis_bunch_i.data(raddr_width+1 downto 2);
                    res.st.req.re   := '1';
                end if;
            end if;
        elsif st.st = ReadSend1 then
            if axis_ready_i = '1' then
                res.st.st := ReadSend2;
            end if;
            res.axis_bunch_o := ("010" & "01010" & "0" & "000" & "0" & "0" & "0" & "0" & "0" & "0" & "00" & "00" & st.len, "1111", '0', '1');
        elsif st.st = ReadSend2 then
            if axis_ready_i = '1' then
                res.st.st := ReadSend3;
            end if;
            res.axis_bunch_o := (pcie_id_i & "000" & "0" & st.len & "00", "1111", '0', '1');
        elsif st.st = ReadSend3 then
            if axis_ready_i = '1' then
                res.st.st := ReadSend4;
            end if;
            res.axis_bunch_o := (st.header, "1111", '0', '1');
        elsif st.st = ReadSend4 then
            if st.res.valid = '1' and axis_ready_i = '1' then
                if st.left = 0 then
                    res.st.st := Idle;
                else
                    res.st.left  := st.left-1;
                    res.st.timer := (others => '1');
                    res.st.req.addr := st.req.addr+1;
                    res.st.req.re   := '1';
                end if;
                res.st.res.valid := '0';
            end if;
            res.axis_bunch_o := (reverse(8, st.res.data), "1111", to_stdl(st.left = 0), st.res.valid);
        elsif st.st = Skip then
            res.axis_ready_o := '1';
            if axis_bunch_i.valid = '1' then
                if axis_bunch_i.last = '1' then
                    res.st.st := Idle;
                end if;
            end if;
        end if;
        return res;
    end function;
begin
    process (clk, rstn)
    begin
        if rstn = '0' then
            st <= (Idle, uninitl, uninit(10), uninit(10), uninit32, zero(wait_width), nothing, nothing);
        elsif rising_edge(clk) then
            st <= res.st;
        end if;
    end process;

    res <= nextState(st, pcie_id_i, axis_bunch_i, axis_ready_i, rld_res_i);

    rld_req_o    <= st.req;
    axis_ready_o <= res.axis_ready_o;
    axis_bunch_o <= res.axis_bunch_o;
end architecture;
