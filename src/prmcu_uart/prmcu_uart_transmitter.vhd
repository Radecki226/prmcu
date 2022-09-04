-----------------------------------------------------------------
-- Name        : prmcu_uart_transmitter.vhdl
-----------------------------------------------------------------
-- Description : Module designed to serve as uart transmitter.
-----------------------------------------------------------------
-- Author      : Piotr Radecki
-----------------------------------------------------------------
-- Edited      : January 2022
-----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity prmcu_uart_transmitter is 
	port(
		clk                    : in  std_logic;
		internal_clk_divider_i : in  std_logic_vector(15 downto 0);
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
end prmcu_uart_transmitter;

architecture rtl of prmcu_uart_transmitter is

	-- in/out signal copies
	signal in_mask_s : std_logic_vector(8 downto 0);
	signal in_dat_s  : std_logic_vector(8 downto 0);
	signal in_dat_r  : std_logic_vector(8 downto 0); -- shift register
	signal in_rdy_s  : std_logic;

	
	type tx_fsm_t is (IDLE, START, DATA, PARITY, STOP1, STOP2);
	signal tx_fsm_r : tx_fsm_t;

	-- config signals
	signal internal_clk_divider_r : std_logic_vector(15 downto 0);
	signal n_parity_bits_r        : std_logic;
	signal n_stop_bits_r          : std_logic_vector(1 downto 0);
	signal n_data_bits_r          : std_logic_vector(3 downto 0);
	signal parity_bit_r           : std_logic;

	-- counters
	signal dat_counter_r           : unsigned(3 downto 0);
	--signal dat_counter_en          : std_logic;

	signal internal_clk_counter_r  : unsigned(16 downto 0);
	signal internal_clk_debug_r    : std_logic;
	signal internal_clk_counter_r1 : unsigned(16 downto 0); -- delayed copy
	signal internal_clk_counter_en : std_logic;


begin

	-- internal clock generator
	internal_clk_counter_p : process(clk)
	begin
		if rising_edge(clk) then 
			if internal_clk_counter_en = '1' then 
				if internal_clk_counter_r = unsigned(internal_clk_divider_r)-1 then 
					internal_clk_counter_r <= (others => '0');
					internal_clk_debug_r   <= '1';
				else
					internal_clk_counter_r <= internal_clk_counter_r + 1;
					internal_clk_debug_r <= '0';
				end if;
			end if;


			if rst = '1' then 
				internal_clk_counter_r <= (others => '0');
			end if;

		end if;
	end process;

	mask_in_dat_p : process(n_data_bits_i)
	begin
		case n_data_bits_i is 
			when "0101" =>
				in_mask_s <= "000011111";
			when "0110" =>
				in_mask_s <= "000111111";
			when "0111" =>
				in_mask_s <= "001111111";
			when "1000" =>
				in_mask_s <= "011111111";
			when others => --9
				in_mask_s <= "111111111";
		end case;
	end process;

	in_dat_s <= in_dat_i and in_mask_s;

	-- FSM registered part
	tx_fsm_reg_p : process(clk)
		variable parity_bit_v : std_logic;
	begin
		if rising_edge(clk) then 
			case tx_fsm_r is 
				
				when START => 
					if internal_clk_counter_r = unsigned(internal_clk_divider_r)-1 then 
						tx_fsm_r <= DATA;
					end if;

				when DATA =>
					if internal_clk_counter_r = unsigned(internal_clk_divider_r)-1 then 
						in_dat_r <= '0' & in_dat_r(8 downto 1);
						if dat_counter_r = unsigned(n_data_bits_r)-1 then 
							if n_parity_bits_r = '1' then 
								tx_fsm_r <= PARITY;
							elsif n_stop_bits_r = "01" then  
								tx_fsm_r <= STOP2;
							else 
								tx_fsm_r <= STOP1;
							end if;
						end if;
						dat_counter_r <= dat_counter_r + 1; 
					end if;

				when PARITY => 
					if internal_clk_counter_r = unsigned(internal_clk_divider_r)-1 then 
						if n_stop_bits_r = "01" then 
							tx_fsm_r <= STOP2;
						else
							tx_fsm_r <= STOP1;
						end if;
					end if;

				when STOP1 =>
					if internal_clk_counter_r = unsigned(internal_clk_divider_r)-1 then 
						tx_fsm_r <= STOP2;
					end if;

				when STOP2 =>
					if internal_clk_counter_r = unsigned(internal_clk_divider_r)-1 then 
						tx_fsm_r <= IDLE;
					end if;

				when others => --IDLE
					if in_vld_i = '1' and in_rdy_s = '1' and tx_en = '1' then 
						tx_fsm_r               <= START;
						in_dat_r               <= in_dat_s;
						internal_clk_divider_r <= internal_clk_divider_i;
						n_parity_bits_r        <= n_parity_bits_i;
						n_stop_bits_r          <= n_stop_bits_i;
						n_data_bits_r          <= n_data_bits_i;
						dat_counter_r          <= (others => '0');
						
						parity_bit_v := '0';
						for i in 0 to 8 loop
							parity_bit_v := parity_bit_v xor in_dat_s(i);
						end loop;
						parity_bit_r <= parity_bit_v;

					end if;
			end case;

			if rst = '1' then 
				tx_fsm_r <= IDLE;
			end if;

		end if;
	end process;

	-- FSM, combinational part
	tx_fsm_comb_p : process(tx_fsm_r, in_dat_r, parity_bit_r)
	begin
		case tx_fsm_r is 
			when START => 
				tx_o <= '0';

			when DATA => 
				tx_o <= in_dat_r(0);

			when PARITY => 
				tx_o <= parity_bit_r;

			when others => 
				tx_o <= '1';

		end case;

		if tx_fsm_r = IDLE then 
			internal_clk_counter_en <= '0';
			in_rdy_s <= '1';
		else 
			internal_clk_counter_en <= '1';
			in_rdy_s <= '0';
		end if;

	end process;


	-- output assignment
	in_rdy_o <= in_rdy_s;

end rtl; 
