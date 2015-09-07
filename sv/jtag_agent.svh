`ifndef JTAG_AGENT__SVH
 `define JTAG_AGENT__SVH

class jtag_agent extends uvm_agent;
  
  jtag_driver driver;
  jtag_sequencer sequencer;

  jtag_collector collector;
  jtag_monitor monitor;
  
  jtag_agent_config jtag_agent_cfg;

  `uvm_component_utils_begin(jtag_agent)
  `uvm_field_object(jtag_agent_cfg, UVM_DEFAULT)
  `uvm_component_utils_end
    
    function new (string name, uvm_component parent);
      super.new(name,parent);
    endfunction // new

  extern function void build_phase (uvm_phase phase);
  extern function void connect_phase (uvm_phase phase);
  
  // function void end_of_elaboration_phase (uvm_phase phase);
  //   print();
  // endfunction // end_of_elaboration_phase  
endclass // jtag_agent

function void jtag_agent::build_phase (uvm_phase phase);
  super.build_phase(phase);
  
  if (jtag_agent_cfg == null)
    begin
      `uvm_info("JTAG_AGENT_INFO", " Creating configuration", UVM_LOW)
      jtag_agent_cfg = jtag_agent_config::type_id::create("jtag_agent_cfg");
      if (!jtag_agent_cfg.randomize())
        `uvm_fatal("JTAG_AGENT_FATAL", "Randomization of jtag_agent_cfg failed")
    end
  else
    `uvm_info("JTAG_AGENT_INFO", " Agent used auto config", UVM_LOW)
  
  if (jtag_agent_cfg.is_active == UVM_ACTIVE)
    begin
      `uvm_info("JTAG_AGENT_INFO", "Agent is active... building drv and seq", UVM_LOW)
      
      uvm_config_db#(uvm_object)::set(this,"driver","driver_cfg", jtag_agent_cfg.driver_cfg);

      // the existance of vif can be checked in build phase since it is top down.
      // That way we avoid driver errors in connect phase that is bottom up
      if(uvm_config_db#(jtag_vif)::exists(this, get_full_name(), "jtag_virtual_if"))
        begin
          `uvm_info("JTAG_AGENT_INFO","VIF EXISTS IN CONFIG DB",UVM_LOW)
        end
      else
        `uvm_fatal("JTAG_AGENT_FATAL", {"VIF must exist for: ", get_full_name()})
      
      // the existance of proxy can be checked in build phase since it is top down.
      // That way we avoid driver errors in connect phase that is bottom up
      if(uvm_config_db#(jtag_if_proxy)::exists(this, get_full_name(), "jtag_if_proxy"))
        begin
          `uvm_info("JTAG_AGENT_INFO","IF_PROXY EXISTS IN CONFIG DB",UVM_LOW)
        end
      else
        `uvm_fatal("JTAG_AGENT_FATAL", {"IF_PROXY must exist for: ", get_full_name()})
      
      driver = jtag_driver::type_id::create("driver",this);
      sequencer = jtag_sequencer::type_id::create("sequencer",this);
    end 
  
  collector = jtag_collector::type_id::create("collector",this);
  monitor = jtag_monitor::type_id::create("monitor",this);
  
endfunction // build_phase

function void jtag_agent::connect_phase (uvm_phase phase);
  super.connect_phase(phase);
  
  `uvm_info("JTAG_AGENT_INFO", "Agent connect phase", UVM_LOW)

  collector.item_collected_rx_port.connect(monitor.col_mon_rx_import);
  collector.item_collected_tx_port.connect(monitor.col_mon_tx_import);
  
  // requires automatic configuration from test
  if (monitor.drv_mon_tx_check_en)
    driver.drv_mon_tx_port.connect(monitor.drv_mon_tx_import);
    
  if (jtag_agent_cfg.is_active == UVM_ACTIVE)
    begin
      `uvm_info("JTAG_AGENT_INFO", "Agent is active... connecting drv and seq", UVM_LOW)
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  
endfunction // connect_phase

`endif
