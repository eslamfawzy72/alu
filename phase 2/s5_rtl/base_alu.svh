
class base_alu;

    // @IF-001 @FR-001
    int operand_A;

    // @IF-002 @FR-001
    int operand_B;

    // @IF-003 @FR-001 @FR-011
    alu_op_t alu_op;

    // @IF-004 @FR-001
    int alu_result;

    // @D-013
    extern function void load_operand_A(input int value);
    // @D-013
    extern function void load_operand_B(input int value);
    // @D-013
    extern function void initialize();
    // @D-013
    extern function void display();
    // @D-013
    extern virtual function void execute();

endclass

function void base_alu::load_operand_A(input int value);
    // @FR-002 @IF-005
    operand_A = value;
endfunction

function void base_alu::load_operand_B(input int value);
    // @FR-003 @IF-006
    operand_B = value;
endfunction

function void base_alu::initialize();
    // @FR-004 @D-007
    operand_A = 0;
    operand_B = 0;
    alu_op = OP_SEL_B;
    alu_result = 0;
endfunction

function void base_alu::display();
    // @FR-005 @D-010
    $display("[%s] A=%0d B=%0d OP=%s (%04b) RESULT=%0d",
             "base_alu", operand_A, operand_B, alu_op.name(), alu_op, alu_result);
endfunction

virtual function void base_alu::execute();
    // @D-013
    alu_result = 0;
endfunction
