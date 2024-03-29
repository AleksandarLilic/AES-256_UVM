`ifndef _AES256_INC_SVH
`define _AES256_INC_SVH

// Design consts
`define MATRIX_DATA_WIDTH 128
`define MATRIX_ROUND_KEY_WIDTH 128
`define MATRIX_KEY_WIDTH 256
`define WORD_WIDTH 32
`define N_ROUNDS 15

// Consts
const shortint unsigned LOADING_CYCLES = 16; // takes 16 clocks to load one ciphertext block
const shortint unsigned KEY_EXP_CYCLES = 84; // takes 84 clocks to expand one key
const shortint unsigned ENC_CYCLES = 58; // takes 58 clocks to encrypt one plaintext block
const shortint unsigned KEY_EXP_TIMEOUT_CLOCKS = KEY_EXP_CYCLES + 2;
const shortint unsigned ENC_TIMEOUT_CLOCKS = ENC_CYCLES + 2;
const shortint unsigned MAX_START_DELAY = LOADING_CYCLES;

// design FSMs
typedef enum bit {
    FSM_LOADING_IDLE = 0,
    FSM_LOADING_LOADING = 1
} loading_fsm_t;
typedef enum bit [2:0] {
    EXP_FSM_IDLE = 0,
    EXP_FSM_KEY_PARSER = 1,
    EXP_FSM_ROT_WORD = 2,
    EXP_FSM_SUB_WORD = 3,
    EXP_FSM_RCON = 4,
    EXP_FSM_XOR_WE = 5
} exp_fsm_t;
typedef enum bit [2:0] {
    ENC_FSM_IDLE = 0,
    ENC_FSM_SUB_BYTES = 1,
    ENC_FSM_SHIFT_ROWS = 2,
    ENC_FSM_MIX_COLUMNS = 3,
    ENC_FSM_ADD_ROUND_KEY = 4
} enc_fsm_t;

// Coverage consts
const bit [31:0] CP_32_MAX = 32'hFFFF_FFFF;
const bit [127:0] CP_128_MAX = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
const bit [255:0] CP_256_MAX = 256'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;

// Enums
typedef enum bit { FALSE = 0, TRUE = 1 } bool_t;
typedef enum bit { UVM_PASSIVE = 0, UVM_ACTIVE = 1 } uvm_active_passive_enum;
typedef enum bit [2:0] {
    EXP_NO_DELAY = 0,
    EXP_WITH_DELAY = 1,
    EXP_WITH_DELAY_LTL = 2, // LTL = Less Than Loading
    EXP_RANDOM = 3,
    EXP_RANDOM_LONG_PULSE = 4
} exp_delay_mode_t;
typedef enum bit [2:0] {
    ENC_NO_DELAY = 0,
    ENC_WITH_DELAY = 1,
    ENC_OVERLAP_W_LOADING = 2,
    ENC_WAIT_FOR_LOADING_END = 3,
    ENC_RANDOM = 4,
    ENC_RANDOM_LONG_PULSE = 5
} enc_delay_mode_t;
typedef enum bit [1:0] {
    SWEEP_TYPE_NONE = 0,
    SWEEP_TYPE_KEY = 1,
    SWEEP_TYPE_PT = 2
} sweep_type_t;

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

`define PRINT_SCBD_ERROR(msg) \
    `uvm_error(get_type_name(), msg); \
    `uvm_info(get_type_name(), $sformatf("Entire packet:\n%s", item.sprint()), UVM_NONE)

`define DEFAULT_CONSTRAINTS \
    number_of_keys == num_keys; \
    number_of_plaintexts == num_pts; \
    exp_delay_mode == EXP_NO_DELAY; \
    enc_delay_mode == ENC_NO_DELAY; \
    wait_period_at_the_end == 20;

`define SEND_DEFAULT_SEQ \
    assert(seq.randomize() with {`DEFAULT_CONSTRAINTS}) \
    else `uvm_fatal(get_type_name(), "Randomization failed"); \
    env.scbd.num_expected_items += num_items(); \
    seq.start(env.agent_1.sequencer_1);

`endif
