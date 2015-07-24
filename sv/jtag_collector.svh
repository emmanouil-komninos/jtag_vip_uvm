`ifndef JTAG_COLLECTOR__SVH
 `define JTAG_COLLECTOR__SVH

// extract bus signal info and translate it into transactions
class jtag_collector extends uvm_component;
  
  jtag_vif jtag_vif_col;
  
  `uvm_component_utils(jtag_collector)

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction // new

  
endclass // jtag_collector



`endif
