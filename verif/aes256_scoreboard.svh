import uvm_pkg::*;
`include "aes256_inc.svh"

class aes256_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(aes256_scoreboard)
    uvm_analysis_imp#(aes256_seq_item, aes256_scoreboard) item_imp;
    int unsigned num_items = 0;

    function new(string name = "aes256_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        item_imp = new("item_imp", this);
    endfunction

    function write(aes256_seq_item item);
        `uvm_info(get_type_name(), $sformatf("Received item\n%s", item.sprint()), UVM_MEDIUM)
        num_items++;
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(), $sformatf("Number of items received: %0d", num_items), UVM_MEDIUM)
    endfunction
    
endclass
