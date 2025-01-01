-- vim: set syntax=vhdl et sw=4 ts=4:

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library unisim;
use unisim.vcomponents.all;
use work.address;
use work.util.all;

entity icape is
    port(
        clk, rstn : in std_logic;
        --
        req_i : in  rld32req_t);
end entity;

architecture icape of icape is
    signal csn, wen  : std_logic;
    signal res_data  : std_logic_vector(31 downto 0);
    signal data      : std_logic_vector(31 downto 0);
begin
    data(31 downto 24) <= reverse(1, req_i.data( 7 downto  0));
    data(23 downto 16) <= reverse(1, req_i.data(15 downto  8));
    data(15 downto  8) <= reverse(1, req_i.data(23 downto 16));
    data( 7 downto  0) <= reverse(1, req_i.data(31 downto 24));

    icape : ICAPE2
        --generic map (
        --    ICAP_WIDTH => "X32")
        port map (
            CLK   => clk,
            CSIB  => csn,
            I     => data,
            O     => res_data,
            RDWRB => wen);

    csn <= not to_stdl(req_i.we = '1' and req_i.addr = address.icape);
    wen <= not req_i.we;
end architecture;
