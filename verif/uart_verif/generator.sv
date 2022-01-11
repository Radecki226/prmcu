class generator;
    mailbox drv_mailbox;
    event drv_done;
	int size;

	function new(int size);
		size = size;
	endfunction 

	task run_transmit();
		for (int i = 0 ; i < size ; i++) begin
			uart_item item = new;
			item.randomize();
			$display("T=%0t [Generator] Loop:%0d%0d create next item", $time, i+1, num);
			drv_mbx.put(item);
			@(drv_done);
		end;
		$display("T=%0t [Generator] Done generation of %0d items", $time, num);
	endtask
endclass
