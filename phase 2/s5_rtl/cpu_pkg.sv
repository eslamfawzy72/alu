
package cpu_pkg;

    // @FR-011 @IF-003 @IF-014 @D-001
    typedef enum logic [3:0] {
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

    // @D-014
    `include "base_alu.svh"
    `include "logical_alu.svh"
    `include "arithmetic_alu.svh"
    `include "CPU.svh"

endpackage
