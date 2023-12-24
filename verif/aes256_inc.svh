`ifndef _AES256_INC_SVH
`define _AES256_INC_SVH

// Enums
typedef enum {NOT_READY, EXPANDED} key_state_t;
typedef enum {FALSE, TRUE} bool_t;

// Macros
`define SEND_ITEM(item, print) \
    start_item(item); \
    if (print) \
        `uvm_info(get_type_name(), $sformatf("\n%s", item.sprint()), UVM_MEDIUM); \
    finish_item(item);

`define SEND_ITEM_RAND(item) \
    start_item(item); \
    assert(item.randomize()); \
    `uvm_info(get_type_name(), $sformatf("\n%s", item.sprint()), UVM_MEDIUM); \
    finish_item(item);

`define SEND_ITEM_RAND_WITH(item, constraint) \
    start_item(item); \
    assert(item.randomize() with constraint); \
    `uvm_info(get_type_name(), $sformatf("\n%s", item.sprint()), UVM_MEDIUM); \
    finish_item(item);

`endif
