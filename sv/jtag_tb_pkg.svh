fndef JTAG_TB_PKG__SVH
 `define JTAG_TB_PKG__SVH

package jtag_tb_pkg;
  
  import uvm_pkg::*;
`include "uvm_macros.svh"
  typedef virtual jtag_if jtag_vif; 
`include "jtag_if_proxy.svh"
`include "jtag_vip.svh"
`include "jtag_test_lib.svh"
  
endpackage // jtag_tb_pkg
  
`endif
