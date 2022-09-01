library ieee;
use ieee.std_logic_1164.all;


entity axi_stream_fifo is
  generic (
    WIDTH : integer := 32;
	  DEPTH : integer := 128
  );
  port (
    clk         : in std_logic;
	  rst         : in std_logic;

    in_dat_i    : in std_logic_vector(WIDTH-1 downto 0);
    in_vld_i    : in std_logic;
    in_rdy_o    : out std_logic;

    out_dat_o   : out std_logic_vector(WIDTH-1 downto 0);
    out_vld_o   : out std_logic;
    out_rdy_i   : in  std_logic

  );
 end axi_stream_fifo;

architecture rtl of axi_stream_fifo is

type ram_type is array (0 to DEPTH - 1) of std_logic_vector(WIDTH-1 downto 0);
signal ram : ram_type;

  subtype idx_t is natural range 0 to DEPTH-1;
  signal head_r  : idx_t;
  signal tail_r  : idx_t;
  signal count_c : idx_t;
  signal count_r : idx_t;

  signal in_rdy_c  : std_logic;
  signal out_dat_r : std_logic_vector(WIDTH-1 downto 0);
  signal out_vld_c : std_logic;

  signal read_while_write_r : std_logic;

  function next_index(
    idx : idx_t;
    rdy : std_logic;
    vld : std_logic) return idx_t is begin
    if rdy = '1' and vld = '1' then
      if idx = DEPTH-1 then
        return 0;
      else
        return idx + 1;
      end if;
    end if;
    return idx;
  end function;


begin


head_update_p : process(clk) begin
  if rising_edge(clk) then
		head_r <= next_index(head_r, in_rdy_c, in_vld_i);

		if rst = '1' then
			head_r <= 0;
		end if;
	end if;
end process;


tail_update_p : process(clk) begin
  if rising_edge(clk) then
		tail_r <= next_index(tail_r, out_rdy_i, out_vld_c);

		if rst = '1' then
			tail_r <= 0;
		end if;
	end if;
end process;

ram_p : process(clk) begin
  if rising_edge(clk) then
    -- If there is read from fifo next index must be prepared
    ram(head_r) <= in_dat_i;
    out_dat_r <= ram(next_index(tail_r, out_rdy_i, out_vld_c));
  end if;
end process;

count_p : process(head_r, tail_r) begin
  if head_r < tail_r then
    count_c <= head_r - tail_r + DEPTH;
  else
    count_c <= head_r - tail_r;
  end if;
end process;

count_r_p : process(clk) begin
  if rising_edge(clk) then
    count_r <= count_c;

    if rst = '1' then
      count_r <= 0;
    end if;

  end if;
end process;

in_rdy_p : process(count_c) begin
  if count_c < DEPTH-1 then
    in_rdy_c <= '1';
  else
    in_rdy_c <= '0';
  end if;
end process;

read_while_write_last_cycle_p : process(clk) begin
  if rising_edge(clk) then

    read_while_write_r <= '0';
    if in_rdy_c = '1' and in_vld_i = '1' and out_rdy_i = '1' and out_vld_c = '1' then
      read_while_write_r <= '1';
    end if;

    if rst = '1' then
      read_while_write_r <= '0';
    end if;
  end if;
end process;


out_vld_p : process(count_c, count_r, read_while_write_r) begin
  out_vld_c <= '1';

  if count_c = 0 or count_r = 0 then
    out_vld_c <= '0';
  end if;

  if count_c = 1 and read_while_write_r = '1' then
    out_vld_c <= '0';
  end if;

end process;

out_dat_o <=  out_dat_r;
out_vld_o <= out_vld_c;
in_rdy_o <= in_rdy_c;

end rtl;
