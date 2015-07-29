`ifndef JTAG_COLLECTOR__SVH
 `define JTAG_COLLECTOR__SVH

// extract bus signal info and translates it into transactions
class jtag_collector extends uvm_component;
  
  `uvm_component_utils(jtag_collector)
  
  uvm_analysis_port #(jtag_receive_packet) item_collected_port;
  jtag_vif jtag_vif_col;
  
  tap_state current_state = X;
 
  bit dr_shifted_out = 0;
  bit ir_shifted_out = 0;
  
  jtag_receive_packet col_rsp;
  
  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction // new

  virtual function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    item_collected_port = new("item_collected_port",this);
  endfunction // build_phase

  virtual function void connect_phase (uvm_phase phase);
    super.connect_phase(phase);
    
    `uvm_info("JTAG_COLLECTOR_INFO","Driver Connect phase",UVM_LOW)
    
    if (!uvm_config_db#(jtag_vif)::get(this, get_full_name(), "jtag_virtual_if", jtag_vif_col))
      // equivalent : if (!uvm_config_db#(jtag_vif)::get(this, "", "jtag_virtual_if", jtag_vif_col))
      // equivalent : if (!uvm_config_db#(jtag_vif)::get(null, get_full_name(), "jtag_virtual_if", jtag_vif_col))
      `uvm_fatal("JTAG_COLLECTOR_FATAL", "Virtual interface is null")
    else
      `uvm_info("JTAG_COLLECTOR_INFO", {"VIF is set for: ", get_full_name()},UVM_LOW )
    
  endfunction // connect_phase

  extern virtual task run_phase(uvm_phase phase);
  extern function void compute_state();
  
endclass // jtag_collector

task jtag_collector::run_phase(uvm_phase phase);
  
  col_rsp = jtag_receive_packet::type_id::create("col_rsp");
  
  forever
    begin
      @jtag_vif_col.jtag_tb_mod.tb_ck;
      compute_state();
      if (dr_shifted_out & ir_shifted_out)
        begin
          item_collected_port.write(col_rsp);
          dr_shifted_out = 0;
          ir_shifted_out = 0;
        end
    end
  
endtask // run_phase

// compute next state based on tms
function void jtag_collector::compute_state();
  
  case (this.current_state)
    X:
      begin 
        if(jtag_vif_col.jtag_tb_mod.tb_ck.tms == 1) 
          this.current_state = RESET;
      end
    RESET:
      begin 
        if(jtag_vif_col.jtag_tb_mod.tb_ck.tms == 0) 
          this.current_state = IDLE;
      end
    IDLE: 
      begin
        if(jtag_vif_col.jtag_tb_mod.tb_ck.tms == 1) 
          this.current_state = SELECT_DR;
      end
    SELECT_DR: 
      begin
        if(jtag_vif_col.jtag_tb_mod.tb_ck.tms == 1) 
          this.current_state = SELECT_IR;
        else
          this.current_state = CAPTURE_DR;
      end
    SELECT_IR: 
      begin
        if(jtag_vif_col.jtag_tb_mod.tb_ck.tms == 1)
          this.current_state = RESET;
        else
          this.current_state = CAPTURE_IR;
      end
    CAPTURE_DR: 
      begin
        if(jtag_vif_col.jtag_tb_mod.tb_ck.tms == 1)
          this.current_state = EXIT_DR;
        else
          this.current_state = SHIFT_DR;
      end
    CAPTURE_IR: 
      begin
        if(jtag_vif_col.jtag_tb_mod.tb_ck.tms == 1)
          this.current_state = EXIT_IR;
        else
          this.current_state = SHIFT_IR;
      end
    SHIFT_DR: 
      begin
        col_rsp.data = {jtag_vif_col.jtag_tb_mod.tb_ck.tdo, col_rsp.data[31:1]};
        if(jtag_vif_col.jtag_tb_mod.tb_ck.tms == 1)
          begin
            this.current_state = EXIT_DR;
          end
      end
    SHIFT_IR: 
      begin
        col_rsp.instr = {jtag_vif_col.jtag_tb_mod.tb_ck.tdo, col_rsp.instr[3:1]};
        if(jtag_vif_col.jtag_tb_mod.tb_ck.tms == 1)
          begin
            this.current_state = EXIT_IR;
          end
      end
    EXIT_DR:
      begin   
        col_rsp.data = {jtag_vif_col.jtag_tb_mod.tb_ck.tdo, col_rsp.data[31:1]};   
        dr_shifted_out = 1;  
        if(jtag_vif_col.jtag_tb_mod.tb_ck.tms == 1)
          this.current_state = UPDATE_DR;
        else
          this.current_state = PAUSE_DR;
      end
    EXIT_IR:
      begin
        col_rsp.instr = {jtag_vif_col.jtag_tb_mod.tb_ck.tdo, col_rsp.instr[3:1]};
        ir_shifted_out = 1;
        if(jtag_vif_col.jtag_tb_mod.tb_ck.tms == 1)
          this.current_state = UPDATE_IR;
        else
          this.current_state = PAUSE_IR;
      end
    PAUSE_DR:
      begin
        if(jtag_vif_col.jtag_tb_mod.tb_ck.tms == 1)
          this.current_state = EXIT2_DR;
      end
    PAUSE_IR:
      begin
        if(jtag_vif_col.jtag_tb_mod.tb_ck.tms == 1)
          this.current_state = EXIT2_IR;
      end
    EXIT2_DR:
      begin
        if(jtag_vif_col.jtag_tb_mod.tb_ck.tms == 1)
          this.current_state = UPDATE_DR;
        else
          this.current_state = SHIFT_DR;
      end
    EXIT2_IR:
      begin
        if(jtag_vif_col.jtag_tb_mod.tb_ck.tms == 1)
          this.current_state = UPDATE_IR;
        else
          this.current_state = SHIFT_IR;
      end
    UPDATE_DR, UPDATE_IR:
      begin
        if(jtag_vif_col.jtag_tb_mod.tb_ck.tms == 1)
          this.current_state = SELECT_DR;
        else
          this.current_state = IDLE;
      end
  endcase
  
endfunction // compute_state

`endif
