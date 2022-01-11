class scoreboard;
	mailbox scb_mbx_in_dat, scb_mbx_tx;

	bit [8:0] in_dat_buffer [];
	bit [2:0] in_overhead_buffer [];
	bit [8:0] tx_dat_buffer [];
	bit [2:0] tx_overhead_buffer [];
	int error_cnt;
	
	function new(int size);
		in_dat_buffer = new(size);
		in_overhead_buffer = new(size);
		tx_dat_buffer = new(size);
		tx_overhead_buffer = new(size);
		error_cnt = 0;
	endfunction

	task run();
		fork
			save_reference();
			compare_data();
		join_any
	endtask

	task save_reference();
		int i = 0;
		forever begin
			uart_item item;
			scb_mbx_in_dat.get(item);
			in_dat_buffer[i] = item.in_dat;
			in_overhead_buffer[i] = item.in_overhead;
			i = i + 1;
		end
	endtask

	task compare_data();
		int i = 0;
		forever begin
			uart_item item;
			scb_mbx_tx.get(item);
			tx_dat_buffer[i] = item.tx_data;
			tx_overhead_buffer[i] = item.tx_overhead;
			if (tx_dat_buffer[i] == in_dat_buffer[i]) begin
				if (tx_overhead_buffer[i] == in_overhead_buffer[i]) begin
					$display("T=%0t [Scoreboard] PASS! addr = 0x%0h", $time, i);
				end else
					$display("T=%0t [Scoreboard] ERROR! overhead mismatch addr = 0x%0h expected = %0b received = %0b",
					         $time, i, in_overhead_buffer, tx_overhead_buffer);
					error_cnt = error_cnt + 1;
				end
			end else
				$display("T=%0t [Scoreboard] ERROR! data mismatch addr = 0x%0h expected = 0x%0h received = 0x%0h",
				         $time, i, in_data_buffer, tx_data_buffer);
			end

			i = i + 1;
		end
	endtask

