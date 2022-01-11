class driver;
	virtual uart_if uif;
	event drv_done;
	mailbox drv_mbx;

	task run_transmit();
		$display("T=%0t [Driver] starting transmitting....", $time);
		@(posedge uif.clk);



		forever begin
			uart_item item;
			$diplay("T=%0t [Driver] waiting for item...", $time);
			drv_mbx.get(item);
			item.print("Driver");
			uif.uart_en <= 1;
			uif.tx_en <= 1;
			uif.rx_en <= 0;
			uif.n_parity_bits <= 0;
			uif.n_stop_bits <= 1;
			uif.n_data_bits <= 8;
			uif.internal_clk_divider <= 64;
			uif.in_dat <= item.in_dat[8-1:0];
			uif.in_vld <= 1;
			uif.out_rdy <= 1;
			uif.rx <= item.rx;
			
			/*wait for ready*/
			while(!uif.in_rdy)

			@(posedge uif.clk);
			uif.vld <= 0; -> drv_done; 
		end
	end task
end class

