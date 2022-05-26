# Repository for rtl implementations of various archicecture components


## Uart

Uart implementation is test of icarius verilog software for rtl simulation.
### Steps
- PRMCU_PATH variable must be set to local_path/prmcu \
- frame structure -> data have width 5-9 and is located on lsb \
- make all NAME=uart_transmitter_tb FLAGS="-DN_BITS=6 -DTEST=20 -DRECV_RATE=115000"
