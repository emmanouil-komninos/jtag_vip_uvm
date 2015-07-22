`ifndef JTAG_SEQUENCE_ITEM__SVH
 `define JTAG_SEQUENCE_ITEM__SVH

// sequence items
class jtag_send_packet extends uvm_sequence_item;
  
  rand logic [0:3] instr;
  rand logic [0:7] data;
  rand int instr_sz;
  rand int data_sz;

  constraint c_instr_sz {instr_sz == $size(instr);}
  constraint c_data_sz {data_sz == $size(data);}
  
  `uvm_object_utils_begin(jtag_send_packet)
  `uvm_field_int(instr, UVM_DEFAULT)
  `uvm_field_int(data, UVM_DEFAULT)
  `uvm_field_int(instr_sz, UVM_DEFAULT)
  `uvm_field_int(data_sz, UVM_DEFAULT)
  `uvm_object_utils_end

    function new (string name = "jtag_send_packet");
      super.new(name);
    endfunction // new
  
endclass // jtag_send_packet

class jtag_idcode extends jtag_send_packet;

  `uvm_object_utils(jtag_idcode)

  constraint c_instr { instr == 4'b0010;}
  
  function new (string name = "jtag_idcode");
    super.new(name);
  endfunction // new

endclass // jtag_idcode

`endif
