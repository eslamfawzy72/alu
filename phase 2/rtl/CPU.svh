
class CPU;

    // @IF-009 @FR-008
    logical_alu l_alu;

    // @IF-010 @FR-008
    arithmetic_alu a_alu;

    // @D-018
    extern function new();

    // @IF-011 @FR-009
    extern function void Reset();

    // @IF-012 @FR-010 @D-012
    extern function int Calc(input int in1, input int in2, input alu_op_t operation);

endclass

function CPU::new();
    // @FR-008 @D-018
    l_alu = new();
    a_alu = new();
    Reset();
endfunction

function void CPU::Reset();
    // @FR-009 @D-008
    if (l_alu == null)
        l_alu = new();

    if (a_alu == null)
        a_alu = new();

    l_alu.initialize();
    a_alu.initialize();
endfunction

function int CPU::Calc(input int in1, input int in2, input alu_op_t operation);
    // @FR-010 @D-012
    if (l_alu == null)
        l_alu = new();

    if (a_alu == null)
        a_alu = new();

    if (operation <= OP_SUBB) begin
        a_alu.load_operand_A(in1);
        a_alu.load_operand_B(in2);
        a_alu.alu_op = operation;
        a_alu.execute();
        return a_alu.alu_result;
    end
    else if (operation <= OP_ROR) begin
        l_alu.load_operand_A(in1);
        l_alu.load_operand_B(in2);
        l_alu.alu_op = operation;
        l_alu.execute();
        return l_alu.alu_result;
    end
    else begin
        // @D-009
        $warning("CPU.Calc received unsupported opcode %04b", operation);
        return 0;
    end
end
