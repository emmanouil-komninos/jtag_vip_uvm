`ifndef JTAG_SEQUENCER__SVH
 `define JTAG_SEQUENCER__SVH

class jtag_sequencer extends uvm_sequencer #(jtag_send_packet, jtag_packet);
  
  `uvm_component_utils(jtag_sequencer)

  function new (string name, uvm_component parent);
    super.new(name,parent);
  endfunction // new
  
endclass // jtag_sequencer

`endif
