//      // verilator_coverage annotation
        // base_alu: state and methods common to every ALU.
        // Derived classes override execute() with their operations, so CPU.Calc can run
        // either ALU through a base_alu handle.
        
        class base_alu;  // @FR-001
        
          int      operand_A;   // @IF-001
          int      operand_B;   // @IF-002
          alu_op_t alu_op;      // @IF-003
          int      alu_result;  // @IF-004
        
          // Every object starts in the initialize() state
 000056   function new();
 000056     initialize();  // @D-018
          endfunction
        
 005072   function void load_operand_A(int value);  // @FR-002 @IF-005 @D-011
 005072     operand_A = value;
          endfunction
        
 005072   function void load_operand_B(int value);  // @FR-003 @IF-006 @D-011
 005072     operand_B = value;
          endfunction
        
          // Virtual so CPU.Reset() also clears state a derived class adds (carry)
 000062   virtual function void initialize();  // @FR-004 @IF-007 @D-011
 000062     operand_A  = 0;         // @D-007
 000062     operand_B  = 0;         // @D-007
 000062     alu_op     = OP_SEL_B;  // @D-007
 000062     alu_result = 0;         // @D-007
          endfunction
        
          // Name printed by display(); each derived class returns its own
 000001   virtual function string get_name();
 000001     return "base_alu";
          endfunction
        
 000002   virtual function void display();  // @FR-005 @IF-008 @D-011
 000002     $display("[%s] op=%s A=%0d B=%0d result=%0d",  // @D-010
 000002              get_name(), alu_op.name(), operand_A, operand_B, alu_result);
          endfunction
        
          // Computes alu_result from alu_op. base_alu has no operations of its own.
          virtual function void execute();  // @IF-016 @D-012
            $error("%s: execute() has no operations; use logical_alu or arithmetic_alu", get_name());
          endfunction
        
        endclass : base_alu
        
