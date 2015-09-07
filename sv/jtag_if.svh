`ifndef JTAG_IF__SVH
 `define JTAG_IF__SVH

import jtag_tb_pkg::*;

interface jtag_if (input bit tck);
  
  logic tdi;
  logic tdo;
  logic tms;
  logic trst;
  logic vref;
  logic gnd;
  logic test = 'z;

  assign test_bus = test;
  
  clocking tb_ck @(posedge tck);
    output tdi;
    inout tms;
    input  negedge tdo;
    input  vref;
    input  gnd;
    output test;
    
  endclocking // tb_ck

   modport jtag_tb_mod (clocking tb_ck);

    // proxy class extention and instantiation
     class if_proxy extends jtag_tb_pkg::jtag_if_proxy;
       virtual function void set_tdi(bit tdi);
         tb_ck.tdi <= tdi;
       endfunction // set_tdi
     endclass // jtag_if_proxy

    if_proxy proxy = new();
    
endinterface // jtag_if

`endif
