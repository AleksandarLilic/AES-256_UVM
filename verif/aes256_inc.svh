`ifndef _AES256_INC_SVH
`define _AES256_INC_SVH

// Consts
const shortint unsigned LOADING_CYCLES = 16; // takes 16 clocks to load one ciphertext block
const shortint unsigned KEY_EXP_CYCLES = 84; // takes 84 clocks to expand one key
const shortint unsigned ENC_CYCLES = 58; // takes 58 clocks to encrypt one plaintext block
const shortint unsigned KEY_EXP_TIMEOUT_CLOCKS = KEY_EXP_CYCLES + 2;
const shortint unsigned ENC_TIMEOUT_CLOCKS = ENC_CYCLES + 2;
const shortint unsigned MAX_START_DELAY = LOADING_CYCLES;

// FSMs
typedef enum bit [2:0] {
    ENC_FSM_IDLE = 0,
    ENC_FSM_SUB_BYTES = 1,
    ENC_FSM_SHIFT_ROWS = 2,
    ENC_FSM_MIX_COLUMNS = 3,
    ENC_FSM_ADD_ROUND_KEY = 4
} enc_fsm_t;

// Coverage consts
const bit [127:0] CP_128_MAX = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
const bit [255:0] CP_255_MAX = 256'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;


// Coverage enables
`define SUB_BYTES_EN DUT_aes256_if_i.key_ready && DUT_aes256_loading_wrap_i.enc_pr_state == ENC_FSM_SUB_BYTES
`define SHIFT_ROWS_EN DUT_aes256_if_i.key_ready && DUT_aes256_loading_wrap_i.enc_pr_state == ENC_FSM_SHIFT_ROWS
`define MIX_COLUMNS_EN DUT_aes256_if_i.key_ready && DUT_aes256_loading_wrap_i.enc_pr_state == ENC_FSM_MIX_COLUMNS
`define ADD_ROUND_KEY_EN DUT_aes256_if_i.key_ready && DUT_aes256_loading_wrap_i.enc_pr_state == ENC_FSM_ADD_ROUND_KEY

// Coverage macros
`define CP_128 \
    bins min = {'h0}; \
    bins range = {['h0:CP_128_MAX-1]}; \
    bins max = {CP_128_MAX}

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
