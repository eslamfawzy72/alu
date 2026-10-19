// Smoke test: 37 Phase 1 golden vectors + Reset + invalid codes + display. Uses only spec interfaces (Calc, Reset, get_carry, set_carry).
module smoke_tb;
  import cpu_pkg::*;

  CPU cpu;
  int r, pass_n = 0, fail_n = 0;
  bit c_before;
  base_alu b;

  task automatic check(string id, string what, int got, int exp);
    if (got === exp) begin pass_n++; $display("PASS %s %s = %0d", id, what, got); end
    else begin fail_n++; $display("FAIL %s %s: got %0d expected %0d", id, what, got, exp); end
  endtask

  initial begin
    cpu = new();
    // GV-01 OP_SEL_B A=5 B=23 carry_in=0 (basic)
    cpu.a_alu.set_carry(1'b0);
    r = cpu.Calc(int'(32'h00000005), int'(32'h00000017), OP_SEL_B);
    check("GV-01", "result", r, int'(32'h00000017));
    check("GV-01", "carry", int'(cpu.a_alu.get_carry()), 0);
    // GV-02 OP_INC_B A=0 B=9 carry_in=0 (basic)
    cpu.a_alu.set_carry(1'b0);
    r = cpu.Calc(int'(32'h00000000), int'(32'h00000009), OP_INC_B);
    check("GV-02", "result", r, int'(32'h0000000A));
    check("GV-02", "carry", int'(cpu.a_alu.get_carry()), 0);
    // GV-03 OP_INC_B A=0 B=2147483647 carry_in=0 (max int wraps to min)
    cpu.a_alu.set_carry(1'b0);
    r = cpu.Calc(int'(32'h00000000), int'(32'h7FFFFFFF), OP_INC_B);
    check("GV-03", "result", r, int'(32'h80000000));
    check("GV-03", "carry", int'(cpu.a_alu.get_carry()), 0);
    // GV-04 OP_INC_B A=0 B=-1 carry_in=0 (-1 + 1 = 0)
    cpu.a_alu.set_carry(1'b0);
    r = cpu.Calc(int'(32'h00000000), int'(32'hFFFFFFFF), OP_INC_B);
    check("GV-04", "result", r, int'(32'h00000000));
    check("GV-04", "carry", int'(cpu.a_alu.get_carry()), 0);
    // GV-05 OP_DEC_B A=0 B=9 carry_in=0 (basic)
    cpu.a_alu.set_carry(1'b0);
    r = cpu.Calc(int'(32'h00000000), int'(32'h00000009), OP_DEC_B);
    check("GV-05", "result", r, int'(32'h00000008));
    check("GV-05", "carry", int'(cpu.a_alu.get_carry()), 0);
    // GV-06 OP_DEC_B A=0 B=-2147483648 carry_in=0 (min int wraps to max)
    cpu.a_alu.set_carry(1'b0);
    r = cpu.Calc(int'(32'h00000000), int'(32'h80000000), OP_DEC_B);
    check("GV-06", "result", r, int'(32'h7FFFFFFF));
    check("GV-06", "carry", int'(cpu.a_alu.get_carry()), 0);
    // GV-07 OP_ADD A=7 B=5 carry_in=0 (basic)
    cpu.a_alu.set_carry(1'b0);
    r = cpu.Calc(int'(32'h00000007), int'(32'h00000005), OP_ADD);
    check("GV-07", "result", r, int'(32'h0000000C));
    check("GV-07", "carry", int'(cpu.a_alu.get_carry()), 0);
    // GV-08 OP_ADD A=-1 B=1 carry_in=0 (unsigned carry out)
    cpu.a_alu.set_carry(1'b0);
    r = cpu.Calc(int'(32'hFFFFFFFF), int'(32'h00000001), OP_ADD);
    check("GV-08", "result", r, int'(32'h00000000));
    check("GV-08", "carry", int'(cpu.a_alu.get_carry()), 1);
    // GV-09 OP_ADD A=2147483647 B=1 carry_in=0 (signed overflow, no carry)
    cpu.a_alu.set_carry(1'b0);
    r = cpu.Calc(int'(32'h7FFFFFFF), int'(32'h00000001), OP_ADD);
    check("GV-09", "result", r, int'(32'h80000000));
    check("GV-09", "carry", int'(cpu.a_alu.get_carry()), 0);
    // GV-10 OP_ADD A=7 B=5 carry_in=1 (carry in ignored)
    cpu.a_alu.set_carry(1'b1);
    r = cpu.Calc(int'(32'h00000007), int'(32'h00000005), OP_ADD);
    check("GV-10", "result", r, int'(32'h0000000C));
    check("GV-10", "carry", int'(cpu.a_alu.get_carry()), 0);
    // GV-11 OP_ADDC A=7 B=5 carry_in=1 (carry in used)
    cpu.a_alu.set_carry(1'b1);
    r = cpu.Calc(int'(32'h00000007), int'(32'h00000005), OP_ADDC);
    check("GV-11", "result", r, int'(32'h0000000D));
    check("GV-11", "carry", int'(cpu.a_alu.get_carry()), 0);
    // GV-12 OP_ADDC A=-1 B=0 carry_in=1 (carry in causes carry out)
    cpu.a_alu.set_carry(1'b1);
    r = cpu.Calc(int'(32'hFFFFFFFF), int'(32'h00000000), OP_ADDC);
    check("GV-12", "result", r, int'(32'h00000000));
    check("GV-12", "carry", int'(cpu.a_alu.get_carry()), 1);
    // GV-13 OP_ADDC A=7 B=5 carry_in=0 (carry 0 equals ADD)
    cpu.a_alu.set_carry(1'b0);
    r = cpu.Calc(int'(32'h00000007), int'(32'h00000005), OP_ADDC);
    check("GV-13", "result", r, int'(32'h0000000C));
    check("GV-13", "carry", int'(cpu.a_alu.get_carry()), 0);
    // GV-14 OP_SUB A=9 B=4 carry_in=0 (basic)
    cpu.a_alu.set_carry(1'b0);
    r = cpu.Calc(int'(32'h00000009), int'(32'h00000004), OP_SUB);
    check("GV-14", "result", r, int'(32'h00000005));
    check("GV-14", "carry", int'(cpu.a_alu.get_carry()), 0);
    // GV-15 OP_SUB A=4 B=9 carry_in=0 (negative result, borrow out)
    cpu.a_alu.set_carry(1'b0);
    r = cpu.Calc(int'(32'h00000004), int'(32'h00000009), OP_SUB);
    check("GV-15", "result", r, int'(32'hFFFFFFFB));
    check("GV-15", "carry", int'(cpu.a_alu.get_carry()), 1);
    // GV-16 OP_SUB A=9 B=4 carry_in=1 (borrow in ignored)
    cpu.a_alu.set_carry(1'b1);
    r = cpu.Calc(int'(32'h00000009), int'(32'h00000004), OP_SUB);
    check("GV-16", "result", r, int'(32'h00000005));
    check("GV-16", "carry", int'(cpu.a_alu.get_carry()), 0);
    // GV-17 OP_SUBB A=9 B=4 carry_in=1 (borrow in used)
    cpu.a_alu.set_carry(1'b1);
    r = cpu.Calc(int'(32'h00000009), int'(32'h00000004), OP_SUBB);
    check("GV-17", "result", r, int'(32'h00000004));
    check("GV-17", "carry", int'(cpu.a_alu.get_carry()), 0);
    // GV-18 OP_SUBB A=0 B=0 carry_in=1 (0 - 0 - 1 borrows)
    cpu.a_alu.set_carry(1'b1);
    r = cpu.Calc(int'(32'h00000000), int'(32'h00000000), OP_SUBB);
    check("GV-18", "result", r, int'(32'hFFFFFFFF));
    check("GV-18", "carry", int'(cpu.a_alu.get_carry()), 1);
    // GV-19 OP_SUBB A=9 B=4 carry_in=0 (borrow 0 equals SUB)
    cpu.a_alu.set_carry(1'b0);
    r = cpu.Calc(int'(32'h00000009), int'(32'h00000004), OP_SUBB);
    check("GV-19", "result", r, int'(32'h00000005));
    check("GV-19", "carry", int'(cpu.a_alu.get_carry()), 0);
    // GV-20 OP_AND A=12 B=10 carry_in=0 (basic)
    cpu.a_alu.set_carry(1'b0);
    r = cpu.Calc(int'(32'h0000000C), int'(32'h0000000A), OP_AND);
    check("GV-20", "result", r, int'(32'h00000008));
    check("GV-20", "carry", int'(cpu.a_alu.get_carry()), 0);
    // GV-21 OP_AND A=-1 B=3855 carry_in=0 (mask)
    cpu.a_alu.set_carry(1'b0);
    r = cpu.Calc(int'(32'hFFFFFFFF), int'(32'h00000F0F), OP_AND);
    check("GV-21", "result", r, int'(32'h00000F0F));
    check("GV-21", "carry", int'(cpu.a_alu.get_carry()), 0);
    // GV-22 OP_OR A=12 B=10 carry_in=0 (basic)
    cpu.a_alu.set_carry(1'b0);
    r = cpu.Calc(int'(32'h0000000C), int'(32'h0000000A), OP_OR);
    check("GV-22", "result", r, int'(32'h0000000E));
    check("GV-22", "carry", int'(cpu.a_alu.get_carry()), 0);
    // GV-23 OP_XOR A=12 B=10 carry_in=0 (basic)
    cpu.a_alu.set_carry(1'b0);
    r = cpu.Calc(int'(32'h0000000C), int'(32'h0000000A), OP_XOR);
    check("GV-23", "result", r, int'(32'h00000006));
    check("GV-23", "carry", int'(cpu.a_alu.get_carry()), 0);
    // GV-24 OP_XOR A=-1 B=-1 carry_in=0 (x ^ x = 0)
    cpu.a_alu.set_carry(1'b0);
    r = cpu.Calc(int'(32'hFFFFFFFF), int'(32'hFFFFFFFF), OP_XOR);
    check("GV-24", "result", r, int'(32'h00000000));
    check("GV-24", "carry", int'(cpu.a_alu.get_carry()), 0);
    // GV-25 OP_SHL A=1 B=4 carry_in=0 (basic)
    cpu.a_alu.set_carry(1'b0);
    r = cpu.Calc(int'(32'h00000001), int'(32'h00000004), OP_SHL);
    check("GV-25", "result", r, int'(32'h00000010));
    check("GV-25", "carry", int'(cpu.a_alu.get_carry()), 0);
    // GV-26 OP_SHL A=1 B=31 carry_in=0 (into sign bit)
    cpu.a_alu.set_carry(1'b0);
    r = cpu.Calc(int'(32'h00000001), int'(32'h0000001F), OP_SHL);
    check("GV-26", "result", r, int'(32'h80000000));
    check("GV-26", "carry", int'(cpu.a_alu.get_carry()), 0);
    // GV-27 OP_SHL A=5 B=32 carry_in=0 (amount uses B[4:0], 32 -> 0)
    cpu.a_alu.set_carry(1'b0);
    r = cpu.Calc(int'(32'h00000005), int'(32'h00000020), OP_SHL);
    check("GV-27", "result", r, int'(32'h00000005));
    check("GV-27", "carry", int'(cpu.a_alu.get_carry()), 0);
    // GV-28 OP_SHL A=5 B=0 carry_in=0 (amount 0)
    cpu.a_alu.set_carry(1'b0);
    r = cpu.Calc(int'(32'h00000005), int'(32'h00000000), OP_SHL);
    check("GV-28", "result", r, int'(32'h00000005));
    check("GV-28", "carry", int'(cpu.a_alu.get_carry()), 0);
    // GV-29 OP_SHR A=16 B=4 carry_in=0 (basic)
    cpu.a_alu.set_carry(1'b0);
    r = cpu.Calc(int'(32'h00000010), int'(32'h00000004), OP_SHR);
    check("GV-29", "result", r, int'(32'h00000001));
    check("GV-29", "carry", int'(cpu.a_alu.get_carry()), 0);
    // GV-30 OP_SHR A=-2147483648 B=31 carry_in=0 (logical, not arithmetic)
    cpu.a_alu.set_carry(1'b0);
    r = cpu.Calc(int'(32'h80000000), int'(32'h0000001F), OP_SHR);
    check("GV-30", "result", r, int'(32'h00000001));
    check("GV-30", "carry", int'(cpu.a_alu.get_carry()), 0);
    // GV-31 OP_SHR A=-1 B=1 carry_in=0 (zero fill)
    cpu.a_alu.set_carry(1'b0);
    r = cpu.Calc(int'(32'hFFFFFFFF), int'(32'h00000001), OP_SHR);
    check("GV-31", "result", r, int'(32'h7FFFFFFF));
    check("GV-31", "carry", int'(cpu.a_alu.get_carry()), 0);
    // GV-32 OP_ROL A=-2147483647 B=1 carry_in=0 (MSB wraps to LSB)
    cpu.a_alu.set_carry(1'b0);
    r = cpu.Calc(int'(32'h80000001), int'(32'h00000001), OP_ROL);
    check("GV-32", "result", r, int'(32'h00000003));
    check("GV-32", "carry", int'(cpu.a_alu.get_carry()), 0);
    // GV-33 OP_ROL A=1 B=0 carry_in=0 (amount 0)
    cpu.a_alu.set_carry(1'b0);
    r = cpu.Calc(int'(32'h00000001), int'(32'h00000000), OP_ROL);
    check("GV-33", "result", r, int'(32'h00000001));
    check("GV-33", "carry", int'(cpu.a_alu.get_carry()), 0);
    // GV-34 OP_ROL A=305419896 B=8 carry_in=0 (byte rotate)
    cpu.a_alu.set_carry(1'b0);
    r = cpu.Calc(int'(32'h12345678), int'(32'h00000008), OP_ROL);
    check("GV-34", "result", r, int'(32'h34567812));
    check("GV-34", "carry", int'(cpu.a_alu.get_carry()), 0);
    // GV-35 OP_ROR A=1 B=1 carry_in=0 (LSB wraps to MSB)
    cpu.a_alu.set_carry(1'b0);
    r = cpu.Calc(int'(32'h00000001), int'(32'h00000001), OP_ROR);
    check("GV-35", "result", r, int'(32'h80000000));
    check("GV-35", "carry", int'(cpu.a_alu.get_carry()), 0);
    // GV-36 OP_ROR A=3 B=1 carry_in=0 (two bits)
    cpu.a_alu.set_carry(1'b0);
    r = cpu.Calc(int'(32'h00000003), int'(32'h00000001), OP_ROR);
    check("GV-36", "result", r, int'(32'h80000001));
    check("GV-36", "carry", int'(cpu.a_alu.get_carry()), 0);
    // GV-37 OP_ROR A=305419896 B=8 carry_in=0 (byte rotate)
    cpu.a_alu.set_carry(1'b0);
    r = cpu.Calc(int'(32'h12345678), int'(32'h00000008), OP_ROR);
    check("GV-37", "result", r, int'(32'h78123456));
    check("GV-37", "carry", int'(cpu.a_alu.get_carry()), 0);
    // SM-RESET: put non-default state in both ALUs, then Reset (FR-009, D-007, D-008)
    void'(cpu.Calc(5, 7, OP_ADD)); void'(cpu.Calc(5, 7, OP_XOR)); cpu.a_alu.set_carry(1'b1);
    cpu.Reset();
    check("SM-RESET", "a_alu.operand_A", cpu.a_alu.operand_A, 0);
    check("SM-RESET", "a_alu.operand_B", cpu.a_alu.operand_B, 0);
    check("SM-RESET", "a_alu.alu_op", int'(cpu.a_alu.alu_op), int'(OP_SEL_B));
    check("SM-RESET", "a_alu.alu_result", cpu.a_alu.alu_result, 0);
    check("SM-RESET", "a_alu.carry", int'(cpu.a_alu.get_carry()), 0);
    check("SM-RESET", "l_alu.operand_A", cpu.l_alu.operand_A, 0);
    check("SM-RESET", "l_alu.operand_B", cpu.l_alu.operand_B, 0);
    check("SM-RESET", "l_alu.alu_op", int'(cpu.l_alu.alu_op), int'(OP_SEL_B));
    check("SM-RESET", "l_alu.alu_result", cpu.l_alu.alu_result, 0);
    // SM-INV-1110: invalid code returns 0 and changes no ALU state (D-009); expect one $error line
    void'(cpu.Calc(9, 4, OP_SUB)); void'(cpu.Calc(12, 10, OP_AND)); c_before = cpu.a_alu.get_carry();
    r = cpu.Calc(1, 2, alu_op_t'(4'b1110));
    check("SM-INV-1110", "result", r, 0);
    check("SM-INV-1110", "a_alu.alu_result unchanged", cpu.a_alu.alu_result, 5);
    check("SM-INV-1110", "l_alu.alu_result unchanged", cpu.l_alu.alu_result, 8);
    check("SM-INV-1110", "a_alu.carry unchanged", int'(cpu.a_alu.get_carry()), int'(c_before));
    // SM-INV-1111: invalid code returns 0 and changes no ALU state (D-009); expect one $error line
    void'(cpu.Calc(9, 4, OP_SUB)); void'(cpu.Calc(12, 10, OP_AND)); c_before = cpu.a_alu.get_carry();
    r = cpu.Calc(1, 2, alu_op_t'(4'b1111));
    check("SM-INV-1111", "result", r, 0);
    check("SM-INV-1111", "a_alu.alu_result unchanged", cpu.a_alu.alu_result, 5);
    check("SM-INV-1111", "l_alu.alu_result unchanged", cpu.l_alu.alu_result, 8);
    check("SM-INV-1111", "a_alu.carry unchanged", int'(cpu.a_alu.get_carry()), int'(c_before));
    // SM-DISPLAY: display() runs on every ALU class (FR-005, D-010); output is printed, not compared
    b = new(); b.display();
    cpu.l_alu.display();
    cpu.a_alu.display();
    $display("SUMMARY pass=%0d fail=%0d", pass_n, fail_n);
    $finish;
  end
endmodule
