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
		rst                    : in  std_logic;
		internal_clk_divider_i : in  std_logic_vector(7 downto 0);
		rx_en_i                : in  std_logic;	
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
	
	--copy of output signals
	signal out_dat_r  : std_logic_vector(8 downto 0); -- shift register
	signal out_vld_s  : std_logic;

	
	type rx_fsm_t is (IDLE, WAIT_HALF_BIT, START, DATA, PARITY, STOP, SEND_ERROR, SEND_DATA);
	signal rx_fsm_r : rx_fsm_t;

	--config signals
	signal internal_clk_divider_r      : std_logic_vector(7 downto 0);
	signal internal_clk_divider_div2_s : std_logic_vector(7 downto 0);
	signal n_parity_bits_r             : std_logic;
	signal n_stop_bits_r               : std_logic_vector(1 downto 0);
	signal n_data_bits_r               : std_logic_vector(3 downto 0);
	signal parity_bit_r                : std_logic;
	signal output_shift_s              : unsigned(3 downto 0);

	-- counters
	signal dat_counter_r          : unsigned(3 downto 0);

	signal internal_clk_counter_r  : unsigned(8 downto 0);
	signal internal_clk_debug_r    : std_logic;
	signal internaL_clk_counter_en : std_logic;

	-- error
	signal parity_err_flag_r : std_logic;
	signal err_pulse_s       : std_logic;

	signal rx_r              : std_logic;

begin

	-- internal clock generator
	internal_clk_counter_p : process(clk)
	begin
		if rising_edge(clk) then
			if internal_clk_counter_en = '1' then
        if internal_clk_counter_r = unsigned(internal_clk_divider_r)-1 then
				  internal_clk_counter_r <= (others => '0');
				  internal_clk_debug_r <= '1';
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
	internal_clk_divider_div2_s <= '0' & internal_clk_divider_r(7 downto 1);

	-- FSM registered part
	rx_fsm_reg_p : process(clk)
	begin
		if rising_edge(clk) then
			rx_r <= rx_i;
			case rx_fsm_r is

				when START => 
          if internal_clk_counter_r = unsigned(internal_clk_divider_r)-1 then 
            rx_fsm_r <= DATA;
          end if;

				when DATA => 
					if internal_clk_counter_r = unsigned(internal_clk_divider_div2_s)-1 then
						out_dat_r <= rx_i & out_dat_r(8 downto 1);
						parity_bit_r <= parity_bit_r xor rx_i;
					end if;

					if internal_clk_counter_r = unsigned(internal_clk_divider_r)-1 then
						if dat_counter_r = unsigned(n_data_bits_r)-1 then
							if n_parity_bits_r = '1' then
								rx_fsm_r <= PARITY;
							else
								rx_fsm_r <= STOP;
							end if;
						end if;
					  dat_counter_r <= dat_counter_r + 1;
					end if;

        when PARITY =>
          if internal_clk_counter_r = unsigned(internal_clk_divider_div2_s)-1 then
						
						if parity_bit_r = rx_i then
							parity_err_flag_r <= '0';
						else 
							parity_err_flag_r <= '1';
						end if;
							
						rx_fsm_r <= STOP;

					end if;

			when STOP =>
				if parity_err_flag_r = '1' then
					rx_fsm_r <= SEND_ERROR;
				else
					rx_fsm_r <= SEND_DATA;
				end if;

			when SEND_ERROR =>
				rx_fsm_r <= IDLE;

			when SEND_DATA =>
				if out_rdy_i = '1' and out_vld_s = '1' then --TODO: problematic
					rx_fsm_r <= IDLE;
				end if;

			when others => --IDLE
			  if rx_i = '0' and rx_r = '1' and rx_en_i = '1' then
					rx_fsm_r               <= START;
					internal_clk_divider_r <= internal_clk_divider_i;
					n_parity_bits_r        <= n_parity_bits_i;
					n_stop_bits_r          <= n_stop_bits_i;
					n_data_bits_r          <= n_data_bits_i;
					dat_counter_r          <= (others => '0');
					out_dat_r              <= (others => '0');
					parity_bit_r           <= '0';
					parity_err_flag_r      <= '0';
				end if;
			end case;

			if rst = '1' then
				rx_fsm_r <= IDLE;
			end if;

		end if;
	end process;

	--FSM, combinational part
	rx_fsm_comb_p : process(rx_fsm_r)
	begin
		if rx_fsm_r = SEND_DATA then
			out_vld_s <= '1';
		else
			out_vld_s <= '0';
		end if;

		if rx_fsm_r = SEND_ERROR then
			err_pulse_s <= '1';
		else
			err_pulse_s <= '0';
		end if;

		if rx_fsm_r = IDLE then
			internal_clk_counter_en <= '0';
		else
			internal_clk_counter_en <= '1';
		end if;

	end process;

  -- output assignmend
	output_shift_s <= 9 - unsigned(n_data_bits_r);
	out_dat_o <= std_logic_vector(shift_right(unsigned(out_dat_r),to_integer(output_shift_s)));
   out_vld_o <= out_vld_s;


end rtl;
