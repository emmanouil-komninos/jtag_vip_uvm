`ifndef JTAG_COLLECTOR__SVH
 `define JTAG_COLLECTOR__SVH

// extract bus signal info and translate it into transactions
class jtag_collector extends uvm_component;
  
  jtag_vif jtag_vif_col;

  uvm_analysis_port #(jtag_receive_packet) item_collected_port;
  
  `uvm_component_utils(jtag_collector)

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction // new

  virtual function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    item_collected_port = new("item_collected_port",this);
  endfunction // build_phase

  virtual function void connect_phase (uvm_phase phase);
    super.connect_phase(phase);
    
    if (!uvm_config_db#(jtag_vif)::get(this, get_full_name(), "jtag_virtual_if", jtag_vif_col))
      `uvm_fatal("JTAG_COLLECTOR", "Virtual interface is null")
    
  endfunction // connect_phase
  
endclass // jtag_collector

`endif
