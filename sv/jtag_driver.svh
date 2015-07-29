`ifndef JTAG_DRIVER__SVH
 `define JTAG_DRIVER__SVH

class jtag_driver extends uvm_driver #(jtag_send_packet, jtag_receive_packet);
  
  // configuration component for the driver
  jtag_driver_config jtag_drv_cfg;
  
  // no automation for the following 
  tap_state current_state = X;
  bit        exit = 0;
  bit dr_shifted_out = 0;
  bit ir_shifted_out = 0;
  jtag_send_packet temp_req;
  
  // virtual interface
  jtag_vif jtag_vif_drv;
  
  // uvm macros for configuration
  // allows for automatic configuration 
  // during call of super.build_phase()
  `uvm_component_utils_begin(jtag_driver)
  `uvm_field_object(jtag_drv_cfg, UVM_DEFAULT)
  `uvm_component_utils_end

    function new (string name, uvm_component parent);
      super.new(name, parent);
    endfunction // new
  
  // uvm phases
  function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    if(jtag_drv_cfg == null)
      begin
        `uvm_fatal("JTAG_DRIVER_FATAL","Empty driver configuration")
        jtag_drv_cfg.print(); 
      end
  endfunction // build_phase
  
  virtual function void connect_phase (uvm_phase phase);
    super.connect_phase(phase);
   
    `uvm_info("JTAG_DRIVER_INFO","Driver Connect phase",UVM_LOW)
    
    if(!uvm_config_db#(jtag_vif)::get(null, get_full_name(), "jtag_virtual_if", jtag_vif_drv))
      `uvm_fatal("JTAG_DRIVER_FATAL", {"VIF must be set for: ", get_full_name()})
    else
      `uvm_info("JTAG_DRIVER_INFO", {"VIF is set for: ", get_full_name()},UVM_LOW )
      
  endfunction // connect_phase

  task run_phase (uvm_phase phase);
    if (jtag_vif_drv == null)
      begin
        `uvm_fatal("JTAG_DRIVER_FATAL", {"VIF must be set for: ", get_full_name()})
      end
    else
      `uvm_info("JTAG_DRIVER_INFO", " Driver used if from config db", UVM_LOW)
    
    // time consuming part
    forever
      begin
        seq_item_port.get_next_item(req); // blocking

        // new pointer for each response.. 
        // maybe the sequence is draining rsp slower than the driver provides them
        rsp = jtag_receive_packet::type_id::create("rsp");
        
        // in the sequence, when calling get_response(), 
        // we can optionally provide the transaction_id of the req to pick up the specific rsp
        rsp.set_id_info(req);

        phase.raise_objection(this,"Jtag Driver raised objection");
                
        $cast(temp_req, req.clone()); // temp_req will be modified
        ir_seq();
        dr_seq();
        
        phase.drop_objection(this, "Jtag Driver dropped objection");
        
        repeat (req.delay) @jtag_vif_drv.tb_ck;
        
        // following will return a response. 
        // get the response in the sequence otherwise you ll get overflow after a couple of rsps (8?)
        seq_item_port.item_done(rsp);

        // if no rsp required dont call the blocking get_response() at the sequence
        // and don't return a rsp from here by calling :
        // seq_item_port.item_done();
      
      end
    
  endtask // run_phase
  
  task all_dropped (uvm_objection objection, uvm_object source_obj, string description, int count);
    if (objection == uvm_test_done)
      begin
        `uvm_info("JTAG_DRIVER_INFO", "Jtag driver @ all_dropped waiting for drain time", UVM_LOW)
        repeat (15) @jtag_vif_drv.tb_ck;
        // uvm_test_done.drop_objection(this);
      end
  endtask // all_dropped
  
  extern task dr_seq();
  extern task ir_seq();
  extern function void compute_state();
  extern function void drive_tms_ir();
  extern function void drive_tms_dr();

  // function void end_of_elaboration_phase (uvm_phase phase);
  //   print();
  // endfunction // end_of_elaboration_phase
  
endclass // jtag_driver

task jtag_driver::dr_seq();
  
  this.exit = 0;
  
  while (!this.exit)
    begin
      drive_tms_dr();
      @jtag_vif_drv.tb_ck;
      compute_state();
    end
  
endtask // dr_seq

task jtag_driver::ir_seq();
  
  this.exit = 0;
  
  while (!this.exit)
    begin
      drive_tms_ir();
      @jtag_vif_drv.tb_ck;
      compute_state();
    end

endtask // ir_seq

// compute tms based on current state
function void jtag_driver::drive_tms_dr();
    
  this.exit = 0;
  
  jtag_vif_drv.jtag_tb_mod.tb_ck.tms <= 0;
  
  case (this.current_state)
    X:
      begin
        // this.next_state = RESET;
        jtag_vif_drv.jtag_tb_mod.tb_ck.tms <= 1;
      end
    IDLE:
      begin
        // this.next_state = SELECT_DR;
        jtag_vif_drv.jtag_tb_mod.tb_ck.tms <= 1;
      end
    SHIFT_DR:
      begin
        if (this.temp_req.data_sz > 0)
          begin
            // this.next_state = SHIFT_DR;
            jtag_vif_drv.jtag_tb_mod.tb_ck.tdi <= this.temp_req.data[this.temp_req.data_sz];
            this.temp_req.data_sz--;
          end
        else
          begin
            // this.next_state = EXIT_DR;
            // drive last bit to tdi
            jtag_vif_drv.jtag_tb_mod.tb_ck.tdi <= this.temp_req.data[this.temp_req.data_sz];
            jtag_vif_drv.jtag_tb_mod.tb_ck.tms <= 1;
          end
      end
    EXIT_DR:
      begin
        // this.next_state = UPDATE_DR;
        jtag_vif_drv.jtag_tb_mod.tb_ck.tms <= 1;
      end
    UPDATE_DR:
      begin
        // this.next_state = IDLE;
        this.exit = 1;
      end
    default:
      jtag_vif_drv.jtag_tb_mod.tb_ck.tms <= 0;
  endcase // case (this.current_state)
  
endfunction // drive_tms_dr


// compute tms based on current state
function void jtag_driver::drive_tms_ir();
    
  this.exit = 0;
  
  jtag_vif_drv.jtag_tb_mod.tb_ck.tms <= 0;
  
  case (this.current_state)
    X:
      begin
        // this.next_state = RESET;
        jtag_vif_drv.jtag_tb_mod.tb_ck.tms <= 1;
      end
    IDLE:
      begin
        // this.next_state = SELECT_DR;
        jtag_vif_drv.jtag_tb_mod.tb_ck.tms <= 1;
      end
    SELECT_DR:
      begin
        // this.next_state = SELECT_IR;
        jtag_vif_drv.jtag_tb_mod.tb_ck.tms <= 1;
      end
    SHIFT_IR:
      begin
        if (this.temp_req.instr_sz > 0)
          begin
            // this.next_state = SHIFT_IR;
            jtag_vif_drv.jtag_tb_mod.tb_ck.tdi <= this.temp_req.instr[this.temp_req.instr_sz];
            this.temp_req.instr_sz--;
          end
        else
          begin
            // this.next_state = EXIT_IR;
            // drive last bit to tdi
            jtag_vif_drv.jtag_tb_mod.tb_ck.tdi <= this.temp_req.instr[this.temp_req.instr_sz];
            jtag_vif_drv.jtag_tb_mod.tb_ck.tms <= 1;
          end
      end
    EXIT_IR:
      begin
        // this.next_state = UPDATE_IR;
        jtag_vif_drv.jtag_tb_mod.tb_ck.tms <= 1;
      end
    UPDATE_IR:
      begin
        // this.next_state = IDLE;
        this.exit = 1;
      end
    default:
      jtag_vif_drv.jtag_tb_mod.tb_ck.tms <= 0;
  endcase // case (this.current_state)
  
endfunction // drive_tms_ir

// compute next state based on tms
function void jtag_driver::compute_state();
  
  case (this.current_state)
    X:
      begin 
        if(jtag_vif_drv.jtag_tb_mod.tb_ck.tms == 1) 
          this.current_state = RESET;
      end        
    RESET:
      begin 
        if(jtag_vif_drv.jtag_tb_mod.tb_ck.tms == 0) 
          this.current_state = IDLE;
      end
    IDLE: 
      begin
        if(jtag_vif_drv.jtag_tb_mod.tb_ck.tms == 1) 
          this.current_state = SELECT_DR;
      end
    SELECT_DR: 
      begin
        if(jtag_vif_drv.jtag_tb_mod.tb_ck.tms == 1) 
          this.current_state = SELECT_IR;
        else
          this.current_state = CAPTURE_DR;
      end
    SELECT_IR: 
      begin
        if(jtag_vif_drv.jtag_tb_mod.tb_ck.tms == 1)
          this.current_state = RESET;
        else
          this.current_state = CAPTURE_IR;
      end
    CAPTURE_DR: 
      begin
        if(jtag_vif_drv.jtag_tb_mod.tb_ck.tms == 1)
          this.current_state = EXIT_DR;
        else
          this.current_state = SHIFT_DR;
      end
    CAPTURE_IR: 
      begin
        if(jtag_vif_drv.jtag_tb_mod.tb_ck.tms == 1)
          this.current_state = EXIT_IR;
        else
          this.current_state = SHIFT_IR;
      end
    SHIFT_DR: 
      begin
        rsp.data = {jtag_vif_drv.jtag_tb_mod.tb_ck.tdo, rsp.data[31:1]};
        if(jtag_vif_drv.jtag_tb_mod.tb_ck.tms == 1)
          this.current_state = EXIT_DR;
      end
    SHIFT_IR: 
      begin
        rsp.instr = {jtag_vif_drv.jtag_tb_mod.tb_ck.tdo, rsp.instr[3:1]};
        if(jtag_vif_drv.jtag_tb_mod.tb_ck.tms == 1)
          this.current_state = EXIT_IR;
      end
    EXIT_DR:
      begin
        rsp.data = {jtag_vif_drv.jtag_tb_mod.tb_ck.tdo, rsp.data[31:1]};
        if(jtag_vif_drv.jtag_tb_mod.tb_ck.tms == 1)
          this.current_state = UPDATE_DR;
        else
          this.current_state = PAUSE_DR;
      end
    EXIT_IR:
      begin
        rsp.instr = {jtag_vif_drv.jtag_tb_mod.tb_ck.tdo, rsp.instr[3:1]};
        if(jtag_vif_drv.jtag_tb_mod.tb_ck.tms == 1)
          this.current_state = UPDATE_IR;
        else
          this.current_state = PAUSE_IR;
      end
    PAUSE_DR:
      begin
        if(jtag_vif_drv.jtag_tb_mod.tb_ck.tms == 1)
          this.current_state = EXIT2_DR;
      end
    PAUSE_IR:
      begin
        if(jtag_vif_drv.jtag_tb_mod.tb_ck.tms == 1)
          this.current_state = EXIT2_IR;
      end
    EXIT2_DR:
      begin
        if(jtag_vif_drv.jtag_tb_mod.tb_ck.tms == 1)
          this.current_state = UPDATE_DR;
        else
          this.current_state = SHIFT_DR;
      end
    EXIT2_IR:
      begin
        if(jtag_vif_drv.jtag_tb_mod.tb_ck.tms == 1)
          this.current_state = UPDATE_IR;
        else
          this.current_state = SHIFT_IR;
      end
    UPDATE_DR, UPDATE_IR:
      begin
        if(jtag_vif_drv.jtag_tb_mod.tb_ck.tms == 1)
          this.current_state = SELECT_DR;
        else
          this.current_state = IDLE;
      end
  endcase // case (this.current_state)
  
endfunction // compute_state

`endif
