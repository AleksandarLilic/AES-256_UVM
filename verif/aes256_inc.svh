`ifndef _AES256_INC_SVH
`define _AES256_INC_SVH

// Consts
const shortint unsigned LOADING_CYCLES = 16; // takes 16 clocks to load one ciphertext block
const shortint unsigned KEY_EXP_CYCLES = 84; // takes 84 clocks to expand one key
const shortint unsigned ENC_CYCLES = 58; // takes 58 clocks to encrypt one plaintext block
const shortint unsigned KEY_EXP_TIMEOUT_CLOCKS = KEY_EXP_CYCLES + 2;
const shortint unsigned ENC_TIMEOUT_CLOCKS = ENC_CYCLES + 2;
const shortint unsigned MAX_START_DELAY = LOADING_CYCLES;

// Enums
typedef enum bit { FALSE = 0, TRUE = 1 } bool_t;
typedef enum bit { UVM_PASSIVE = 0, UVM_ACTIVE = 1 } uvm_active_passive_enum;
typedef enum bit [1:0] {
    EXP_NO_DELAY = 0,
    EXP_WITH_DELAY = 1,
    EXP_RANDOM = 2
} exp_delay_mode_t;
typedef enum bit [2:0] {
    ENC_NO_DELAY = 0,
    ENC_WITH_DELAY = 1,
    ENC_OVERLAP_W_LOADING = 2,
    ENC_WAIT_FOR_LOADING_END = 3,
    ENC_RANDOM = 4
} enc_delay_mode_t;

// Macros
`define SEND_ITEM(item, print) \
    start_item(item); \
    if (print == 1) \
        `uvm_info(get_type_name(), $sformatf("\n%s", item.sprint()), UVM_HIGH); \
    finish_item(item);

//`define SEND_ITEM_RAND(item) \
//    start_item(item); \
//    assert(item.randomize()) \
//    else `uvm_fatal(get_type_name(), "Randomization failed"); \
//    `uvm_info(get_type_name(), $sformatf("\n%s", item.sprint()), UVM_HIGH); \
//    finish_item(item);
//
//`define SEND_ITEM_RAND_WITH(item, constraint) \
//    start_item(item); \
//    assert(item.randomize() with constraint) \
//    else `uvm_fatal(get_type_name(), "Randomization failed"); \
//    `uvm_info(get_type_name(), $sformatf("\n%s", item.sprint()), UVM_HIGH); \
//    finish_item(item);

`endif
