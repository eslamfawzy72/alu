
`timescale 1ns/1ps

module tb_alu;

    import cpu_pkg::*;

    CPU cpu;
    logical_alu l_alu;
    arithmetic_alu a_alu;
    int result;
    int errors;

    task automatic check(input string name, input int actual, input int expected);
        if (actual !== expected) begin
            $display("FAIL: %s actual=%0d expected=%0d", name, actual, expected);
            errors++;
        end
        else begin
            $display("PASS: %s -> %0d", name, actual);
        end
    endtask

    initial begin
        errors = 0;

        // @FR-013 @D-015
        cpu = new();
        l_alu = new();
        a_alu = new();

        // Reset and base initialization.
        cpu.Reset();
        check("reset A", cpu.a_alu.operand_A, 0);
        check("reset B", cpu.a_alu.operand_B, 0);
        check("reset result", cpu.a_alu.alu_result, 0);

        // Base setters.
        l_alu.load_operand_A(12);
        l_alu.load_operand_B(10);
        l_alu.alu_op = OP_AND;
        l_alu.execute();
        check("direct AND", l_alu.alu_result, 8);

        // Arithmetic operations.
        check("select B",  cpu.Calc(99, 23, OP_SEL_B), 23);
        check("increment B", cpu.Calc(0, 9, OP_INC_B), 10);
        check("decrement B", cpu.Calc(0, 9, OP_DEC_B), 8);
        check("add", cpu.Calc(7, 5, OP_ADD), 12);
        check("sub", cpu.Calc(9, 4, OP_SUB), 5);

        // Carry chain: FFFFFFFF + 1 sets carry, then ADDC consumes it.
        check("add creates carry", cpu.Calc(32'hffff_ffff, 1, OP_ADD), 0);
        check("add with carry", cpu.Calc(7, 5, OP_ADDC), 13);

        // Borrow chain: 0 - 1 sets borrow, then SUBB consumes it.
        check("sub creates borrow", cpu.Calc(0, 1, OP_SUB), -1);
        check("sub with borrow", cpu.Calc(9, 4, OP_SUBB), 4);

        // Logical operations.
        check("AND", cpu.Calc(12, 10, OP_AND), 8);
        check("OR", cpu.Calc(12, 10, OP_OR), 14);
        check("XOR", cpu.Calc(12, 10, OP_XOR), 6);
        check("shift left", cpu.Calc(3, 2, OP_SHL), 12);
        check("shift right", cpu.Calc(8, 2, OP_SHR), 2);
        check("rotate left", cpu.Calc(32'h8000_0001, 1, OP_ROL), 3);
        check("rotate right", cpu.Calc(32'h8000_0001, 1, OP_ROR), 32'hc000_0000);

        // Invalid opcode policy.
        result = cpu.Calc(0, 0, alu_op_t'(4'b1110));
        check("invalid opcode", result, 0);

        if (errors == 0)
            $display("SMOKE PASS: all ALU cases passed.");
        else
            $display("SMOKE FAIL: %0d case(s) failed.", errors);

        $finish;
    end

endmodule
