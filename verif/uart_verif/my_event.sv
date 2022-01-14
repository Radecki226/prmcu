class my_event;
	int trigerred = 0;
	task trigger();
		if (trigerred == 0) begin
			trigerred = 1;
		end
	endtask

	task receive();
		@(trigerred == 1);
		trigerred = 0;
	endtask
endclass
