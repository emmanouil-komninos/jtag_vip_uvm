`ifndef JTAG_SEQUENCE_ITEM__SVH
 `define JTAG_SEQUENCE_ITEM__SVH

// sequence items
class jtag_send_packet extends uvm_sequence_item;
  
  rand logic [0:3] instr_reg;
  rand logic [0:7] data;

  `uvm_object_utils_begin(jtag_send_packet)
  `uvm_field_int(instr_reg, UVM_ALL_ON)
  `uvm_field_int(data, UVM_DEFAULT)
  `uvm_object_utils_end

    function new (string name = "jtag_send_packet");
      super.new(name);
    endfunction // new
  
endclass // jtag_send_packet

class jtag_idcode extends jtag_send_packet;

  `uvm_object_utils(jtag_idcode)

  constraint c_instr_reg { instr_reg == 4'b0010;}
  
  function new (string name = "jtag_idcode");
    super.new(name);
  endfunction // new

endclass // jtag_idcode

`endif
