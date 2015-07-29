`ifndef JTAG_MONITOR__SVH
 `define JTAG_MONITOR__SVH

// performs transaction level checking and coverage
class jtag_monitor extends uvm_monitor;

  jtag_receive_packet collected_rsp;
  bit coverage_enable = 0;
  
  `uvm_component_utils_begin(jtag_monitor)
  `uvm_field_object(collected_rsp, UVM_DEFAULT)
  `uvm_field_int(coverage_enable, UVM_DEFAULT)
  `uvm_component_utils_end
  
  uvm_analysis_imp #(jtag_receive_packet, jtag_monitor) col_mon_import;

  covergroup jtag_transfer_cg;
    JTAG_INSTR_REG: coverpoint collected_rsp.instr;
  endgroup // jtag_transfer_cg
    
  function new (string name, uvm_component parent);
    super.new(name,parent);
    
    // covergroups always in new method
    jtag_transfer_cg = new();
    
  endfunction // new
  
  virtual function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    // will not be overriden by factory so new() is suficient
    col_mon_import = new("col_mon_import", this);
    collected_rsp = jtag_receive_packet::type_id::create("collected_rsp");
    if (coverage_enable)
      `uvm_info("JTAG_COLLECTOR", "Coverage enabled", UVM_LOW)
  endfunction // build_phase

  extern virtual function void write (jtag_receive_packet rsp);
  extern virtual function void perform_coverage();
  
endclass // jtag_monitor

// the body of write must be defined otherwise will get elaboration error
// automatically called when collector writes to its analysis port
function void jtag_monitor::write (jtag_receive_packet rsp);
  `uvm_info("JTAG_COLLECTOR", "PRINTS RSP ->", UVM_LOW)
  collected_rsp.copy(rsp);
  collected_rsp.print();
  
  if (coverage_enable)
    perform_coverage();  

endfunction // write

function void jtag_monitor::perform_coverage();  
  jtag_transfer_cg.sample();
endfunction // perform_coverage

`endif
