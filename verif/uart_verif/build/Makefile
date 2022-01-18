VP=$(PRMCU_PATH)/verif/uart_verif
SP=$(PRMCU_PATH)/src/prmcu_uart
VERIFFILES=$(wildcard $(VP)/*.sv)
SOURCEFILES=$(wildcard $(SP)/*.vhd) $(SP)/build/design.o



src: $(SOURCEFILES)
	cd $(SP)/build make all 

test: $(VERIFFILES)
	iverilog -g2012 -o build  $(SP)/prmcu_uart_top.vhd $(VP)/uart_tb.sv
	vvp build
	gtkwave dump.vcd

all: src test 

