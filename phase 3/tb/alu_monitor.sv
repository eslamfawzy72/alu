// Monitor records only actual DUT observations, never predicted values.
class alu_monitor;
  import alu_tb_pkg::*;
  int observed_count=0;
  alu_txn_t last_txn;
  int last_result;
  function void observe(input alu_txn_t transaction,input int dut_result);
    observed_count++;last_txn=transaction;last_result=dut_result;
  endfunction
endclass
