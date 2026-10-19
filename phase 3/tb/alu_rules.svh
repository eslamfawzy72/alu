// Verification policy, NOT a declaration of the specification.
// Set each macro to 1 only after a documented Phase 1 clarification.
`ifndef ALU_RULES_SVH
`define ALU_RULES_SVH
`ifndef P3_ENABLE_SELECT_B
 `define P3_ENABLE_SELECT_B 0
`endif
`ifndef P3_ENABLE_INC_DEC
 `define P3_ENABLE_INC_DEC 0
`endif
`ifndef P3_ENABLE_ADD
 `define P3_ENABLE_ADD 0
`endif
`ifndef P3_ENABLE_SUB
 `define P3_ENABLE_SUB 0
`endif
`ifndef P3_ENABLE_CARRY
 `define P3_ENABLE_CARRY 0
`endif
`ifndef P3_ENABLE_BORROW
 `define P3_ENABLE_BORROW 0
`endif
`ifndef P3_ENABLE_SHIFTS
 `define P3_ENABLE_SHIFTS 0
`endif
`ifndef P3_ENABLE_ROTATES
 `define P3_ENABLE_ROTATES 0
`endif
// Interpretation switches are irrelevant until corresponding ENABLE is 1.
`ifndef P3_SHIFT_BY_B
 `define P3_SHIFT_BY_B 1
`endif
`ifndef P3_SHR_ARITHMETIC
 `define P3_SHR_ARITHMETIC 0
`endif
`ifndef P3_SUB_B_MINUS_A
 `define P3_SUB_B_MINUS_A 0
`endif
`ifndef P3_CARRY_IN
 `define P3_CARRY_IN 0
`endif
`ifndef P3_BORROW_IN
 `define P3_BORROW_IN 0
`endif
`endif
