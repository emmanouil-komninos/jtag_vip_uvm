`ifndef JTAG_MONITOR__SVH
 `define JTAG_MONITOR__SVH

// performs transaction level checking and coverage
class jtag_monitor extends uvm_monitor;

  `uvm_component_utils(jtag_monitor)
  
  function new (string name, uvm_component parent);
    super.new(name,parent);
  endfunction // new
  
endclass // jtag_monitor


`endif
