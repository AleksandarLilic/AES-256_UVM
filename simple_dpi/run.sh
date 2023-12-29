#!/bin/bash -xvf
xsc functions.c 
xvlog -svlog top_module.sv inc_module.sv
xelab work.top_module -sv_lib dpi -R
