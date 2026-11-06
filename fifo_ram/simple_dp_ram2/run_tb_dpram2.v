#!/usr/bin/bash
iverilog -o sim_dpram2.vvp tb_dpram2.v dpram2.v
vvp sim_dpram2.vvp
gtkwave sim_dpram2.vcd
