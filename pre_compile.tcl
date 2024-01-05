# this script should be set to run as xsim.compile.tcl.pre
puts "Starting tcl pre script"

set project_root ../../../../ ; # from the point of the simulation directory
set model_dir aes-256_model
set model_path $project_root/$model_dir

# from reporoot: ./aes256_uvm.sim/sim_1/behav/xsim/proj_dpi.so
set dpi_output_name aes_dpi.so

if {[file exists $dpi_output_name]} {
    file delete $dpi_output_name
}

set aes_source $model_path/aes.c
set aes_dpi $model_path/aes_dpi.c

exec sh -c "xsc $aes_dpi $aes_source -o $dpi_output_name"

puts "Finished tcl pre script"
