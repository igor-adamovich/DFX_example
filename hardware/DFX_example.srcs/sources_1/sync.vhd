-- vim: set syntax=vhdl et sw=4 ts=4:

library ieee;
use ieee.std_logic_1164.all;

entity sync is
    generic (
        data_width  : positive := 1;
        sync_stages : positive := 2;
        data_r      : std_logic_vector);
    port (
        clk, rstn : in std_logic;
        --
        data_i : in  std_logic_vector(data_width-1 downto 0);
        data_o : out std_logic_vector(data_width-1 downto 0));
end entity;

architecture sync of sync is
    subtype data_t is std_logic_vector(data_width-1 downto 0);
    type data_array is array (integer range <>) of data_t;
    signal sync_data : data_array(sync_stages-1 downto 0);

    attribute ASYNC_REG : string;
    attribute ASYNC_REG of sync_data : signal is "TRUE";
begin
    process (clk, rstn)
    begin
        if rstn = '0' then
            sync_data <= (others => data_r);
        elsif rising_edge(clk) then
            sync_data <= sync_data(sync_stages-2 downto 0) & data_i;
        end if;
    end process;

    data_o <= sync_data(sync_stages-1);
end architecture;



library ieee;
use ieee.std_logic_1164.all;

entity sync_rstn is
    generic (
        sync_stages : positive := 2);
    port (
        clk, rstn : in std_logic;
        --
        rstn_o : out std_logic);
end entity;

architecture sync_rstn of sync_rstn is
begin
    sync : entity work.sync
        generic map (
            data_width  => 1,
            sync_stages => sync_stages,
            data_r(0)   => '0')
        port map (
            clk  => clk,
            rstn => rstn,
            --
            data_i(0) => '1',
            data_o(0) => rstn_o);
end architecture;
