`timescale 1ns/1ps
`ifndef N_DATA
  `define N_DATA 100
`endif
`ifndef N_BITS
  `define N_BITS 8
`endif
`ifndef N_STOP_BITS
  `define N_STOP_BITS 6
`endif
`ifndef N_PARITY_BITS
  `define N_PARITY_BITS 6
`endif
`ifndef RECV_RATE
  `define RECV_RATE 115000
`endif
`define RECV_DELAY 1000000000/(2*`RECV_RATE)
`ifndef ITERATION_DELAY
  `define ITERATION_DELAY 2
`endif

 
/*Assumption is that input clk has f=10MHz*/
module tb;
	
	/*rx side*/
  bit [`N_BITS-1:0] led_state [`N_DATA:0];

	bit [`N_BITS-1:0] rx_dat_buffer [`N_DATA-1:0];
	bit               rx_driver;

	/*tx side*/
	bit [`N_BITS-1:0] tx_dat;
	bit [`N_BITS-1:0] tx_result;

	int led_written = 0;
	int tx_written = 0;

	int error_cnt = 0;
	int error_cnt_tx = 0;
	int finish_flag = 0;
	
	reg external_clk;

	reg        clk;
	reg        rst;


	wire      tx;
	reg       rx;

  wire      led_dat;
	wire      led_vld;


	/*DUT declaration*/
	prmcu_uart_hw_test_dut
	#(parameter CLK_DIVIDER=87)
	(
		.clk(clk),
		.rst(rst),
    
		.tx_o(tx),
		.rx_i(rx),

		.led_dat_o(led),
		.led_vld_o(led_vld)
	)
	
	/*10MHz*/
	always #50 clk =~ clk;

	
	/*115 kbaud*/
  always #(`RECV_DELAY) external_clk =~ external_clk;
	
	/*Clock stimulous*/
	initial begin
		external_clk <= 1;
		clk <= 0;
		rst <= 1;
	  #100	
		rst <= 0;
		rx <= 1;
	end

	/*dump*/
	initial begin
		$dumpfile("uart_hw_test_dump.vcd");
		$dumpvars;
	end

	/*rx dat generator*/
	initial begin
		for (int i = 0; i < `N_DATA; i++) begin
			rx_dat_buffer[i] <= $urandom();
		end
	end

	/*driver*/
	initial begin
		@(rst == 1);
		#100
		for (int i = 0; i < `N_DATA; i++) begin
      #`ITERATION_DELAY
      $display("T=%0t [Driver] Data with addr = 0x%0h and value = 0x%0h has been driven", 
			         $time, i, rx_dat_buffer[i]);
			rx = 0;
			@(posedge external_clk);
			for (int j = 0; j < `N_BITS; j++) begin
				rx = rx_dat_buffer[i][j];
				@(posedge external_clk);
			end
			/*stop bit*/
			rx = 1;
			@(posedge external_clk);

		end
	end

  /*Monitor led*/
	initial begin
		@(rst == 1)
		@(posedge clk);
		for (int i = 0; i < `N_DATA; i++) begin
			@(led_vld == 1);
			@(posedge clk);
			led_state[i] = led_dat;
			led_written = 1;
			@(led_written == 0);
			@(posedge clk);
		end
	end

	/*monitor tx*/
  initial begin
		@(tx == 1);
		while (1) begin
			@(tx == 0);
			@posedge(external_clk);
			for (int i = 0; i < `N_BITS ; i++) begin
				@(posedge external_clk);
				tx_dat[i] = tx;
			end
			//stop bit
			@(posedge external_clk);
			tx_result = tx_dat;
		  tx_written = 1;
		end
	end

	/*scoreboard diode*/
	
	initial begin
		for (int i = 0; i < `N_DATA; i++) begin
			@(led_written == 1);
			if (i != 0) begin
				if (led[i] == led[i-1]) begin
					if rx_dat_buffer[i] != 84 begin
						$display("T=%0t [Scoreboard] ERROR! Diode changed although it shouldn't have!",$time, i);
						error_cnt = error_cnt + 1;
				  end
				else begin
					if rx_dat_buffer[i] == 84 begin
						$display("T=%0t [Scoreboard] ERROR! Diode didn't change although it should have!",$time, i);
						error_cnt = error_cnt + 1;
					end else begin
						$display("T=%0t [Scoreboard] PASS! Diode changed OK!",$time, i);
					end
				end
			end
      led_written = 0;
		end
		finish_flag_led = 1;
	end
  
	/*scoreboard tx*/
  initial begin
	  while(1) begin
			@(tx_written == 1);
			tx_written = 0;
			if (tx_result == 84) begin
				$display("T=%0t [Scoreboard] PASS! Tx ok", $time);
			else begin
				$display("T=%0t [Scoreboard] ERROR! Tx wrong value = 0x%0h", $time, tx_result);
				error_cnt_tx += 1;
			end
		end
	end
	
	initial begin
		#100000000	
    $display("T=%0t [Scoreboard] ERROR! Not all data has been captured",$time);
	  error_cnt = error_cnt + 1;
		finish_flag = 1;
	end

	initial begin
		@(finish_flag == 1);
		if (error_cnt + error_cnt_tx > 0) begin
			$display("Simulation FAILED!");
		end else begin
			$display("Simulation PASSED!");
	  end
		$finish;
	end
	

endmodule
