`ifndef JTAG_MONITOR__SVH
 `define JTAG_MONITOR__SVH

`uvm_analysis_imp_decl(_tx)
`uvm_analysis_imp_decl(_rx)

// performs transaction level checking and coverage
class jtag_monitor extends uvm_monitor;

  jtag_receive_packet collected_rsp;
  jtag_send_packet collected_trans;
  
  bit coverage_enable = 0;
  
  `uvm_component_utils_begin(jtag_monitor)
  `uvm_field_object(collected_rsp, UVM_DEFAULT)
  `uvm_field_object(collected_trans, UVM_DEFAULT)
  `uvm_field_int(coverage_enable, UVM_DEFAULT)
  `uvm_component_utils_end
  
  uvm_analysis_imp_tx #(jtag_send_packet, jtag_monitor) col_mon_tx_import;
  uvm_analysis_imp_rx #(jtag_receive_packet, jtag_monitor) col_mon_rx_import;

  covergroup jtag_rsp_cg;
    JTAG_RSP: coverpoint collected_rsp.instr;
  endgroup // jtag_transfer_cg
  
  covergroup jtag_trans_cg;
    JTAG_TRANS: coverpoint collected_trans.instr;
  endgroup // jtag_transfer_cg
  
  function new (string name, uvm_component parent);
    super.new(name,parent);
    
    // covergroups always in new method
    jtag_rsp_cg = new();
    jtag_trans_cg = new();
    
  endfunction // new
  
  virtual function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    
    collected_rsp = jtag_receive_packet::type_id::create("collected_rsp");
    collected_trans = jtag_send_packet::type_id::create("collected_trans");
    
    // will not be overriden by factory so new() is suficient
    col_mon_rx_import = new("col_mon_rx_import", this);
    col_mon_tx_import = new("col_mon_tx_import", this);
    
    if (coverage_enable)
      `uvm_info("JTAG_COLLECTOR", "Coverage enabled", UVM_LOW)
    
  endfunction // build_phase

  extern virtual function void write_rx (jtag_receive_packet rsp);
  extern virtual function void write_tx (jtag_send_packet trans);
  extern virtual function void perform_rsp_coverage();
  extern virtual function void perform_trans_coverage();
  
endclass // jtag_monitor

// the body of write must be defined otherwise will get elaboration error
// automatically called when collector writes to its analysis port
function void jtag_monitor::write_rx (jtag_receive_packet rsp);
  `uvm_info("JTAG_COLLECTOR", "PRINTS RSP ->", UVM_LOW)
  collected_rsp.copy(rsp);
  collected_rsp.print();
  
  if (coverage_enable)
    perform_rsp_coverage();  

endfunction // write_rx

function void jtag_monitor::write_tx (jtag_send_packet trans);
  `uvm_info("JTAG_COLLECTOR", "PRINTS TRANS ->", UVM_LOW)
  collected_trans.copy(trans);
  collected_trans.print();
  
  if (coverage_enable)
    perform_trans_coverage();  

endfunction // write_rx

function void jtag_monitor::perform_rsp_coverage();  
  jtag_rsp_cg.sample();
endfunction // perform_coverage

function void jtag_monitor::perform_trans_coverage();  
  jtag_trans_cg.sample();
endfunction // perform_coverage

`endif
