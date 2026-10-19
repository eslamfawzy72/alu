// TEST EQUIPMENT ONLY. This is not Phase 2 design or evidence of DUT correctness.
// Use to smoke-test testbench comparisons and failure detection.
class mock_bitwise_adapter extends alu_dut_adapter;
  import alu_tb_pkg::*;
  function new(); endfunction
  virtual function bit connected();return 1;endfunction
  virtual function int calculate(input int a,input int b,input bit[3:0] op);
    int r;
    case(op)
      4'h7:r=a & b;
      4'h8:r=a | b;
      4'h9:r=a ^ b;
      default:$fatal(1,"Mock invoked for undefined operation %h",op);
    endcase
    // +INJECT_AND_BUG is intentional mutation; scoreboard must fail.
    if(op==4'h7 && $test$plusargs("INJECT_AND_BUG"))r=~r;
    return r;
  endfunction
endclass
