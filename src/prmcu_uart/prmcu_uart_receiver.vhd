-----------------------------------------------------------------
-- Name : prmcu_uart_receiver.vhdl
-----------------------------------------------------------------
-- Description : Uart receiver
-----------------------------------------------------------------
-- Author : Piotr Radecki
-----------------------------------------------------------------
-- Edited : January 2022
-----------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity prmcu_uart_receiver is 
	port(
		clk                    : in  std_logic;
		internal_clk_divider_i : in  std_logic_vector(7 downto 0);
		rst                    : in  std_logic;
		rx_en                  : in  std_logic;	
		n_parity_bits_i        : in  std_logic;
		n_stop_bits_i          : in  std_logic_vector(1 downto 0);
		n_data_bits_i          : in  std_logic_vector(3 downto 0);

		out_dat_o              : out std_logic_vector(8 downto 0);
		out_vld_o              : out std_logic;
		out_rdy_i              : in  std_logic;

		rx_i                   : in  std_logic
	);
end entity prmcu_uart_receiver;


architecture rtl of prmcu_uart_receiver is 
begin

	out_dat_o <= (others => '0');

end rtl;
