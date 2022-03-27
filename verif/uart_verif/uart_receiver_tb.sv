`timescale 1ns/1ps
`ifndef N_DATA
  `define N_DATA 100
`endif
`ifndef N_BITS
  `define N_BITS 6
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
	
	bit [8:0] out_dat_buffer [`N_DATA:0];

	bit [8:0] rx_dat_buffer [`N_DATA:0];
	bit       rx_driver;

	int out_dat_written = 0;
	int error_cnt = 0;
	int finish_flag = 0;
	
	reg external_clk;

	reg        clk;
	wire       internal_clk;
	reg        rst;

	reg        uart_en;
	reg        tx_en;
	reg        rx_en;
	reg        n_parity_bits;
	reg  [1:0] n_stop_bits;
	reg  [3:0] n_data_bits;
	reg  [7:0] internal_clk_divider;

	reg  [8:0] in_dat;
	reg        in_vld;
	wire       in_rdy;

	wire [8:0] out_dat;
	wire       out_vld;
	reg        out_rdy;

	wire      tx;
	reg       rx;


	/*DUT declaration*/
	prmcu_uart_top dut(
		.clk(clk),
		.internal_clk_o(internal_clk),
		.rst(rst),

		.uart_en(uart_en),
		.tx_en(tx_en),
		.rx_en(rx_en),
		.n_parity_bits_i(n_parity_bits),
		.n_stop_bits_i(n_stop_bits),
		.n_data_bits_i(n_data_bits),
		.internal_clk_divider_i(internal_clk_divider),

		.in_dat_i(in_dat),
		.in_vld_i(in_vld),
		.in_rdy_o(in_rdy),
		
		.out_dat_o(out_dat),
		.out_vld_o(out_vld),
		.out_rdy_i(out_rdy),

		.tx_o(tx),
		.rx_i(rx)
	);

	
	/*10MHz*/
	always #50 clk =~ clk;

	
	/*115 kbaud*/
  always #(`RECV_DELAY) external_clk =~ external_clk;
	
	/*Clock stimulous*/
	initial begin
		external_clk <= 1;
		clk <= 0;
		rst <= 1;
		uart_en <= 1;
	  #100	
		rst <= 0;
		tx_en <= 0;
		rx_en <= 1;
		rx <= 1;
		out_rdy <= 1;
		n_parity_bits <= `N_PARITY_BITS;
		n_stop_bits <= `N_STOP_BITS;
		n_data_bits <= `N_BITS;
		internal_clk_divider <= 87; /*115200*/ /*div - 87:*/
		
		
		/*#10000000 
		if (error_cnt > 0) begin
			$display("Sumlation FAILED!");
		end else begin
			$display("Simulation PASSED!");
		end
		$display("test %d\n", `TEST);
		$display("delay %d\n", `RECV_DELAY);
		$finish;*/

	end

	/*dump*/
	initial begin
		$dumpfile("uart_dump.vcd");
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
			if (`N_PARITY_BITS == 1) begin
			  rx = ^rx_dat_buffer[i][`N_BITS-1:0];
				@(posedge external_clk);
			end
			for (int j = 0; j < `N_STOP_BITS; j++) begin
				rx = 1;
				@(posedge external_clk);
			end

		end
	end

  /*Monitor out_dat*/
	initial begin
		@(rst == 1)
		@(posedge clk);
		for (int i = 0; i < `N_DATA; i++) begin
			@(out_vld == 1);
			@(posedge clk);
			out_dat_buffer[i] = out_dat;
			out_dat_written = 1;
			@(out_dat_written == 0);
			@(posedge clk);
		end
	end
	/*scoreboard*/
	
	initial begin
		for (int i = 0; i < `N_DATA; i++) begin
			@(out_dat_written == 1);
			if (out_dat_buffer[i][`N_BITS-1:0] == rx_dat_buffer[i][`N_BITS-1:0]) begin
        $display("T=%0t [Scoreboard] PASS! addr = 0x%0h received = 0x%0h expected = 0x%0h", 
			           $time, i, out_dat_buffer[i][`N_BITS-1:0], rx_dat_buffer[i][`N_BITS-1:0]);
			end else begin
				$display("T=%0t [Scoreboard] ERROR! data mismatch addr = 0x%0h received = 0x%0h expected = 0x%0h",
				         $time, i, out_dat_buffer[i][`N_BITS-1:0], rx_dat_buffer[i][`N_BITS-1:0]);
				error_cnt = error_cnt + 1;
			end
			out_dat_written = 0;
		end
		finish_flag = 1;
	end
	
	initial begin
		#100000000	
    $display("T=%0t [Scoreboard] ERROR! Not all data has been captured",$time);
	  error_cnt = error_cnt + 1;
		finish_flag = 1;
	end

	initial begin
		@(finish_flag == 1);
		if (error_cnt > 0) begin
			$display("Simulation FAILED!");
		end else begin
			$display("Simulation PASSED!");
	  end
		$finish;
	end
	

endmodule
