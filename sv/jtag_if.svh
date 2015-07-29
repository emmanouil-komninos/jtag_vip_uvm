`ifndef JTAG_IF__SVH
 `define JTAG_IF__SVH

interface jtag_if (input bit tck);
  
  logic tdi;
  logic tdo;
  logic tms;
  logic trst;
  logic vref;
  logic gnd;
  
  clocking tb_ck @(posedge tck);
    output tdi;
    inout tms;
    input  negedge tdo;
    input  vref;
    input  gnd;
  endclocking // tb_ck

  modport jtag_tb_mod (clocking tb_ck);
      
endinterface // jtag_if

`endif
