// logical_alu: bitwise, shift and rotate operations, codes 4'b0111 to 4'b1101.
// Binary operations compute A op B. Shifts and rotates move operand_A by
// operand_B[4:0] places. Shift right is logical: zeros fill from the left.

class logical_alu extends base_alu;  // @FR-006

  virtual function string get_name();
    return "logical_alu";
  endfunction

  virtual function void execute();
    // Unsigned copy so >> fills with zeros and rotates see a plain 32-bit pattern
    int unsigned a   = int'(operand_A);            // @D-004
    int unsigned amt = {27'b0, operand_B[4:0]};    // @D-003

    case (alu_op)
      OP_AND: alu_result = operand_A & operand_B;  // @OP-008 @D-002
      OP_OR:  alu_result = operand_A | operand_B;  // @OP-009 @D-002
      OP_XOR: alu_result = operand_A ^ operand_B;  // @OP-010 @D-002
      OP_SHL: alu_result = int'(a << amt);         // @OP-011
      OP_SHR: alu_result = int'(a >> amt);         // @OP-012 @D-004
      // Bits leaving one end re-enter at the other. For amt = 0 the second
      // term shifts by 32, which SystemVerilog defines as 0, so the result is a.
      OP_ROL: alu_result = int'((a << amt) | (a >> (32 - amt)));  // @OP-013
      OP_ROR: alu_result = int'((a >> amt) | (a << (32 - amt)));  // @OP-014
      default: $error("logical_alu: %s is not a logical operation", alu_op.name());
    endcase
  endfunction

endclass : logical_alu
