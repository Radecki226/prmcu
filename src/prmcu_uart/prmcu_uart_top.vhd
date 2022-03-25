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
		clk                    : in  std_logic;
		internal_clk_o         : out std_logic; --rx clk, just for test purposes
		rst                    : in  std_logic;

		-- control
		uart_en                : in  std_logic;
		tx_en                  : in  std_logic;
		rx_en                  : in  std_logic;
		n_parity_bits_i        : in  std_logic; 
		n_stop_bits_i          : in  std_logic_vector(1 downto 0); 
		n_data_bits_i          : in  std_logic_vector(3 downto 0); 
		internal_clk_divider_i : in  std_logic_vector(7 downto 0);
  
		--input axi interface
		in_dat_i               : in  std_logic_vector(8 downto 0);
		in_vld_i               : in  std_logic;
		in_rdy_o               : out std_logic;

		-- output axi interface
		out_dat_o              : out std_logic_vector(8 downto 0);
		out_vld_o              : out std_logic;
		out_rdy_i              : in  std_logic;

		--to external device
		tx_o                   : out std_logic;
		rx_i                   : in  std_logic
	);
end entity prmcu_uart_top;
	
architecture rtl of prmcu_uart_top is
	
	-----------------------------------------------------------------
	-- COMPONENTS
	-----------------------------------------------------------------
	component prmcu_uart_transmitter is 
		port(
			clk                    : in  std_logic;
			internal_clk_divider_i : in  std_logic_vector(7 downto 0);
			rst                    : in  std_logic;
			tx_en                  : in  std_logic;
			n_parity_bits_i        : in  std_logic;
			n_stop_bits_i          : in  std_logic_vector(1 downto 0);
			n_data_bits_i          : in  std_logic_vector(3 downto 0);
			
			in_dat_i               : in  std_logic_vector(8 downto 0);
			in_vld_i               : in  std_logic;
			in_rdy_o               : out std_logic;

			tx_o                   : out std_logic
		);
	end component;

	component prmcu_uart_receiver is 
		port(
			clk                    : in  std_logic;
			internal_clk_divider_i : in  std_logic_vector(7 downto 0);
			rst                    : in  std_logic;
			rx_en_i                : in  std_logic;
			n_parity_bits_i        : in  std_logic;
			n_stop_bits_i          : in  std_logic_vector(1 downto 0);
			n_data_bits_i          : in  std_logic_vector(3 downto 0);

			out_dat_o              : out std_logic_vector(8 downto 0);
			out_vld_o              : out std_logic;
			out_rdy_i              : in  std_logic;

			rx_i                   : in std_logic
		);
	end component;

			

			
begin
	
	-----------------------------------------------------------------
	-- INSTANCES
	-----------------------------------------------------------------
	transmitter_i : prmcu_uart_transmitter
	port map(
 		clk                    => clk and uart_en,
		internal_clk_divider_i => internal_clk_divider_i,
		rst                    => rst, 
		tx_en                  => tx_en,
		n_parity_bits_i        => n_parity_bits_i,
		n_stop_bits_i          => n_stop_bits_i,
		n_data_bits_i          => n_data_bits_i,

		in_dat_i               => in_dat_i,
		in_vld_i               => in_vld_i,
		in_rdy_o               => in_rdy_o,

		tx_o                   => tx_o
	);

	receiver_i : prmcu_uart_receiver
	port map(
		clk                    => clk and uart_en,
		internal_clk_divider_i => internal_clk_divider_i,
		rst                    => rst,
		rx_en_i                => rx_en,
		n_parity_bits_i        => n_parity_bits_i,
		n_stop_bits_i          => n_stop_bits_i,
		n_data_bits_i          => n_data_bits_i,

		out_dat_o              => out_dat_o,
		out_vld_o              => out_vld_o,
		out_rdy_i              => out_rdy_i,

		rx_i                   => rx_i
	);

	-----------------------------------------------------------------
	
	-----------------------------------------------------------------
	-- OUTPUT ASSIGNEMENTS
	-----------------------------------------------------------------
	-----------------------------------------------------------------

	

end rtl;
