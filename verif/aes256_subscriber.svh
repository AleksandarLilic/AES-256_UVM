import uvm_pkg::*;
`include "aes256_inc.svh"

`ifndef AES256_SUBSCRIBER_SVH
`define AES256_SUBSCRIBER_SVH

class aes256_subscriber extends uvm_subscriber #(aes256_seq_item);
    `uvm_component_utils(aes256_subscriber)
    uvm_analysis_imp#(aes256_seq_item, aes256_subscriber) item_imp;
    uvm_event item_received;
    aes256_seq_item item;

    function new(string name = "aes256_subscriber", uvm_component parent = null);
        super.new(name, parent);
        item_imp = new("item_imp", this);
        item_received = new("item_received");
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        item = aes256_seq_item::type_id::create("item");
    endfunction

    virtual function void write(aes256_seq_item t);
        `uvm_info(get_type_name(), $sformatf("Received item\n%s", t.sprint()), UVM_HIGH)
        this.item = t;
        item_received.trigger();
    endfunction
endclass

`endif
