`ifndef JTAG_SEQUENCE_LIB__SVH
 `define JTAG_SEQUENCE_LIB__SVH

class test_configuration extends uvm_object;
  rand int seq_repeat;

  constraint c_seq_repeat {seq_repeat == 1;}
  
  function new (string name = "test_configuration");
    super.new(name);
  endfunction // new
  
endclass // test_configuration

class jtag_simple_sequence extends uvm_sequence #(jtag_send_packet);
  test_configuration test_cfg;
  
  `uvm_object_utils_begin(jtag_simple_sequence)
  `uvm_field_object(test_cfg, UVM_DEFAULT)
  `uvm_object_utils_end

  function new (string name = "jtag_simple_sequence");
    super.new(name);
  endfunction // new
  
  virtual task body();
    int repeat_cnt;
    
    if (!uvm_config_db#(test_configuration)::get(null,"","test_cfg",test_cfg))
      begin
        `uvm_info("JTAG_SIMPLE_SEQUENCE","No test configuration exists in config db", UVM_LOW)
        repeat_cnt = 3;
      end
    
    repeat(repeat_cnt)
      begin 
        req = jtag_send_packet::type_id::create("req");
        start_item(req);       
        if (!req.randomize())
          `uvm_fatal("JTAG_SIMPLE_SEQ", "Failed on randomization of req")   
        finish_item(req);
      end
  endtask // body
  
endclass // jtag_simple_sequence

`endif
