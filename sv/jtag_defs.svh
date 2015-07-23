`ifndef JTAG_DEFS__SVH
 `define JTAG_DEFS__SVH

typedef enum bit [0:3] {
                        EXTEST = 'h0, SAMPLE_PREL = 'h1, 
                        IDCODE = 'h2, DEBIG = 'h8,
                        MBIST = 'h9, BYPASS = 'hF} jtag_instr_registers;

`endif
