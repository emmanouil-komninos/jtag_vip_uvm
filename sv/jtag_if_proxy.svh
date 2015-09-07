`ifndef JTAG_IF_PROXY__SVH
 `define JTAG_IF_PROXY__SVH

virtual class jtag_if_proxy;
  
  pure virtual function void set_tdi(bit tdi);
 
  // pure virtual function void set_tms(bit tms);
      
  // pure virtual function bit get_tdo();
        
endclass // jtag_if_proxy

`endif
