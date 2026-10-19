// arithmetic_alu: select, increment, decrement, add and subtract, codes 4'b0000 to 4'b0110.
// Results wrap modulo 2^32. One carry flag is the carry for adds and the borrow for
// subtracts. Adds and subtracts are computed in 33 bits, so bit 32 is the carry or
// borrow out:
//   add: bit 32 = 1 when A + B (+ carry) does not fit in 32 unsigned bits
//   sub: bit 32 = 1 when A - B (- carry) goes below zero (unsigned A < B + carry)

class arithmetic_alu extends base_alu;  // @FR-007

  bit carry;  // @IF-015 @D-005 @D-006

  virtual function string get_name();
    return "arithmetic_alu";
  endfunction

  virtual function void initialize();
    super.initialize();
    carry = 1'b0;  // @D-007
  endfunction

  function bit get_carry();  // @D-016
    return carry;
  endfunction

  // Lets a test set carry-in directly before ADDC or SUBB
  function void set_carry(bit c);  // @D-005
    carry = c;
  endfunction

  virtual function void display();
    $display("[%s] op=%s A=%0d B=%0d result=%0d carry=%0b",  // @D-010
             get_name(), alu_op.name(), operand_A, operand_B, alu_result, carry);
  endfunction

  virtual function void execute();
    logic [32:0] a   = {1'b0, operand_A};  // @D-004
    logic [32:0] b   = {1'b0, operand_B};
    logic [32:0] cin = {32'b0, carry};
    logic [32:0] wide;

    case (alu_op)
      OP_SEL_B: alu_result = operand_B;      // @OP-001 @D-017
      OP_INC_B: alu_result = operand_B + 1;  // @OP-002
      OP_DEC_B: alu_result = operand_B - 1;  // @OP-003
      OP_ADD: begin                          // @OP-004 @D-002
        wide       = a + b;
        alu_result = int'(wide[31:0]);
        carry      = wide[32];
      end
      OP_ADDC: begin                         // @OP-005 @D-005
        wide       = a + b + cin;
        alu_result = int'(wide[31:0]);
        carry      = wide[32];
      end
      OP_SUB: begin                          // @OP-006 @D-002
        wide       = a - b;
        alu_result = int'(wide[31:0]);
        carry      = wide[32];
      end
      OP_SUBB: begin                         // @OP-007 @D-006
        wide       = a - b - cin;
        alu_result = int'(wide[31:0]);
        carry      = wide[32];
      end
      default: $error("arithmetic_alu: %s is not an arithmetic operation", alu_op.name());
    endcase
  endfunction

endclass : arithmetic_alu
