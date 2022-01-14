-----------------------------------------------------------------
-- Name : prmcu_uart.vhdl
-----------------------------------------------------------------
-- Description : Module designed to serve as uart controller. It
-- enables simultaneous reception and transmission of uart data.
-- Module consist of 32 x 8 rx\tx fifos.
-----------------------------------------------------------------
-- Author : Piotr Radecki
-----------------------------------------------------------------
-- Edited : January 2022
-----------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity prmcu_uart_top is
	port(
		clk                  : in  std_logic;
		internal_clk_o       : out std_logic;
		rst                  : in  std_logic;

		-- control
		uart_en              : in  std_logic;
		tx_en                : in  std_logic;
		rx_en                : in  std_logic;
		n_parity_bits        : in  std_logic; 
		n_stop_bits          : in  std_logic_vector(1 downto 0); 
		n_data_bits          : in  std_logic_vector(3 downto 0); 
		internal_clk_divider : in  std_logic_vector(7 downto 0);
  
		--input axi interface
		in_dat_i             : in  std_logic_vector(8 downto 0);
		in_vld_i             : in  std_logic;
		in_rdy_o             : in  std_logic;

		-- output axi interface
		out_dat_o            : out std_logic_vector(8 downto 0);
		out_vld_o            : out std_logic;
		out_rdy_i            : in  std_logic;

		--to external device
		tx_o                 : out std_logic;
		rx_i                 : in  std_logic
	);
end entity prmcu_uart_top;
	
architecture rtl of prmcu_uart_top is
	
	component prmcu_uart_transmitter is 
		port(
			clk            : in  std_logic;
			internal_clk_i : in  std_logic;
			rst            : in  std_logic;
			tx_en          : in  std_logic;
			n_parity_btis  : in  std_logic;
			n_stop_bits    : in  std_logic_vector(1 downto 0);
			
			in_dat_i       : in  std_logic_vector(8 downto 0);
			in_vld_i       : in  std_logic;
			in_rdy_o       : out std_logic;

			tx_o           : out std_logic
		);
	end component;


			
begin
	tx_o <= '1';
 
end rtl;
