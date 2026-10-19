`include "alu_rules.svh"
package alu_tb_pkg;
  typedef struct packed {int a; int b; bit [3:0] op;} alu_txn_t;
  typedef enum int {P3_NOT_RUN=0, P3_PASS=1, P3_FAIL=2, P3_BLOCKED=3} p3_status_e;

  // Independent expected-value model. Optional interpretations are disabled by default.
  class alu_oracle;
    static function bit predict(input alu_txn_t t, output int expected);
      int unsigned u;
      int unsigned cnt;
      expected=0;
      cnt = (`P3_SHIFT_BY_B != 0) ? (32'(t.b) & 31) : 1;
      case(t.op)
        4'h0: if(`P3_ENABLE_SELECT_B) begin expected=t.b;return 1;end
        4'h1: if(`P3_ENABLE_INC_DEC) begin expected=t.b+1;return 1;end
        4'h2: if(`P3_ENABLE_INC_DEC) begin expected=t.b-1;return 1;end
        4'h3: if(`P3_ENABLE_ADD) begin expected=t.a+t.b;return 1;end
        4'h4: if(`P3_ENABLE_CARRY) begin expected=t.a+t.b+`P3_CARRY_IN;return 1;end
        4'h5: if(`P3_ENABLE_SUB) begin
                 expected=(`P3_SUB_B_MINUS_A != 0) ? t.b-t.a : t.a-t.b;return 1;end
        4'h6: if(`P3_ENABLE_BORROW) begin
                 expected=(`P3_SUB_B_MINUS_A != 0) ? t.b-t.a-`P3_BORROW_IN : t.a-t.b-`P3_BORROW_IN;return 1;end
        4'h7: begin expected=t.a & t.b;return 1;end
        4'h8: begin expected=t.a | t.b;return 1;end
        4'h9: begin expected=t.a ^ t.b;return 1;end
        4'ha: if(`P3_ENABLE_SHIFTS) begin expected=t.a << cnt;return 1;end
        4'hb: if(`P3_ENABLE_SHIFTS) begin
                 expected=(`P3_SHR_ARITHMETIC != 0) ? (t.a >>> cnt) : (int'(32'(t.a) >> cnt));return 1;end
        4'hc: if(`P3_ENABLE_ROTATES) begin
                 u=32'(t.a); expected=int'((u << cnt) | (u >> ((32-cnt)&31)));return 1;end
        4'hd: if(`P3_ENABLE_ROTATES) begin
                 u=32'(t.a); expected=int'((u >> cnt) | (u << ((32-cnt)&31)));return 1;end
        default: ; // invalid opcode policy not approved
      endcase
      return 0;
    endfunction
  endclass

  class alu_coverage;
    int generated[16], compared[16], blocked[16], passed[16], failed[16];
    int directed[16], random_hits[16], zero_a[16], zero_b[16];
    int all_ones[16], equal_ab[16], extreme[16], alternating[16];
    function void sample(input alu_txn_t t,input bit random_kind);
      int i; i=int'(t.op);generated[i]++;
      if(random_kind) random_hits[i]++; else directed[i]++;
      if(t.a==0) zero_a[i]++;if(t.b==0) zero_b[i]++;
      if(t.a==-1 || t.b==-1) all_ones[i]++;
      if(t.a==t.b) equal_ab[i]++;
      if(t.a==32'h80000000 || t.a==32'h7fffffff ||
         t.b==32'h80000000 || t.b==32'h7fffffff) extreme[i]++;
      if(t.a==32'h55555555 || t.b==32'haaaaaaaa) alternating[i]++;
    endfunction
    function void report();
      $display("COVERAGE (stimulus metrics, not functional signoff)");
      for(int i=0;i<16;i++)
        $display("OP=%0h generated=%0d compared=%0d pass=%0d fail=%0d blocked=%0d directed=%0d random=%0d zeroA=%0d zeroB=%0d allOnes=%0d equal=%0d extreme=%0d alternating=%0d",
          i,generated[i],compared[i],passed[i],failed[i],blocked[i],directed[i],random_hits[i],zero_a[i],zero_b[i],all_ones[i],equal_ab[i],extreme[i],alternating[i]);
    endfunction
  endclass

  class alu_scoreboard;
    int pass_count=0, fail_count=0, blocked_count=0, not_run_count=0;
    int api_pass=0,api_fail=0,api_blocked=0;
    function void compare(input alu_txn_t t,input int actual,input int expected,input alu_coverage c);
      int i;i=int'(t.op); c.compared[i]++;
      if(actual === expected) begin pass_count++;c.passed[i]++;end
      else begin fail_count++;c.failed[i]++;
        $error("MISMATCH op=%h A=%h B=%h got=%h expected=%h",t.op,t.a,t.b,actual,expected);end
    endfunction
    function void blocked(input alu_txn_t t,input alu_coverage c);
      blocked_count++;c.blocked[int'(t.op)]++;
    endfunction
    function void api(input string name,input p3_status_e status);
      case(status)
        P3_PASS: api_pass++;
        P3_FAIL: begin api_fail++;$error("API FAIL: %s",name);end
        default: begin api_blocked++;$display("API BLOCKED: %s",name);end
      endcase
    endfunction
    function void report();
      $display("SUMMARY FUNCTIONAL_PASS=%0d FUNCTIONAL_FAIL=%0d BEHAVIOR_BLOCKED=%0d API_PASS=%0d API_FAIL=%0d API_BLOCKED=%0d",
        pass_count,fail_count,blocked_count,api_pass,api_fail,api_blocked);
    endfunction
  endclass
endpackage
