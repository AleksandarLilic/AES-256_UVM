`ifndef _AES256_INC_SVH
`define _AES256_INC_SVH

// Consts
const shortint unsigned LOADING_CYCLES = 16; // takes 16 clocks to load one ciphertext block
const shortint unsigned KEY_EXP_CYCLES = 84; // takes 84 clocks to expand one key
const shortint unsigned ENC_CYCLES = 58; // takes 58 clocks to encrypt one plaintext block
const shortint unsigned KEY_EXP_TIMEOUT_CLOCKS = KEY_EXP_CYCLES + 2; 
const shortint unsigned ENC_TIMEOUT_CLOCKS = ENC_CYCLES + 2; 

// Enums
typedef enum {NOT_READY, EXPANDED} key_state_t;
typedef enum {FALSE, TRUE} bool_t;

// Macros
`define SEND_ITEM(item, print) \
    start_item(item); \
    if (print == 1) \
        `uvm_info(get_type_name(), $sformatf("\n%s", item.sprint()), UVM_HIGH); \
    finish_item(item);

`define SEND_ITEM_RAND(item) \
    start_item(item); \
    assert(item.randomize()); \
    `uvm_info(get_type_name(), $sformatf("\n%s", item.sprint()), UVM_HIGH); \
    finish_item(item);

`define SEND_ITEM_RAND_WITH(item, constraint) \
    start_item(item); \
    assert(item.randomize() with constraint); \
    `uvm_info(get_type_name(), $sformatf("\n%s", item.sprint()), UVM_HIGH); \
    finish_item(item);

`endif
