class monitor;
	uart_if uif;
	uart_item item_dat_in, item_tx;
	/*first mailbox for input(in_dat), second for output(tx)*/
	mailbox scb_mbx_tx, scb_mbx_in_dat;
	
	task run();
		$display("T=%0t [Monitor] starting ...", $time);
		fork
			sample_port_dat_in();
			sample_port_tx();
		join_any
	endtask

	task sample_port_dat_in(string tag = "");
		forever begin
			@(posedge uif.clk);
			/*when axi handshake takes place transaction is happening*/
			if(!uif.rst & uif.in_vld & uif.in_rdy) begin
				item_in_dat = new;
				item.in_dat = uif.in_dat;
				item.in_overhead[2] = uif.n_parity_bits;
				item.in_overhead[1:0] = uif.n_stop_bits;
				$display("T=%0t [Monitor] %s in dat reception completed", $time, tag);
				scb_mbx_in_dat.put(item);
				item.print("Monitor in dat");
			end
		end
	endtask

	task sample_port_tx(string tag="");
		forever begin 
			@(posedge uif.internal_clk);
			/*when start bit detected start transmission*/
			if (!uif.rst & !uif.tx) begin
				//bit[8:0] tx_data_buffer = 0;
				//bit[1:0] tx_stop_buffer = 0;
				//bit      tx_parity_buffer = 0;
				//item_tx = new;
				@posedge(uif.internal_clk);
				/*get correcnt number of bits to buffer*/
				//int i = 0;
				//repeat(int(uif.n_data_bits)) begin
				//	@posedge(uif.internal_clk);
				//	tx_buffer[i] = uif.tx;
				//end
				/*
				for (int i = 0; i < uif.n_parity_bits; i++) begin
					@posedge(uif.internal_clk);
					tx_parity_buffer = uif.tx;
				end
				for (int i = 0; i < uif.n_stop_bits; i++) begin
					@posedge(uif.internal_clk);
					tx_stop_buffer[i] = uif.tx;
				end

				item.tx = tx_data_buffer;
				item.tx_overhead = {tx_parity_buffer,tx_stop_buffer}; 
				$display("T=%0t [Monitor] %s Tx reception completed", $time, tag);


				scb_mbx_tx.put(item);
				item.print("Monitor_tx");
				*/
			end
		end
	endtask


