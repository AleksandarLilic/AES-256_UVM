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

`define SEND_ITEM_RAND_WITH(item, constraint) \
    start_item(item); \
    assert(item.randomize() with constraint); \
    `uvm_info(get_type_name(), $sformatf("\n%s", item.sprint()), UVM_MEDIUM); \
    finish_item(item);

`define ADD_WAIT_AT_THE_END(cnt1, chk1, cnt2, chk2, item) \
    if (cnt1 == chk1 && cnt2 == chk2) \
        item.wait_at_the_end = 10;

`endif
