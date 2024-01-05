import uvm_pkg::*;
`include "aes256_inc.svh"

import "DPI-C" function void aes_dpi(input byte unsigned key[32],
                                     input byte unsigned plaintext[16],
                                     output byte unsigned ciphertext[16]);

class aes256_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(aes256_scoreboard)
    uvm_analysis_imp#(aes256_seq_item, aes256_scoreboard) item_imp;
    
    int unsigned num_items = 0;
    byte unsigned key_bytes[32];
    byte unsigned plaintext_bytes[16];
    byte unsigned ciphertext_bytes[16];
    int unsigned error_count = 0;
    int unsigned error_count_total = 0;

    function new(string name = "aes256_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        item_imp = new("item_imp", this);
    endfunction

    function write(aes256_seq_item item);
        `uvm_info(get_type_name(), $sformatf("Received item\n%s", item.sprint()), UVM_HIGH)
        num_items++;

        // format sequence item data as byte arrays
        for (int i = 0; i < 32; i++) key_bytes[i] = item.master_key[(31-i)*8 +: 8];
        for (int i = 0; i < 16; i++) plaintext_bytes[i] = item.data_in[(15-i)*8 +: 8];
        
        // run model
        aes_dpi(key_bytes, plaintext_bytes, ciphertext_bytes);
        
        // compare results
        error_count = 0;
        for (int i = 0; i < 16; i++) begin
            assert(ciphertext_bytes[i] == item.data_out[15-i]) else begin
                `uvm_error(get_type_name(), $sformatf("Ciphertext byte %0d mismatch: expected %0h, received %0h", i, ciphertext_bytes[i], item.data_out[15-i]))
                error_count++;
            end
        end
        
        if (error_count == 0) begin
            `uvm_info(get_type_name(), "Ciphertext matched", UVM_HIGH)
        end else begin
            `uvm_error(get_type_name(), $sformatf("Ciphertext mismatched %0d bytes", error_count))
            `uvm_info(get_type_name(), $sformatf("Entire packet:\n%s", item.sprint()), UVM_NONE)
        end
        error_count_total += error_count;
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(), $sformatf("Number of items received: %0d", num_items), UVM_NONE)
        if (error_count_total == 0) begin
            `uvm_info(get_type_name(), "\n\n==== PASS ====\n\n", UVM_NONE)
        end else begin
            `uvm_info(get_type_name(), $sformatf("Total number of errors: %0d", error_count_total), UVM_NONE)
            `uvm_fatal(get_type_name(), "\n\n==== FAIL ====\n\n")
        end
    endfunction
    
endclass
