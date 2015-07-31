`ifndef JTAG_MONITOR__SVH
 `define JTAG_MONITOR__SVH

`uvm_analysis_imp_decl(_tx)
`uvm_analysis_imp_decl(_drv_tx)
`uvm_analysis_imp_decl(_rx)

// performs transaction level checking and coverage
class jtag_monitor extends uvm_monitor;

  jtag_packet collected_rx;
  jtag_packet collected_tx;
  jtag_packet driver_tx;
  
  bit coverage_enable = 0;
  
  // enable tx checks
  bit drv_mon_tx_check_en = 0;

  `uvm_component_utils_begin(jtag_monitor)
  `uvm_field_object(collected_rx, UVM_DEFAULT)
  `uvm_field_object(collected_tx, UVM_DEFAULT)
  `uvm_field_object(driver_tx, UVM_DEFAULT)
  `uvm_field_int(coverage_enable, UVM_DEFAULT)
  `uvm_field_int(drv_mon_tx_check_en, UVM_DEFAULT)
  `uvm_component_utils_end
  
  uvm_analysis_imp_tx #(jtag_packet, jtag_monitor) col_mon_tx_import;
  uvm_analysis_imp_drv_tx #(jtag_packet, jtag_monitor) drv_mon_tx_import;
  uvm_analysis_imp_rx #(jtag_packet, jtag_monitor) col_mon_rx_import;

  covergroup jtag_rsp_cg;
    JTAG_RSP: coverpoint collected_rx.instr;
  endgroup // jtag_transfer_cg
  
  covergroup jtag_trans_cg;
    JTAG_TRANS: coverpoint collected_tx.instr;
  endgroup // jtag_transfer_cg
  
  function new (string name, uvm_component parent);
    super.new(name,parent);
    
    // covergroups always in new method
    jtag_rsp_cg = new();
    jtag_trans_cg = new();
    
  endfunction // new
  
  virtual function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    
    collected_rx = jtag_packet::type_id::create("collected_rx");
    collected_tx = jtag_packet::type_id::create("collected_tx");
    driver_tx = jtag_packet::type_id::create("driver_tx");
    
    // will not be overriden by factory so new() is suficient
    col_mon_rx_import = new("col_mon_rx_import", this);
    
    // requires automatic configuration
    if (drv_mon_tx_check_en)
      drv_mon_tx_import = new("drv_mon_tx_import", this);
    
    col_mon_tx_import = new("col_mon_tx_import", this);
    
    if (coverage_enable)
      `uvm_info("JTAG_COLLECTOR", "Coverage enabled", UVM_LOW)
    
  endfunction // build_phase

  extern virtual function void write_rx (jtag_packet rsp);
  extern virtual function void write_tx (jtag_packet trans);
  extern virtual function void write_drv_tx (jtag_packet trans);
  extern virtual function void perform_rsp_coverage();
  extern virtual function void perform_trans_coverage();
  
endclass // jtag_monitor

// the body of write must be defined otherwise will get elaboration error
// automatically called when collector writes to its analysis port
function void jtag_monitor::write_rx (jtag_packet rsp);
  `uvm_info("JTAG_COLLECTOR", "RX TRANS (from collector)", UVM_LOW)
  collected_rx.copy(rsp);
  // collected_rx.print();
  
  if (coverage_enable)
    perform_rsp_coverage();  

endfunction // write_rx

function void jtag_monitor::write_tx (jtag_packet trans);
  `uvm_info("JTAG_COLLECTOR", "TX TRANS (from collector)", UVM_LOW)
  collected_tx.copy(trans);
  // collected_tx.print();
  
  if (coverage_enable)
    perform_trans_coverage();

  // used for sanity checking
  if (drv_mon_tx_check_en)
    begin
      if (!collected_tx.compare(driver_tx))
        `uvm_fatal("JTAG_MONITOR", "TX TRANS (from collector/ from driver) MISSMATCH")
      else
        `uvm_info("JTAG_COLLECTOR", "TX TRANS (from collector/ from driver) MATCH", UVM_LOW)
    end
  
endfunction // write_rx

function void jtag_monitor::write_drv_tx (jtag_packet trans);
  `uvm_info("JTAG_COLLECTOR", "TX TRANS (from driver)", UVM_LOW)
  driver_tx.copy(trans);
  // driver_tx.print();  
endfunction // write_rx

function void jtag_monitor::perform_rsp_coverage();  
  jtag_rsp_cg.sample();
endfunction // perform_coverage

function void jtag_monitor::perform_trans_coverage();  
  jtag_trans_cg.sample();
endfunction // perform_coverage

`endif
