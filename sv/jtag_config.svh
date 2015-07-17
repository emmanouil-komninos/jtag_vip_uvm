`ifndef JTAG_CONFIG__SVH
 `define JTAG_CONFIG__SVH

class jtag_driver_config extends uvm_object;

  rand logic [0:3] instr_sz;
  rand logic [0:7] data_sz;
  
  `uvm_object_utils_begin(jtag_driver_config)
  `uvm_field_int(instr_sz, UVM_DEFAULT)
  `uvm_field_int(data_sz, UVM_DEFAULT)
  `uvm_object_utils_end

    constraint c_instr_sz {instr_sz == 3;}
  constraint c_data_sz {data_sz == 3;}
  
  function new (string name = "jtag_drviver_cfg");
    super.new(name);
  endfunction // new
  
endclass // jtag_drviver_cfg

class jtag_agent_config extends uvm_object;
  
  rand uvm_active_passive_enum is_active;
  rand jtag_driver_config jtag_drv_cfg;

  `uvm_object_utils_begin(jtag_agent_config)
  `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_DEFAULT)
  `uvm_field_object(jtag_drv_cfg, UVM_DEFAULT)
  `uvm_object_utils_end

    constraint c_is_active {is_active == UVM_PASSIVE;}
  
    function new (string name = "jtag_agent_config");
      super.new(name);
      jtag_drv_cfg = jtag_driver_config::type_id::create("jtag_drv_cfg");
    endfunction // new
  
endclass // jtag_agent_config

class jtag_agent_config_active extends jtag_agent_config;
  
  `uvm_object_utils(jtag_agent_config_active)
  constraint c_is_active {is_active == UVM_ACTIVE;} 
   
  function new (string name = "jtag_agent_config_active");
    super.new(name);
    jtag_drv_cfg = jtag_driver_config::type_id::create("jtag_drv_cfg");
  endfunction // new
  
endclass // jtag_agent_config_active


class jtag_env_config extends uvm_object;

  rand jtag_agent_config jtag_agent_cfg;

  `uvm_object_utils_begin(jtag_env_config)
  `uvm_field_object(jtag_agent_cfg,UVM_DEFAULT)
  `uvm_object_utils_end

    function new (string name = "jtag_env_config");
      super.new(name);
      jtag_agent_cfg = jtag_agent_config::type_id::create("jtag_agent_cfg");
    endfunction // new
endclass // jtag_env_config

      
`endif
