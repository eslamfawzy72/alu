package alu_tb_pkg;
  typedef struct packed {
    int a;
    int b;
    bit [3:0] op;
  } alu_txn_t;

  // Only defined and reviewed expected results may return 1 (checkable).
  // Additional operations remain BLOCKED until their Phase 1 contracts are resolved.
  class alu_oracle;
    static function bit predict(input alu_txn_t t, output int expected);
      case (t.op)
        4'h7: begin expected = t.a & t.b; return 1; end // AND
        4'h8: begin expected = t.a | t.b; return 1; end // OR
        4'h9: begin expected = t.a ^ t.b; return 1; end // XOR
        // Pending Phase 1: select B, INC, DEC, ADD, ADC, SUB, SBB,
        // shifts, rotates, unsupported opcodes, carry, signedness.
        default: begin expected = 0; return 0; end
      endcase
    endfunction
  endclass

  class alu_scoreboard;
    int passed = 0;
    int failed = 0;
    int blocked = 0;
    int attempted[16];
    int checked[16];
    int blocked_by_op[16];

    function void register_blocked(input alu_txn_t t);
      blocked++;
      attempted[int'(t.op)]++;
      blocked_by_op[int'(t.op)]++;
    endfunction
    function void check(input alu_txn_t t, input int actual);
      int exp;
      attempted[int'(t.op)]++;
      if (!alu_oracle::predict(t, exp)) begin
        blocked++;
        blocked_by_op[int'(t.op)]++;
        return;
      end
      checked[int'(t.op)]++;
      if (actual === exp) passed++;
      else begin
        failed++;
        $error("MISMATCH op=%0h A=%08h B=%08h got=%08h exp=%08h",t.op,t.a,t.b,actual,exp);
      end
    endfunction
    function void report();
      $display("CHECKED_PASS=%0d CHECKED_FAIL=%0d BLOCKED=%0d",passed,failed,blocked);
      for (int i=0;i<16;i++)
        $display("OPCODE=%0h ATTEMPTED=%0d CHECKED=%0d BLOCKED=%0d",i,attempted[i],checked[i],blocked_by_op[i]);
    endfunction
  endclass
endpackage
