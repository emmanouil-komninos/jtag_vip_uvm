`ifndef JTAG_AGENT__SVH
 `define JTAG_AGENT__SVH

class jtag_agent extends uvm_agent;
  
  jtag_driver jtag_drv;
  jtag_sequencer jtag_seqr;

  jtag_collector jtag_col;
  jtag_monitor jtag_mon;
  
  jtag_agent_config jtag_agent_cfg;

  `uvm_component_utils_begin(jtag_agent)
  `uvm_field_object(jtag_agent_cfg, UVM_DEFAULT)
  `uvm_component_utils_end
    
    function new (string name, uvm_component parent);
      super.new(name,parent);
    endfunction // new

  function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    
    if (jtag_agent_cfg == null)
      begin
        `uvm_info("JTAG_AGENT_INFO", " Creating configuration", UVM_LOW)
        jtag_agent_cfg = jtag_agent_config::type_id::create("jtag_agent_cfg");
        if (!jtag_agent_cfg.randomize())
          `uvm_fatal("JTAG_AGENT_FATAL", "Randomization of jtag_agent_cfg failed")
        // jtag_agent_cfg.print();
        // jtag_agent_cfg.jtag_drv_cfg.print();
      end
    else
      `uvm_info("JTAG_AGENT_INFO", " Agent used auto config", UVM_LOW)
    
    if (jtag_agent_cfg.is_active == UVM_ACTIVE)
      begin
        `uvm_info("JTAG_AGENT_INFO", "Agent is active... building drv and seq", UVM_LOW)
        
        uvm_config_db#(uvm_object)::set(this,"jtag_drv","jtag_drv_cfg", jtag_agent_cfg.jtag_drv_cfg);

        // the existance of vif can be checked in build phase since it is top down.
        // That way we avoid driver errors in connect phase that is bottopm up
        if(uvm_config_db#(jtag_vif)::exists(this, get_full_name(), "jtag_virtual_if"))
          begin
            `uvm_info("JTAG_AGENT_INFO","VIF EXISTS IN CONFIG DB",UVM_LOW)
          end
        else
            `uvm_fatal("JTAG_AGENT_FATAL", {"VIF must exist for: ", get_full_name()})
        
        jtag_drv = jtag_driver::type_id::create("jtag_drv",this);
        jtag_seqr = jtag_sequencer::type_id::create("jtag_seqr",this);
      end 
    
    jtag_col = jtag_collector::type_id::create("jtag_col",this);
    jtag_mon = jtag_monitor::type_id::create("jtag_mon",this);
    
  endfunction // build_phase

  function void connect_phase (uvm_phase phase);
    super.connect_phase(phase);
    
    `uvm_info("JTAG_AGENT_INFO", "Agent connect phase", UVM_LOW)
    if (jtag_agent_cfg.is_active == UVM_ACTIVE)
      begin
        `uvm_info("JTAG_AGENT_INFO", "Agent is active... connecting drv and seq", UVM_LOW)
        jtag_drv.seq_item_port.connect(jtag_seqr.seq_item_export);
      end
    
  endfunction // connect_phase
  
  // function void end_of_elaboration_phase (uvm_phase phase);
  //   print();
  // endfunction // end_of_elaboration_phase  
endclass // jtag_agent

`endif
