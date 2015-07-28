`ifndef JTAG_MONITOR__SVH
 `define JTAG_MONITOR__SVH

// performs transaction level checking and coverage
class jtag_monitor extends uvm_monitor;
  
  jtag_receive_packet collected_rsp;
  
  `uvm_component_utils_begin(jtag_monitor)
  `uvm_field_object(collected_rsp, UVM_DEFAULT)
  `uvm_component_utils_end
  
  uvm_analysis_imp #(jtag_receive_packet, jtag_monitor) col_mon_import;
  
  function new (string name, uvm_component parent);
    super.new(name,parent);
  endfunction // new
  
  virtual function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    // will not be overriden by factory so new() is suficient
    col_mon_import = new("col_mon_import", this);
  endfunction // build_phase

  extern virtual function void write (jtag_receive_packet rsp);
  
endclass // jtag_monitor

// the body of write must be defined otherwise will get elaboration error
// automatically called when collector writes to its analysis port
function void jtag_monitor::write (jtag_receive_packet rsp);
  rsp.print();
endfunction // write

`endif
