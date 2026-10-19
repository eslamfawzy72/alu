// Driver owns all CPU operation invocations.
class alu_driver;
  import alu_tb_pkg::*;
  alu_dut_adapter dut;
  function new(input alu_dut_adapter binding);dut=binding;endfunction
  function int apply(input alu_txn_t t);return dut.calculate(t.a,t.b,t.op);endfunction
endclass
