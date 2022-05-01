--------------------------------------------
-- Author : Piotr Radecki
--------------------------------------------
-- Edited : April 2022
--------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity prmcu_uart_hw_test is 
	generic(
    CLK_DIVIDER : integer := 87
  );
  port(
	  clk : in std_logic;
	  n_rst : in std_logic;
	  
	  tx_o : out std_logic;
	  rx_i : in std_logic;

	  led_dat_o : out std_logic;
	  led_vld_o : out std_logic

  );
end entity prmcu_uart_hw_test;

architecture rtl of prmcu_uart_hw_test is

  component prmcu_uart_top is
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
  end component prmcu_uart_top;
  
	signal in_vld_r : std_logic;

	signal out_dat_s : std_logic_vector(8 downto 0);
	signal out_vld_s : std_logic;

	signal counter_r : unsigned(23 downto 0);

	signal led_vld_r : std_logic;
	signal led_dat_r : std_logic;

	signal INTERVAL : integer := 1000000;
	

begin

	uart_i : prmcu_uart_top
  port map(
    clk => clk,
    internal_clk_o => open,
    rst => not(n_rst),

		uart_en => '1',
		tx_en => '1',
		rx_en => '1',
		n_parity_bits_i => '0',
		n_stop_bits_i => "01",
		n_data_bits_i => "1000",
		internal_clk_divider_i => "01010111", --87

		in_dat_i => "001010100", --T
		in_vld_i => in_vld_r,
		in_rdy_o => open,

		out_dat_o => out_dat_s,
		out_vld_o => out_vld_s,
		out_rdy_i => '1',

		tx_o => tx_o,
		rx_i => rx_i

 	);

	diode_control_p : process(clk)
	begin
	  if rising_edge(clk) then
			led_vld_r <= '0';
			if out_vld_s = '1' then
			  if out_dat_s = "001110100" then
				  led_dat_r <= not led_dat_r;
					led_vld_r <= '1';
				end if;
			end if;

			if n_rst = '0' then
			  led_dat_r <= '0';
				led_vld_r <= '0';
			end if;
		end if;
	end process;

	
	signal_gen_p : process(clk) begin
	  if rising_edge(clk) then
			in_vld_r <= '0';
			if counter_r = INTERVAL-1 then
				in_vld_r <= '1';
			end if;
		  
			if n_rst = '0' then
				in_vld_r <= '0';
			end if;

		end if;
	end process;
	
	

	counter_p : process(clk) begin
		if rising_edge(clk) then
			if counter_r = INTERVAL-1 then
				counter_r <= (others => '0');
			else
				counter_r <= counter_r + 1;
			end if;

			if n_rst = '0' then
				counter_r <= (others => '0');
			end if;
		end if;
	end process;
	
	
		

	led_dat_o <= led_dat_r;
	led_vld_o <= led_vld_r;
			  

end rtl;
  
    
 

    
  
                                                      	
