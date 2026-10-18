module alu_test;
  import alu_tb_pkg::*;
  alu_dut_adapter dut;
  alu_scoreboard sb;
  int directed_total = 0;
  int random_total = 0;

  task automatic run_one(input int a, input int b, input bit [3:0] op);
    alu_txn_t t;
    int actual, expected;
    t.a = a; t.b = b; t.op = op;
    // Don't execute unspecified behavior against a DUT or call it a PASS.
    if (!alu_oracle::predict(t, expected)) begin
      sb.register_blocked(t);
      return;
    end
    actual = dut.calculate(t.a,t.b,t.op);
    sb.check(t, actual);
  endtask

  initial begin : main
    int random_n;
    bit [3:0] op;
    dut = new(); sb = new();
    random_n = 300;
    if ($value$plusargs("RANDOM_N=%d", random_n)) begin end
    if (random_n < 0) $fatal(1,"RANDOM_N must be nonnegative");
    // 14 operations x nominal/boundary/corner = 42 planned scenarios.
    for (int code=0; code<14;code++) begin
      run_one(32'h55AA55AA,32'h0F0F0F0F,4'(code)); directed_total++;
      run_one(32'h00000000,32'hFFFFFFFF,4'(code)); directed_total++;
      run_one(32'hFFFFFFFF,32'hAAAAAAAA,4'(code)); directed_total++;
    end
    // Additional signed, zero and bit-pattern edge cases for every opcode.
    for (int code=0;code<14;code++) begin
      run_one(0,0,4'(code)); directed_total++;
      run_one(32'h80000000,32'h7FFFFFFF,4'(code)); directed_total++;
      run_one(1,-1,4'(code)); directed_total++;
    end
    // Invalid opcode policy is unspecified; record, never pass.
    for (int code=14;code<16;code++) begin
      run_one(0,0,4'(code)); directed_total++;
    end
    repeat (random_n) begin
      op=4'($urandom_range(13,0));
      run_one(int'($urandom),int'($urandom),op);
      random_total++;
    end
    sb.report();
    $display("DIRECTED_TOTAL=%0d RANDOM_TOTAL=%0d",directed_total,random_total);
    // Unconnected adapter intentionally fails if any runnable check is attempted.
    if (sb.failed != 0) $fatal(1,"REGRESSION FAILED");
    if ((sb.checked[7]==0)||(sb.checked[8]==0)||(sb.checked[9]==0))
      $fatal(1,"DEFINED OPCODES MISSING CHECKS");
    $display("REGRESSION PASSED: enabled checks only; BLOCKED items not verified");
    $finish;
  end
endmodule
