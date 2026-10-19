// cpu_pkg: everything the CPU needs; the test program imports it.
// Each class is in its own .svh file, included here in build order.
// Trace tags: "// @ID" marks the line that implements a spec ID.

package cpu_pkg;  // @FR-012 @IF-013

  // Operation codes shared by base_alu.alu_op and CPU.Calc
  typedef enum logic [3:0] {  // @FR-011 @IF-014 @D-001
    OP_SEL_B = 4'b0000,
    OP_INC_B = 4'b0001,
    OP_DEC_B = 4'b0010,
    OP_ADD   = 4'b0011,
    OP_ADDC  = 4'b0100,
    OP_SUB   = 4'b0101,
    OP_SUBB  = 4'b0110,
    OP_AND   = 4'b0111,
    OP_OR    = 4'b1000,
    OP_XOR   = 4'b1001,
    OP_SHL   = 4'b1010,
    OP_SHR   = 4'b1011,
    OP_ROL   = 4'b1100,
    OP_ROR   = 4'b1101
  } alu_op_t;

  // Methods are defined inside each class; extern is not used  // @D-013
  `include "base_alu.svh"        // @D-014
  `include "logical_alu.svh"     // @D-014
  `include "arithmetic_alu.svh"  // @D-014
  `include "CPU.svh"             // @D-014

endpackage : cpu_pkg
