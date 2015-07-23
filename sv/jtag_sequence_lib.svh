`ifndef JTAG_SEQUENCE_LIB__SVH
 `define JTAG_SEQUENCE_LIB__SVH

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
        repeat_cnt = 100;
      end
    
    repeat(repeat_cnt)
      begin
        // `uvm_do_with(req, {req.delay == 0;}) expanded below
        req = jtag_send_packet::type_id::create("req");
        start_item(req);       
        if (!req.randomize() with {req.delay == 0;})
          `uvm_fatal("JTAG_SIMPLE_SEQ", "Failed on randomization of req")   
        finish_item(req);
        
        // if response is returned from the driver with item_done(req)
        // get_response(rsp);

      end
    
  endtask // body
  
endclass // jtag_simple_sequence

class jtag_simple_sequence_with_rand_delay extends jtag_simple_sequence;
  
  `uvm_object_utils(jtag_simple_sequence_with_rand_delay)
  
  function new (string name = "jtag_simple_sequence_with_rand_delay");
    super.new(name);
  endfunction // new
  
  virtual task body();
    int repeat_cnt;
    
    if (!uvm_config_db#(test_configuration)::get(null,"","test_cfg",test_cfg))
      begin
        `uvm_info("JTAG_SIMPLE_SEQUENCE_WITH_RAND_DELAY","No test configuration exists in config db", UVM_LOW)
        repeat_cnt = 100;
      end
    
    repeat(repeat_cnt)
      begin
        // `uvm_do(req) expanded below
        req = jtag_send_packet::type_id::create("req");
        start_item(req);       
        if (!req.randomize())
          `uvm_fatal("JTAG_SIMPLE_SEQ_WITH_RAND_DELAY", 
                     "Failed on randomization of req")   
        finish_item(req);
      end
    
  endtask // body
  
endclass // jtag_simple_sequence_with_rand_delay

`endif
