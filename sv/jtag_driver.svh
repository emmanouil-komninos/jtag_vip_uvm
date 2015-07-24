`ifndef JTAG_DRIVER__SVH
 `define JTAG_DRIVER__SVH

typedef enum {RESET, IDLE, SELECT_DR, SELECT_IR, CAPTURE, SHIFT, EXIT, EXIT2, PAUSE, UPDATE} state;

class jtag_driver extends uvm_driver #(jtag_send_packet, jtag_receive_packet);
  
  // configuration component for the driver
  jtag_driver_config jtag_drv_cfg;
  
  // no automation for the following 
  state next_state = IDLE;
  state current_state = RESET;
  bit        exit = 0;
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
  
  function void connect_phase (uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info("JTAG_DRIVER_INFO","Driver Connect phase",UVM_LOW)
  endfunction // connect_phase

  task run_phase (uvm_phase phase);
    if (jtag_vif_drv == null)
      begin
        `uvm_error("JTAG_DRIVER_ERROR", {"VIF must be set for: ", get_full_name(), ".jtag_vif_drv"})
        `uvm_fatal("JTAG_DRIVER_INFO", "NO VIF")
      end
    else
      `uvm_info("JTAG_DRIVER_INFO", " Driver used if from config db", UVM_LOW)

    // time consuming part
    while(1)
      begin
        seq_item_port.get_next_item(req);
        req.print();
        
        rsp = jtag_receive_packet::type_id::create("rsp");

        // in the sequence, when calling get_response(), we can optionally provide the transaction_id of the req
        rsp.set_id_info(req);
        
        phase.raise_objection(this,"Jtag Driver raised objection");
                
        $cast(temp_req, req.clone()); // temp_req will be modified
        ir_seq();
        dr_seq();
        
        phase.drop_objection(this, "Jtag Driver dropped objection");
        
        repeat (req.delay) @jtag_vif_drv.drv_ck;
        
        // following will return a response.. 
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
        repeat (15) @jtag_vif_drv.drv_ck;
        // uvm_test_done.drop_objection(this);
      end
  endtask // all_dropped  
  
  state current_dr_state = IDLE;
  
  extern task dr_seq();
  extern task ir_seq();
  extern function void compute_state(bit tms);
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
      compute_state(jtag_vif_drv.tms);
      @jtag_vif_drv.drv_ck;
      this.current_state = this.next_state;
    end
  
endtask // dr_seq

task jtag_driver::ir_seq();
  
  this.exit = 0;
  
  while (!this.exit)
    begin
      drive_tms_ir();
      compute_state(jtag_vif_drv.tms);
      @jtag_vif_drv.drv_ck;
      this.current_state = this.next_state;
    end

endtask // ir_seq

// compute tms based on current state
function void jtag_driver::drive_tms_dr();
  
  static bit capture_tdo = 0;
  
  this.exit = 0;
  
  jtag_vif_drv.tms = 0;
  
  if (capture_tdo)
    begin
      rsp.data = {jtag_vif_drv.tdo, rsp.data[31:1]};
    end
  
  case (this.current_state)
    IDLE:
      begin
        // this.next_state = SELECT_DR;
        jtag_vif_drv.tms = 1;
      end
    SHIFT:
      begin
        if (this.temp_req.data_sz > 0)
          begin
            // this.next_state = SHIFT;
            jtag_vif_drv.tdi = this.temp_req.data[this.temp_req.data_sz];
            this.temp_req.data_sz--;
            capture_tdo = 1;
          end
        else
          begin
            // this.next_state = EXIT;
            // drive last bit to tdi
            jtag_vif_drv.tdi = this.temp_req.data[this.temp_req.data_sz];
            jtag_vif_drv.tms = 1;
          end
      end
    EXIT:
      begin
        // this.next_state = UPDATE;
        jtag_vif_drv.tms = 1;
        capture_tdo = 0;
      end
    UPDATE:
      begin
        // this.next_state = IDLE;
        this.exit = 1;
      end
    default:
      jtag_vif_drv.tms = 0;
  endcase // case (this.current_state)
  
endfunction // drive_tms_dr


// compute tms based on current state
function void jtag_driver::drive_tms_ir();
  
  this.exit = 0;
  
  jtag_vif_drv.tms = 0;
  case (this.current_state)
    IDLE:
      begin
        // this.next_state = SELECT_DR;
        jtag_vif_drv.tms = 1;
      end
    SELECT_DR:
      begin
        // this.next_state = SELECT_IR;
        jtag_vif_drv.tms = 1;
      end
    SHIFT:
      begin
        if (this.temp_req.instr_sz > 0)
          begin
            // this.next_state = SHIFT;
            jtag_vif_drv.tdi = this.temp_req.instr[this.temp_req.instr_sz];
            this.temp_req.instr_sz--;
          end
        else
          begin
            // this.next_state = EXIT;
            // drive last bit to tdi
            jtag_vif_drv.tdi = this.temp_req.instr[this.temp_req.instr_sz];
            jtag_vif_drv.tms = 1;
          end
      end
    EXIT:
      begin
        // this.next_state = UPDATE;
        jtag_vif_drv.tms = 1;
      end
    UPDATE:
      begin
        // this.next_state = IDLE;
        this.exit = 1;
      end
    default:
      jtag_vif_drv.tms = 0;
  endcase // case (this.current_state)
  
endfunction // drive_tms_ir

// compute next state based on tms
function void jtag_driver::compute_state(bit tms);
  
  case (this.current_state)
    RESET:
      begin 
        if(tms == 0) 
          this.next_state = IDLE;
      end
    IDLE: 
      begin
        if(tms == 1) 
          this.next_state = SELECT_DR;
      end
    SELECT_DR: 
      begin
        if(tms == 1) 
          this.next_state = SELECT_IR;
        else
          this.next_state = CAPTURE;
      end
    SELECT_IR: 
      begin
        if(tms == 1)
          this.next_state = RESET;
        else
          this.next_state = CAPTURE;
      end
    CAPTURE: 
      begin
        if(tms == 1)
          this.next_state = EXIT;
        else
          this.next_state = SHIFT;
      end
    SHIFT: 
      begin
        if(tms == 1)
          this.next_state = EXIT;
      end
    EXIT:
      begin
        if(tms == 1)
          this.next_state = UPDATE;
        else
          this.next_state = PAUSE;
      end
    PAUSE:
      begin
        if(tms == 1)
          this.next_state = EXIT2;
      end
    EXIT2:
      begin
        if(tms == 1)
          this.next_state = UPDATE;
        else
          this.next_state = SHIFT;
      end
    UPDATE:
      begin
        if(tms == 1)
          this.next_state = SELECT_DR;
        else
          this.next_state = IDLE;
      end
  endcase
  
endfunction // compute_state

`endif
