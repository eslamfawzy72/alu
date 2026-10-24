//      // verilator_coverage annotation
        // arithmetic_alu: select, increment, decrement, add and subtract, codes 4'b0000 to 4'b0110.
        // Results wrap modulo 2^32. One carry flag is the carry for adds and the borrow for
        // subtracts. Adds and subtracts are computed in 33 bits, so bit 32 is the carry or
        // borrow out:
        //   add: bit 32 = 1 when A + B (+ carry) does not fit in 32 unsigned bits
        //   sub: bit 32 = 1 when A - B (- carry) goes below zero (unsigned A < B + carry)
        
 000025 class arithmetic_alu extends base_alu;  // @FR-007
        
          bit carry;  // @IF-015 @D-005 @D-006
        
 000001   virtual function string get_name();
 000001     return "arithmetic_alu";
          endfunction
        
 000002   virtual function void initialize();
 000002     super.initialize();
 000002     carry = 1'b0;  // @D-007
          endfunction
        
 010044   function bit get_carry();  // @D-016
 010044     return carry;
          endfunction
        
          // Lets a test set carry-in directly before ADDC or SUBB
 000040   function void set_carry(bit c);  // @D-005
 000040     carry = c;
          endfunction
        
 000001   virtual function void display();
 000001     $display("[%s] op=%s A=%0d B=%0d result=%0d carry=%0b",  // @D-010
 000001              get_name(), alu_op.name(), operand_A, operand_B, alu_result, carry);
          endfunction
        
 002543   virtual function void execute();
 002543     logic [32:0] a   = {1'b0, operand_A};  // @D-004
 002543     logic [32:0] b   = {1'b0, operand_B};
 002543     logic [32:0] cin = {32'b0, carry};
            logic [32:0] wide;
        
 002543     case (alu_op)
 000391       OP_SEL_B: alu_result = operand_B;      // @OP-001 @D-017
 000341       OP_INC_B: alu_result = operand_B + 1;  // @OP-002
 000372       OP_DEC_B: alu_result = operand_B - 1;  // @OP-003
 000365       OP_ADD: begin                          // @OP-004 @D-002
 000365         wide       = a + b;
 000365         alu_result = int'(wide[31:0]);
 000365         carry      = wide[32];
              end
 000368       OP_ADDC: begin                         // @OP-005 @D-005
 000368         wide       = a + b + cin;
 000368         alu_result = int'(wide[31:0]);
 000368         carry      = wide[32];
              end
 000359       OP_SUB: begin                          // @OP-006 @D-002
 000359         wide       = a - b;
 000359         alu_result = int'(wide[31:0]);
 000359         carry      = wide[32];
              end
 000347       OP_SUBB: begin                         // @OP-007 @D-006
 000347         wide       = a - b - cin;
 000347         alu_result = int'(wide[31:0]);
 000347         carry      = wide[32];
              end
              default: $error("arithmetic_alu: %s is not an arithmetic operation", alu_op.name());
            endcase
          endfunction
        
        endclass : arithmetic_alu
        
