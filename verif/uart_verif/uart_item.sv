class uart_item;
	rand bit [8:0] in_dat;
	bit      [2:0] in_overhead; //parity + stop
	bit      [8:0] out_dat;
	rand bit [8:0] rx; //only data bits
	bit      [8:0] tx; //data plus overhead(up to 9+1+2)
	bit      [2:0] tx_overhead;     


	function void print(string tag = "");
		$display("T=%0t %s in_dat=0x%0h out_dat=0x%0h tx=0x%0h rx=0x%0h", 
                 $time, tag, in_dat, out_dat, rx, tx);
	endfunction
    
endclass
