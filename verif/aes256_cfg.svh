import uvm_pkg::*;
`include "aes256_inc.svh"

class aes256_cfg extends uvm_object;

uvm_active_passive_enum mode = UVM_ACTIVE;
// UVM_PASSIVE is not supported as there is other way to drive the DUT

// TODO: consider adding switches for the following:
// - checkers (DPI or vectors?)
// - coverage (need to expose VHDL internals)

`uvm_object_utils_begin(aes256_cfg)
    `uvm_field_enum(uvm_active_passive_enum, mode, UVM_DEFAULT)
`uvm_object_utils_end

function new (string name = "aes256_cfg");
    super.new(name);
endfunction

endclass
