`ifndef JTAG_SEQUENCE_LIB__SVH
 `define JTAG_SEQUENCE_LIB__SVH

class jtag_simple_sequence extends uvm_sequence #(jtag_send_packet, jtag_packet);
  
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
        repeat_cnt = 5;
      end
    
    repeat(repeat_cnt)
      begin
        // `uvm_do_with(req, {req.delay == 0;}) expanded below
        req = jtag_send_packet::type_id::create("req");
        start_item(req);       
        if (!req.randomize() with {req.delay == 0;})
          `uvm_fatal("JTAG_SIMPLE_SEQ", "Failed on randomization of req")   
        finish_item(req);
        get_response(rsp);
        rsp.print();
        
      end
    
  endtask // body
  
endclass // jtag_simple_sequence

class jtag_simple_sequence_with_rand_delay extends jtag_simple_sequence;
  
  jtag_packet tmp_rsp;
  jtag_packet tmp_rsp_cloned;
  
  `uvm_object_utils_begin(jtag_simple_sequence_with_rand_delay)
  `uvm_field_object(test_cfg, UVM_DEFAULT)
  `uvm_field_object(tmp_rsp, UVM_DEFAULT)
  `uvm_field_object(tmp_rsp_cloned, UVM_DEFAULT)
  `uvm_object_utils_end
  
  function new (string name = "jtag_simple_sequence_with_rand_delay");
    super.new(name);
  endfunction // new
  
  virtual task body();
    int repeat_cnt;
    
    tmp_rsp = jtag_packet::type_id::create("tmp_rsp");
    
    if (!uvm_config_db#(test_configuration)::get(null,"","test_cfg",test_cfg))
      begin
        `uvm_info("JTAG_SIMPLE_SEQUENCE_WITH_RAND_DELAY","No test configuration exists in config db", UVM_LOW)
        repeat_cnt = 1;
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

        // This is not a pipelined protocol but for fun i return the rsp from driver
        // with item_done(req). Simple call to get_response(rsp); or :
        get_response(rsp, req.get_transaction_id()); // blocking
        rsp.print();

        // always new pointer for tmp_rsp_cloned
        $cast(tmp_rsp_cloned, rsp.clone());
        tmp_rsp_cloned.print();
        
        // always same pointer for tmp_rsp
        tmp_rsp.copy(rsp);      // just to use copy()
        tmp_rsp.print();
        
      end
    
  endtask // body
  
endclass // jtag_simple_sequence_with_rand_delay

`endif
