module alu_test;
  import alu_tb_pkg::*;
`ifndef P3_ADAPTER_CLASS
 `define P3_ADAPTER_CLASS alu_dut_adapter
`endif
  alu_dut_adapter dut;alu_driver driver;alu_monitor monitor;
  alu_scoreboard sb;alu_coverage cov;
  int directed_total=0,random_total=0;
  int unsigned rng_state=32'h12345678;
  // Deterministic stimuli independent of simulator-specific random algorithms.
  function automatic int unsigned next_random();
    rng_state=rng_state*32'd1664525+32'd1013904223;return rng_state;
  endfunction
  task automatic run_case(input int a,input int b,input bit[3:0] op,input bit random_kind);
    alu_txn_t t;int expected,actual;bit ready;
    t.a=a;t.b=b;t.op=op;cov.sample(t,random_kind);
    ready=alu_oracle::predict(t,expected);
    if(!ready) begin sb.blocked(t,cov);return;end
    if(!dut.connected()) begin sb.not_run_count++;return;end
    actual=driver.apply(t);monitor.observe(t,actual);sb.compare(t,actual,expected,cov);
  endtask
  task automatic directed_tests();
    for(int i=0;i<14;i++) begin
      run_case(32'h55aa55aa,32'h0f0f0f0f,4'(i),0);directed_total++;
      run_case(0,-1,4'(i),0);directed_total++;
      run_case(-1,32'haaaaaaaa,4'(i),0);directed_total++;
      run_case(0,0,4'(i),0);directed_total++;
      run_case(32'h80000000,32'h7fffffff,4'(i),0);directed_total++;
      run_case(1,-1,4'(i),0);directed_total++;
      run_case(-1,-1,4'(i),0);directed_total++;
      run_case(32'h55555555,32'haaaaaaaa,4'(i),0);directed_total++;
      run_case(32'h7fffffff,1,4'(i),0);directed_total++;
      run_case(12,10,4'(i),0);directed_total++; // Phase 1 TC-006..008 examples
    end
    // Invalid opcodes: negative stimulus only; no pass expectation until Q-009.
    for(int i=14;i<16;i++) begin
      run_case(0,0,4'(i),0);directed_total++;
      run_case(-1,-1,4'(i),0);directed_total++;
    end
  endtask
  task automatic api_tests();
    int v[6]='{0,1,-1,32'h7fffffff,32'h80000000,32'h55aa55aa};
    foreach(v[i]) begin
      sb.api("TC-002 load operand A",dut.load_a(v[i]));
      sb.api("TC-003 load operand B",dut.load_b(v[i]));
    end
    sb.api("TC-020 CPU child objects",dut.handles_exist());
    sb.api("TC-004/028 initialize",dut.initialize_check());
    sb.api("TC-021 CPU Reset",dut.reset_check());
    sb.api("TC-005 display",dut.display_check());
    for(int i=0;i<14;i++)
      sb.api("TC-022/023 CPU routing",dut.routing_check(4'(i)));
  endtask
  initial begin: main
    int random_n;int unsigned a,b,o;bit plan_only;
    random_n=300;
    if($value$plusargs("RANDOM_N=%d",random_n)) begin end
    if($value$plusargs("SEED=%d",rng_state)) begin end
    if(random_n<0 || random_n>10000000) $fatal(1,"invalid RANDOM_N");
    begin
      `P3_ADAPTER_CLASS concrete_dut;
      concrete_dut=new();dut=concrete_dut;
    end
    driver=new(dut);monitor=new();sb=new();cov=new();
    plan_only=$test$plusargs("PLAN_ONLY");
    if(!dut.connected() && !plan_only) $fatal(1,"No DUT bound: use +PLAN_ONLY for stimulus audit, or bind Phase 2");
    // Still generate planned inputs in PLAN_ONLY; never report them as verified.
    if(dut.connected()) api_tests();
    directed_tests();
    repeat(random_n) begin
      o=next_random();a=next_random();b=next_random();
      run_case(int'(a),int'(b),4'(o%14),1);random_total++;
    end
    sb.report();cov.report();
    $display("STIMULUS directed=%0d randomized=%0d monitored=%0d not_run=%0d",
      directed_total,random_total,monitor.observed_count,sb.not_run_count);
    if(!dut.connected()) begin
      $display("NOT VERIFIED: PLAN_ONLY generated stimulus but executed no DUT comparisons");$finish;end
    if(sb.fail_count>0 || sb.api_fail>0) $fatal(1,"REGRESSION FAILED");
    if(sb.pass_count==0) $fatal(1,"NO FUNCTIONAL COMPARISONS COMPLETED");
    if(cov.compared[7]==0 || cov.compared[8]==0 || cov.compared[9]==0)
      $fatal(1,"AND/OR/XOR not exercised");
    $display("ENABLED CHECKS PASSED; BLOCKED checks are NOT verified/sign-off");
    $finish;
  end
endmodule
