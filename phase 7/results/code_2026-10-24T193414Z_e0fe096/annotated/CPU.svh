//      // verilator_coverage annotation
        // CPU: owns one logical and one arithmetic ALU and routes each operation.
        
        class CPU;  // @FR-008
        
          logical_alu    l_alu;  // @IF-009
          arithmetic_alu a_alu;  // @IF-010
        
 000022   function new();
 000022     l_alu = new();  // @D-018
 000022     a_alu = new();  // @D-018
          endfunction
        
          // Returns both ALUs to their initialize() state; the objects are kept
 000001   function void Reset();  // @FR-009 @IF-011
 000001     l_alu.initialize();   // @D-008
 000001     a_alu.initialize();   // @D-008
          endfunction
        
          // Codes 4'b0000-4'b0110 go to a_alu, 4'b0111-4'b1101 to l_alu.
          // Any other code is rejected: no ALU state changes and the result is 0.
 005061   function int Calc(int in1, int in2, alu_op_t operation);  // @FR-010 @IF-012
            base_alu alu;
        
 002543     if (operation inside {[OP_SEL_B : OP_SUBB]}) begin       // @D-012
 002543       alu = a_alu;
 002516     end else if (operation inside {[OP_AND : OP_ROR]}) begin  // @D-012
 002516       alu = l_alu;
            end else begin
              $error("CPU.Calc: invalid operation code 4'b%04b", operation);  // @D-009
              return 0;                                                      // @D-009
            end
        
 005061     alu.load_operand_A(in1);  // @D-002
 005061     alu.load_operand_B(in2);  // @D-002
 005061     alu.alu_op = operation;
 005061     alu.execute();
 005061     return alu.alu_result;
          endfunction
        
        endclass : CPU
        
