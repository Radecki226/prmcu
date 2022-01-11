class env;
	driver     d0;
	monitor    m0;
	generator  g0;
	scoreboard s0;

	mailbox drv_mailbox;
	mailbox scb_mbx_in_dat, scb_mbx_tx;
	
	event drv_done;

	virtual uart_if uif;

	function new(int n_iter);
		d0 = new;
		m0 = new;
		g0 = new(n_iter);
		s0 = new(n_iter);
		drv_mbx = new();
		scb_mbx_in_dat = new();
		scb_mbx_tx = new();

		d0.drv_mbx = drv_mbx;
		g0.drv_mbx = drv_mbx;
		m0.scb_mbx_in_dat = scb_mbx_in_dat;
		m0.scb_mbx_tx = scb_mbx_tx;

		d0.drv_done = drv_done;
		g0.drv_done = drv_done;

	endfunction
	
	virtual task run();
		d0.uif = uif;
		m0.uif = uif;

		fork 
			d0.run();
			m0.run();
			g0.run();
			s0.run();
		join_any
	endtask
endclass

