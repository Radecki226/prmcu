`timescale 1ns/1ps
 
/*Assumption is that input clk has f=10MHz*/
module tb;
	int n_writes = 20;
	bit [8:0] in_dat_buffer [100];
	bit [2:0] in_overhead_buffer [100];

	bit [8:0] tx_dat_buffer [100];
	bit [2:0] tx_overhead_buffer [100];
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


	/*DUT declaration*/
	prmcu_uart_top dut(
		.clk(clk),
		.internal_clk_o(internal_clk),
		.rst(rst),

		.uart_en(uart_en),
		.tx_en(tx_en),
		.rx_en(rx_en),
		.n_parity_bits(n_parity_bits),
		.n_stop_bits(n_stop_bits),
		.n_data_bits(n_data_bits),
		.internal_clk_divider(internal_clk_divider),

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

	/*113.6 kbaud*/
	always #4400 external_clk =~ clk;
	
	/*Clock stimulous*/
	initial begin
		clk <= 0;
		external_clk <= 0;
		rst <= 1;
		#100 
		rst <= 0;
		uart_en <= 1;
		tx_en <= 1;
		rx_en <= 0;
		n_parity_bits <= 0;
		n_stop_bits <= 1;
		n_data_bits <= 8;
		internal_clk_divider <= 43; /*115200*/ /*div - 2*43*/
		
		
		#1000000 
		if (error_cnt > 0) begin
			$display("Sumlation FAILED!");
		end else begin
			$display("Simulation PASSED!");
		end
		$finish;

	end

	/*dump*/
	initial begin
		$dumpvars;
		$dumpfile("uart_dump.vcd");
	end

	/*write (in_dat) generator and driver*/
	initial begin
		in_vld <= 0;
		#350
		in_vld <= 1;
		for (int i = 0; i < n_writes; i++) begin
			in_dat[8] = 0;
			in_dat[7:0] = $urandom();

			@(posedge clk & in_rdy == 1);
		end
	end


	/*monitor in_dat_part*/
	initial begin
		for (int i = 0; i < n_writes; i++) begin
			@(posedge clk & in_vld == 1 & in_rdy == 1)
			in_dat_buffer[i] = in_dat;
			/*parity*/
			if (n_parity_bits == 1) begin
				in_overhead_buffer[i][2] = ^in_dat;
			end else begin
				in_overhead_buffer[i][2] = 0;
			end
			
			/*stop bits*/
			if (n_stop_bits == 2) begin 
				in_overhead_buffer[i][1:0] = 2'b11;
			end else 
				in_overhead_buffer[i][1:0] = 2'b10;
			end

		end
	end

	/*monitor in tx part*/
	initial begin
		@(tx == 1);
		for (int i = 0; i < n_writes; i++) begin 
			@(posedge external_clk & tx == 0);
			for (int i = 0; i < n_data_bits; i++) begin
				@(posedge external_clk);
				tx_dat_buffer[i] = tx;
			end
			for (int i = 0; i < n_parity_bits+n_stop_bits; i++) begin
				@(posedge external_clk);
				tx_overhead_buffer[i] = tx;
			end
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
            		$display("T=%0t [Scoreboard] PASS! addr = 0x%0h", $time, sc_i);
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
		#100000	
		if(sc_i < n_writes-1) begin
    		$display("T=%0t [Scoreboard] ERROR! Not all data has been captured. Captured frames: %0d", $time, sc_i);
			error_cnt = error_cnt + 1;
		end
	end
	

endmodule


