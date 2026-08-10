#!/bin/bash
iverilog -o sim_cdc_fifo_8d.vvp tb_cdc_fifo_8d.v cdc_fifo_8d.v cdc_2ff.v
vvp sim_cdc_fifo_8d.vvp
gtkwave sim_cdc_fifo_8d.vcd
