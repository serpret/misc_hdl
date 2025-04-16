#!/usr/bin/bash
ghdl -a --std=08 uart_tx.vhd
ghdl -a --std=08 uart_rx.vhd
ghdl -a --std=08 tb_uart.vhd
ghdl -e --std=08 tb_uart
ghdl -r --std=08 tb_uart --vcd=tb_uart.vcd --wave=tb_uart.ghw
gtkwave tb_uart.vcd waveforms.gtkw
