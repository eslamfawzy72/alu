// Integration boundary: adapt ONLY this class to Phase 2's actual cpu_pkg.
// No mock DUT, guessed method signature, or implied successful verification.
class alu_dut_adapter;
  function new(); endfunction
  virtual function int calculate(input int a,input int b,input bit [3:0] opcode);
    $fatal(1,"DUT NOT CONNECTED: wire to cpu_pkg::CPU.Calc with actual enum/signature");
    return 0;
  endfunction
endclass
