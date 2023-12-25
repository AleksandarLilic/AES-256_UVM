import uvm_pkg::*;
`include "aes256_inc.svh"
`include "aes256_agent.svh"

class aes256_env extends uvm_env;
    `uvm_component_utils(aes256_env)
    aes256_agent agent_1;
    aes256_cfg cfg;

    function new (string name = "aes256_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(aes256_cfg)::get(this, "", "aes256_cfg", cfg))
            `uvm_fatal(get_full_name(),"Config not found")
        uvm_config_db#(aes256_cfg)::set(this, "agent_1", "aes256_cfg", cfg);
        agent_1 = aes256_agent::type_id::create("agent_1", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction

endclass
