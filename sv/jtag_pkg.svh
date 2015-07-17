`ifndef JTAG_PKG__SVH
 `define JTAG_PKG__SVH

`include "jtag_if.svh"

package jtag_pkg;
  import uvm_pkg::*;
`include "uvm_macros.svh"
  
  typedef virtual jtag_if jtag_vif;
`include "jtag_vip.svh"
`include "jtag_test_lib.svh"
endpackage // jtag_pkg

`endif
