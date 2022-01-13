class uart_if;
	
	logic       clk;
	logic       internal_clk;
	logic       rst;

	logic       uart_en;
	logic       tx_en;
	logic       rx_en;
	logic       n_parity_bits;
	logic [1:0] n_stop_bits;
	logic [3:0] n_data_bits;
	logic [7:0] internal_clk_divider;
	
	logic [8:0] in_dat;
	logic       in_vld;
	logic       in_rdy;

	logic [8:0] out_dat;
	logic       out_vld;
	logic       out_rdy;

	logic       tx;
	logic       rx;
endclass
