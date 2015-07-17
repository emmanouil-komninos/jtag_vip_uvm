`ifndef JTAG_DRIVER__SVH
 `define JTAG_DRIVER__SVH
typedef enum {IDLE, SELECT_DR, SELECT_IR, CAPTURE, SHIFT, EXIT, UPDATE} state;

class jtag_driver extends uvm_driver #(jtag_send_packet);
  
  // configuration component for the driver
  jtag_driver_config jtag_drv_cfg;
  
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
    bit tdi;
    while(1)
      begin
        seq_item_port.get_next_item(req);
        phase.raise_objection(this,"Jtag Driver raised objection");
        req.print();
        
        // tdi = req.instr_reg and 1;
        
        // ir_seq();
        // dr_seq();
        phase.drop_objection(this, "Jtag Driver dropped objection");
        seq_item_port.item_done(req);
      end
    // jtag_vif_drv.trst = 0;
    // @jtag_vif_drv.drv_ck;
    // ir_seq();
    // dr_seq();
    
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

  // function void end_of_elaboration_phase (uvm_phase phase);
  //   print();
  // endfunction // end_of_elaboration_phase
  
endclass // jtag_driver
  
task jtag_driver::dr_seq();
  
  @jtag_vif_drv.drv_ck;
  jtag_vif_drv.tms = 0;
  @jtag_vif_drv.drv_ck;
  jtag_vif_drv.tms = 1;
  current_dr_state = SELECT_DR;
  @jtag_vif_drv.drv_ck;
  jtag_vif_drv.tms = 0;
  current_dr_state = CAPTURE;
  
  repeat(jtag_drv_cfg.data_sz)
    begin
      @jtag_vif_drv.drv_ck;
      current_dr_state = SHIFT;
      jtag_vif_drv.tdi= 1;
    end
  
  @jtag_vif_drv.drv_ck;
  jtag_vif_drv.tms = 1;
  current_dr_state = EXIT;
  @jtag_vif_drv.drv_ck;
  jtag_vif_drv.tms = 1;
  current_dr_state = UPDATE;
  @jtag_vif_drv.drv_ck;
  jtag_vif_drv.tms = 0;
  current_dr_state = IDLE; 
  
endtask // dr_seq
    
task jtag_driver::ir_seq();
  
  @jtag_vif_drv.drv_ck;
  jtag_vif_drv.tms = 0;
  @jtag_vif_drv.drv_ck;
  jtag_vif_drv.tms = 1;
  current_dr_state = SELECT_DR;
  @jtag_vif_drv.drv_ck;
  jtag_vif_drv.tms = 1;
  current_dr_state = SELECT_IR;
  @jtag_vif_drv.drv_ck;
  jtag_vif_drv.tms = 0;
  current_dr_state = CAPTURE;
  
  repeat(jtag_drv_cfg.instr_sz)
    begin
      @jtag_vif_drv.drv_ck;
      current_dr_state = SHIFT;
       jtag_vif_drv.tdi= 1;
    end
  
  @jtag_vif_drv.drv_ck;
  jtag_vif_drv.tms = 1;
  current_dr_state = EXIT;
  @jtag_vif_drv.drv_ck;
  jtag_vif_drv.tms = 1;
  current_dr_state = UPDATE;
  @jtag_vif_drv.drv_ck;
  jtag_vif_drv.tms = 0;
  current_dr_state = IDLE;

endtask // ir_seq
`endif
