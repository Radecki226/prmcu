class mailbox; 
	int loaded=0;
	int done=0;
	uart_item transaction_obj;
	task put(input uart_item obj);
		transaction_obj = obj;
		loaded = 1;
		@(done == 1);
		loaded = 0;
	endtask

	task get(input uart_item obj);
		done = 0;
		@(loaded == 1)
		obj = transacion_obj;
		done = 1;
	endtask
endclass
