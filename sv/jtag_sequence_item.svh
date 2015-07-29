`ifndef JTAG_SEQUENCE_ITEM__SVH
 `define JTAG_SEQUENCE_ITEM__SVH

// sequence items
class jtag_send_packet extends uvm_sequence_item;
  
  rand jtag_instr_registers instr;
  rand logic [31:0] data;
  rand int instr_sz;
  rand int data_sz;
  
  rand bit [3:0] delay;
  
  constraint c_instr_sz {instr_sz == $size(instr)-1;}
  constraint c_data_sz {data_sz == $size(data)-1;}
  
  `uvm_object_utils_begin(jtag_send_packet)
  `uvm_field_enum(jtag_instr_registers, instr, UVM_DEFAULT)
  `uvm_field_int(data, UVM_DEFAULT)
  `uvm_field_int(instr_sz, UVM_DEFAULT)
  `uvm_field_int(data_sz, UVM_DEFAULT)
  `uvm_field_int(delay, UVM_DEFAULT)
  `uvm_object_utils_end

    function new (string name = "jtag_send_packet");
      super.new(name);
    endfunction // new
  
endclass // jtag_send_packet

class jtag_packet extends uvm_sequence_item;
  
  bit [3:0] instr;
  logic [31:0] data;
  
  `uvm_object_utils_begin(jtag_packet)
  `uvm_field_int(instr, UVM_DEFAULT)
  `uvm_field_int(data, UVM_DEFAULT)
  `uvm_object_utils_end

    function new (string name = "jtag_packet");
      super.new(name);
    endfunction // new

endclass // jtag_packet

class jtag_idcode extends jtag_send_packet;

  `uvm_object_utils(jtag_idcode)

  constraint c_instr { instr == 4'b0010;}
  constraint c_data { data == 32'b0;}
  constraint c_delay { delay == 0;}
  
  function new (string name = "jtag_idcode");
    super.new(name);
  endfunction // new

endclass // jtag_idcode

`endif
