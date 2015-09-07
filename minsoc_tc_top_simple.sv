
`include "uvm_macros.svh"
`include "jtag_if.svh"
    
module minsoc_tc_top;
  import uvm_pkg::*;
  import jtag_tb_pkg::*;
  
  reg clk = 0;
  reg reset = 0;
  
  jtag_if jtag_interface(clk);
  jtag_test test;
  
  initial
    begin
      run_test();
    end

   initial
     begin
       uvm_config_db#(jtag_vif)::set(null,"uvm_test_top","jtag_virtual_if",jtag_interface);       
     end

  initial
    begin 
      forever #10 clk = ~clk;
    end
  
   initial
    begin 
      #5 reset = ~reset;
    end 
  
  minsoc_top minsoc(
                    .clk(clk), 
                    .reset(reset), 
                    .jtag_tdi(jtag_interface.tdi),
                    .jtag_tms(jtag_interface.tms),
                    .jtag_tck(clk),
                    .jtag_tdo(jtag_interface.tdo),
                    .jtag_vref(jtag_interface.vref),
                    .jtag_gnd(jtag_interface.gnd)
                    );
  
endmodule
