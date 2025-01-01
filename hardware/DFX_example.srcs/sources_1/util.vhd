-- vim: set syntax=vhdl et sw=4 ts=4:

library ieee;
use ieee.std_logic_1164.all;

package util is
    function to_stdl (b : boolean) return std_logic;
    function "and" (v : std_logic_vector; l : std_logic) return std_logic_vector;
    function reverse (n : positive; v : std_logic_vector) return std_logic_vector;

    constant uninitl : std_logic := 'U';
    function zero (n : natural := 0) return std_logic_vector;
    function uninit (n : natural := 0) return std_logic_vector;

    subtype data4_range is integer range 3 downto 0;
    subtype data4_t is std_logic_vector(data4_range);
    constant uninit4 : data4_t := uninit(4);

    subtype data8_range is integer range 7 downto 0;
    subtype data8_t is std_logic_vector(data8_range);
    constant uninit8 : data8_t := uninit(8);

    subtype data16_range is integer range 15 downto 0;
    subtype data16_t is std_logic_vector(data16_range);
    constant uninit16 : data16_t := uninit(16);

    subtype data32_range is integer range 31 downto 0;
    subtype data32_t is std_logic_vector(data32_range);
    constant uninit32 : data32_t := uninit(32);
    function extend32 (l : std_logic) return data32_t;

    subtype data64_range is integer range 63 downto 0;
    subtype data64_t is std_logic_vector(data64_range);
    constant uninit64 : data64_t := uninit(64);

    constant raddr_width : integer := 16;
    subtype raddr_range is integer range raddr_width-1 downto 0;
    subtype raddr_t is std_logic_vector(raddr_range);
    constant raddr_uninit : raddr_t := uninit(raddr_width);

    type rld32req_t is record
        addr   : raddr_t;
        data   : data32_t;
        re, we : std_logic;
    end record;
    function nothing return rld32req_t;

    type rld32res_t is record
        data  : data32_t;
        valid : std_logic;
    end record;
    function nothing return rld32res_t;

    type axis_bunch32_t is record
        data  : data32_t;
        keep  : data4_t;
        last  : std_logic;
        valid : std_logic;
    end record;
    function nothing return axis_bunch32_t;

    type axis_bunch64_t is record
        data  : data64_t;
        keep  : data8_t;
        last  : std_logic;
        valid : std_logic;
    end record;
    function nothing return axis_bunch64_t;
    function "and" (b : axis_bunch64_t; l : std_logic) return axis_bunch64_t;
end package;

package body util is
    function to_stdl (b : boolean) return std_logic is
    begin
        if b then
            return '1';
        else
            return '0';
        end if;
    end function;

    function "and" (v : std_logic_vector; l : std_logic) return std_logic_vector is
        variable res : std_logic_vector(v'range);
    begin
        for i in v'range loop
            res(i) := v(i) and l;
        end loop;
        return res;
    end function;

    function reverse (n : positive; v : std_logic_vector) return std_logic_vector is
        variable res : std_logic_vector(v'range);
    begin
        for i in v'range loop
            res(i) := v(v'low+((v'high-v'low)/n-(i-v'low)/n)*n+((i-v'low) rem n));
        end loop;
        return res;
    end function;

    function zero (n : natural := 0) return std_logic_vector is
        constant res : std_logic_vector(n-1 downto 0) := (others => '0');
    begin
        return res;
    end function;

    function uninit (n : natural := 0) return std_logic_vector is
        constant res : std_logic_vector(n-1 downto 0) := (others => uninitl);
    begin
        return res;
    end function;

    function extend32 (l : std_logic) return data32_t is
        variable res : data32_t := (others => '0');
    begin
        res(0) := l;
        return res;
    end function;

    function nothing return rld32req_t is
    begin
        return (addr  => raddr_uninit,
                data  => uninit32,
                re    => '0',
                we    => '0');
    end function;

    function nothing return rld32res_t is
    begin
        return (data  => uninit32,
                valid => '0');
    end function;

    function nothing return axis_bunch32_t is
    begin
        return (data  => uninit32,
                keep  => uninit4,
                last  => uninitl,
                valid => '0');
    end function;

    function nothing return axis_bunch64_t is
    begin
        return (data  => uninit64,
                keep  => uninit8,
                last  => uninitl,
                valid => '0');
    end function;

    function "and" (b : axis_bunch64_t; l : std_logic) return axis_bunch64_t is
    begin
        return (data  => b.data,
                keep  => b.keep,
                last  => b.last,
                valid => b.valid and l);
    end function;
end package body;
