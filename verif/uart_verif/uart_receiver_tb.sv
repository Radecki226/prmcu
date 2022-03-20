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
 
/*Assumption is that input clk has f=10MHz*/
module tb;
	
	bit [8:0] out_dat_buffer [`N_DATA:0];
	bit [2:0] out_overhead_buffer [`N_DATA:0];

	bit [8:0] rx_dat_buffer [`N_DATA:0];
	bit [2:0] rx_overhead_buffer [`N_DATA:0];

	int tx_written = 0;
	int error_cnt = 0;
	int sc_i = 0;
	
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
	int       state;
	int       drv_dat;


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
		external_clk <= 0;
		clk <= 0;
		rst <= 1;
		uart_en <= 1;
		#100 
		rst <= 0;
		tx_en <= 0;
		rx_en <= 1;
		n_parity_bits <= `N_PARITY_BITS;
		n_stop_bits <= `N_STOP_BITS;
		n_data_bits <= `N_BITS;
		internal_clk_divider <= 87; /*115200*/ /*div - 87:*/
		
		
		#10000000 
		if (error_cnt > 0) begin
			$display("Sumlation FAILED!");
		end else begin
			$display("Simulation PASSED!");
		end
		$display("test %d\n", `TEST);
		$display("delay %d\n", `RECV_DELAY);
		$finish;

	end

	/*dump*/
	initial begin
		$dumpfile("uart_dump.vcd");
		$dumpvars;
	end

	/*write (in_dat) generator and driver*/
	initial begin
		in_vld <= 0;
		drv_dat = 1;
		#340
		in_vld <= 1;
		rx_dat <= $urandom();
		for (int i = 0; i < n_writes; i++) begin
			$display("T = %0t [generator] frame idx: 0%0d",$time ,i);
			drv_dat = 1;
			in_vld = 1;
			@(drv_dat == 0);			
		end
		in_vld <= 0;
	end

	/*driver*/
	always @(posedge clk) begin
		if (drv_dat == 1 && in_rdy == 1 && in_vld == 1) begin
			in_dat[8] <= 0;
			in_dat[7:0] <= $urandom();
			drv_dat <= 0;
		end
	end


	/*monitor in_dat_part*/
	initial begin
		reg [2:0] in_overhead_capture; 
		for (int i = 0; i < n_writes; i++) begin
			@(posedge clk);
			
			if (in_rdy == 1 && in_vld == 1) begin
				in_dat_buffer[i] = in_dat[`N_BITS-1:0];
	
				in_overhead_capture = 3'b010;
				if (n_parity_bits == 1'b1) begin
					in_overhead_capture[0] = ^in_dat[`N_BITS-1:0];
				end	
				if (n_stop_bits == 2) begin 
					in_overhead_capture[2:1] = 2'b11; 
				end
				in_overhead_buffer[i] = in_overhead_capture;

			end else begin
				i = i-1;
			end
		end
	end

	/*monitor in tx part*/
	initial begin
		@(tx == 1);
		for (int i = 0; i < n_writes; i++) begin 
			@(tx == 0);
			@(posedge external_clk);
			tx_dat_capture =  0;
			tx_parity_capture = 0;
			tx_stop_capture = 0;
			state = 1;
			for (int j = 0; j < n_data_bits; j++) begin
				@(posedge external_clk);
				state = 2;
				tx_dat_capture[j] = tx;
			end
			for (int j = 0; j < n_parity_bits; j++) begin
				@(posedge external_clk);
				tx_parity_capture = tx;
				state = 3;
			end
			for (int j = 0; j < n_stop_bits; j++) begin 
				@(posedge external_clk);
				tx_stop_capture[j] = tx;
				state = 4;
			end
			tx_dat_buffer[i] = tx_dat_capture;
			tx_overhead_buffer[i] = {tx_stop_capture,tx_parity_capture};
			tx_written = 1;
		end
	end

	/*scoreboard*/
	
	initial begin
		for (sc_i = 0; sc_i < n_writes; sc_i++) begin
			@(tx_written == 1);
			tx_written = 0;
			if (tx_dat_buffer[sc_i] == in_dat_buffer[sc_i]) begin
        		if (tx_overhead_buffer[sc_i] == in_overhead_buffer[sc_i]) begin
            		$display("T=%0t [Scoreboard] PASS! addr = 0x%0h expected = 0x%0h received = 0x%0h", 
					         $time, sc_i, in_dat_buffer[sc_i], tx_dat_buffer[sc_i]);
				end else begin
					$display("T=%0t [Scoreboard] ERROR! overhead mismatch addr = 0x%0h expected = %0b received = %0b",
				         	$time, sc_i, in_overhead_buffer[sc_i], tx_overhead_buffer[sc_i]);
					error_cnt = error_cnt + 1;
				end 
			end else begin
				$display("T=%0t [Scoreboard] ERROR! data mismatch addr = 0x%0h expected = 0x%0h received = 0x%0h",
				         $time, sc_i, in_dat_buffer[sc_i], tx_dat_buffer[sc_i]);
			end
		end
	end
	
	initial begin
		#10000000	
		if(sc_i < n_writes-1) begin
    		$display("T=%0t [Scoreboard] ERROR! Not all data has been captured. Captured frames: %0d", $time, sc_i);
			error_cnt = error_cnt + 1;
		end
	end
	

endmodule
