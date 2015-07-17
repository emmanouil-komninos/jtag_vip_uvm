`ifndef JTAG_IF__SVH
 `define JTAG_IF__SVH

interface jtag_if (input bit tck);

  logic tdi;
  
  logic tdo;
  logic tms;
  logic trst;
  logic vref;
  logic gnd;

  clocking drv_ck @(posedge tck);
    output tdi;
    output tms;
    input  negedge tdo;
    input  vref;
    input  gnd;
  endclocking // drv_ck

  modport jtag_drv_mod (clocking drv_ck);
    
endinterface // jtag_if

`endif
