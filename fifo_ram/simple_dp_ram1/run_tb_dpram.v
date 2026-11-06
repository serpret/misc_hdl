#!/usr/bin/bash
iverilog -o sim_dpram.vvp tb_dpram.v dpram.v
vvp sim_dpram.vvp
gtkwave sim_dpram.vcd
