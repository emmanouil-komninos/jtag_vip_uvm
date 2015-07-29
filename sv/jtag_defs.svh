`ifndef JTAG_DEFS__SVH
 `define JTAG_DEFS__SVH

typedef enum bit [0:3] {
                        EXTEST = 'h0, SAMPLE_PREL = 'h1, 
                        IDCODE = 'h2, DEBIG = 'h8,
                        MBIST = 'h9, BYPASS = 'hF} jtag_instr_registers;

typedef enum {X, RESET, IDLE, 
              SELECT_DR, SELECT_IR, 
              CAPTURE_DR, CAPTURE_IR, 
              SHIFT_DR, SHIFT_IR, 
              EXIT_DR, EXIT_IR, 
              EXIT2_DR, EXIT2_IR, 
              PAUSE_DR, PAUSE_IR, 
              UPDATE_DR, UPDATE_IR} tap_state;

`endif
