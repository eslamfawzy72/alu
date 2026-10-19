// Phase 2 binding point. All methods are defined as safe unconnected defaults.
// Override in a subclass; construct that subclass in alu_test.sv using P3_ADAPTER_CLASS.
// Do not copy CPU logic or make pass/fail decisions here.
class alu_dut_adapter;
  import alu_tb_pkg::*;
  function new();endfunction
  virtual function bit connected();return 0;endfunction
  virtual function int calculate(input int a,input int b,input bit[3:0] op);
    $fatal(1,"DUT disconnected: adapter.calculate called");return 0;
  endfunction
  // API observation: return P3_NOT_RUN if Phase 2 has not exposed this observation.
  // Return P3_FAIL when an attempted check actually fails; never hide failures.
  virtual function p3_status_e load_a(input int value);return P3_NOT_RUN;endfunction
  virtual function p3_status_e load_b(input int value);return P3_NOT_RUN;endfunction
  virtual function p3_status_e initialize_check();return P3_NOT_RUN;endfunction
  virtual function p3_status_e reset_check();return P3_NOT_RUN;endfunction
  virtual function p3_status_e display_check();return P3_NOT_RUN;endfunction
  virtual function p3_status_e handles_exist();return P3_NOT_RUN;endfunction
  virtual function p3_status_e routing_check(input bit[3:0] op);return P3_NOT_RUN;endfunction
endclass
