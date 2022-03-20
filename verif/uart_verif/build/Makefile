VP=$(PRMCU_PATH)/verif/uart_verif
SP=$(PRMCU_PATH)/src/prmcu_uart
VERIFFILES=$(wildcard $(VP)/*.sv)
SOURCEFILES=$(wildcard $(SP)/*.vhd) $(SP)/build/design.o

all: $(VERIFFILES)
	iverilog -g2012 -o build $(VP)/$(NAME).sv -c $(SP)/prmcu_uart.f $(FLAGS)
	vvp build
ifeq ($(GUI),1)
	gtkwave uart_dump.vcd &
endif

