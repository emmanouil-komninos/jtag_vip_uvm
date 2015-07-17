`ifndef JTAG_ENV__SVH
 `define JTAG_ENV__SVH

class jtag_env extends uvm_env;
  jtag_agent jtag_agnt;
  jtag_env_config jtag_env_cfg;
  
  `uvm_component_utils_begin(jtag_env)
  `uvm_field_object(jtag_env_cfg,UVM_DEFAULT)
  // `uvm_field_object(jtag_agnt,UVM_DEFAULT)
  `uvm_component_utils_end
    
  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction // new

  function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    if (jtag_env_cfg == null)
      begin
        `uvm_info("JTAG_ENV_INFO","Empty env configuration",UVM_LOW)
        jtag_env_cfg = jtag_env_config::type_id::create("jtag_env_cfg");
        
        if(!jtag_env_cfg.randomize())
          `uvm_fatal("JTAG_ENV_FATAL","Randomization env configuration failed")
      end
    
    uvm_config_db#(uvm_object)::set(this,"jtag_agnt","jtag_agent_cfg",jtag_env_cfg.jtag_agent_cfg);
    jtag_agnt = jtag_agent::type_id::create("jtag_agnt", this);
  endfunction // build_phase
  
  function void end_of_elaboration_phase (uvm_phase phase);
    print();
  endfunction // end_of_elaboration_phase

endclass // jtag_env

`endif
