class mailbox; 
	int loaded=0;
	int done=0;
	uart_item transaction_obj;
	task put(input uart_item obj);
		@(loaded == 0 & done == 0);
		transaction_obj = obj;
		loaded = 1;
		@(done == 1);
		done = 0;
		loaded = 0;
	endtask

	task get(input uart_item obj);
		@(loaded == 1)
		obj = transacion_obj;
		done = 1;
	endtask
endclass
