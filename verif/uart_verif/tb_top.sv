module tb
	reg clk;
	
	always #10 clk ~= clk;
	uart_if _if(clk);
	uart_top u0(
		.clk(clk),
		.internal_clk_o(_if.internal_clk),
		.rst(_if.rst),

		.uart_en(_if.uart_en),
		.tx_en(_if.tx_en),
		.rx_en(_if.rx_en),
		.n_parity_bits(_if.n_parity_bits),
		.n_stop_bits(_if.n_stop_bits),
		.internal_clk_divider(_if.internal_clk_divider),

		.in_dat_i(_if.in_dat),
		.in_vld_i(_if.in_vld),
		.in_rdy_o(_if.in_rdy),

		.out_dat_o(_if.out_dat),
		.out_vld_o(_if.out_vld),
		.out_rdy_i(_if.out_rdy),

		.tx_o(_if.tx),
		.rx_i(_if.rx)
	);

	test t0;
	
	initial begin
		clk <= 0;
		_if.rst <= 1;
		#20 _if.rst <= 0;
		t0 = new;
		t0.e0.uif = _if;
		t0.run(20);

		#200 $finish;
	end
	
	initial begin
		$dumpvars;
		$dumpfile ("uart_dump.vcd");
	end

endmodule
