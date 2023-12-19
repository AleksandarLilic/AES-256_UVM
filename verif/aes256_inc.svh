`ifndef _AES256_INC_SVH
`define _AES256_INC_SVH
// Enums
typedef enum {NOT_READY, EXPANDED} key_state_t;

// Macros
`define SEND_ITEM_RAND(item) \
    start_item(item); \
    assert(item.randomize()); \
    `uvm_info(get_type_name(), $sformatf("\n%s", item.sprint()), UVM_MEDIUM); \
    finish_item(item);

`endif