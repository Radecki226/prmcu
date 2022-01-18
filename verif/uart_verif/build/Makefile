VP=$(PRMCU_PATH)/verif/uart_verif
SP=$(PRMCU_PATH)/src/prmcu_uart
VERIFFILES=$(wildcard $(VP)/*.sv)
SOURCEFILES=$(wildcard $(SP)/*.vhd)



src: $(SOURCEFILES)
	iverilog -g2012 -o dut -c $(SP)/prmcu_uart.f

test: $(VERIFFILES)
	iverilog -g2012 -o build -s dut  $(VP)/uart_tb.sv
	vvp build
	gtkwave dump.vcd

all: src test 

