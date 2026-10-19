// tb_cpu: Phase 3 self-checking test program for the ALU class model (FR-013, D-015).
//
// Every expected value comes from Phase 1, never from this file's own judgement:
//   ../phase 1/ALU_Golden_Vectors.csv     read at run time; no copy is kept in Phase 3
//   ../phase 1/ALU_Design_Decisions.csv   D-xxx, cited at each check that uses one
//   ../phase 1/alu_spec.json              operation semantics behind the reference model
// Each check is counted under the Phase 1 test (TC-xxx) it belongs to. verification_plan.md
// section 4 maps every TC to the task below that tests it.
//
// Plusargs: +GOLDEN=<file>      golden vectors (default ../phase 1/ALU_Golden_Vectors.csv)
//           +SEED=<n>           random seed (default 1)
//           +RANDOM_N=<n>       random transactions (default 2000)
//           +CHECKER_SELFTEST   corrupts the first checked value; the run must then FAIL

program automatic tb_cpu;
  import cpu_pkg::*;

  localparam byte CR = 8'h0D, LF = 8'h0A;

  // ---------------------------------------------------------------- check bookkeeping

  int pass_n[29], fail_n[29];  // indexed by TC number, 1..28
  bit corrupt_next;            // +CHECKER_SELFTEST

  function string two_digits(int n);
    return (n < 10) ? $sformatf("0%0d", n) : $sformatf("%0d", n);
  endfunction

  function string tc_id(int tc);  // "TC-004", as Phase 1 writes it
    return {"TC-0", two_digits(tc)};
  endfunction

  function void check(int tc, string what, int got, int expected);
    if (corrupt_next) begin
      got = ~got;
      corrupt_next = 0;
    end
    if (got == expected) pass_n[tc]++;
    else begin
      fail_n[tc]++;
      $display("FAIL %s %s: got %0d (32'h%h), expected %0d (32'h%h)",
               tc_id(tc), what, got, got, expected, expected);
    end
  endfunction

  function void check_text(int tc, string what, string got, string expected);
    if (got == expected) pass_n[tc]++;
    else begin
      fail_n[tc]++;
      $display("FAIL %s %s: got \"%s\", expected \"%s\"", tc_id(tc), what, got, expected);
    end
  endfunction

  // Phase 1 test that covers each operation (ALU_Verification_Requirements.csv)
  function int tc_of(alu_op_t op);
    case (op)
      OP_AND:   return 6;
      OP_OR:    return 7;
      OP_XOR:   return 8;
      OP_SHL:   return 9;
      OP_SHR:   return 10;
      OP_ROL:   return 11;
      OP_ROR:   return 12;
      OP_SEL_B: return 13;
      OP_INC_B: return 14;
      OP_DEC_B: return 15;
      OP_ADD:   return 16;
      OP_ADDC:  return 17;
      OP_SUB:   return 18;
      OP_SUBB:  return 19;
      default:  return 0;
    endcase
  endfunction

  // ---------------------------------------------------------------- coverage
  // Bins from verification_plan.md section 7. A bin counts the checked Calc calls that hit it.

  int cov[string];

  function void cov_init();
    alu_op_t carry_ops[4] = '{OP_ADD, OP_ADDC, OP_SUB, OP_SUBB};
    alu_op_t shift_ops[4] = '{OP_SHL, OP_SHR, OP_ROL, OP_ROR};
    string   amounts[4]   = '{"B[4:0]=0", "B[4:0]=1..30", "B[4:0]=31", "B[31:5]!=0"};
    for (int i = 0; i < 16; i++) cov[$sformatf("opcode %b", 4'(i))] = 0;
    foreach (carry_ops[i]) begin
      cov[{carry_ops[i].name(), " carry out 0"}] = 0;
      cov[{carry_ops[i].name(), " carry out 1"}] = 0;
    end
    cov["OP_ADDC carry in 0"] = 0;
    cov["OP_ADDC carry in 1"] = 0;
    cov["OP_SUBB carry in 0"] = 0;
    cov["OP_SUBB carry in 1"] = 0;
    foreach (shift_ops[i])
      foreach (amounts[j]) cov[{shift_ops[i].name(), " ", amounts[j]}] = 0;
  endfunction

  function string amount_bin(int b);  // D-003: the amount is B[4:0]
    if (b[31:5] != 0) return "B[31:5]!=0";
    if (b[4:0] == 0) return "B[4:0]=0";
    if (b[4:0] == 31) return "B[4:0]=31";
    return "B[4:0]=1..30";
  endfunction

  function void cov_hit(string key);
    if (cov.exists(key)) cov[key]++;  // names that are not a bin are ignored
  endfunction

  function void cov_sample(logic [3:0] code, int b, bit carry_in, bit carry_out);
    alu_op_t op   = alu_op_t'(code);
    string   name = op.name();
    cov_hit($sformatf("opcode %b", code));
    cov_hit($sformatf("%s carry in %0d", name, carry_in));
    cov_hit($sformatf("%s carry out %0d", name, carry_out));
    cov_hit({name, " ", amount_bin(b)});
  endfunction

  function int cov_report();  // returns the number of bins never hit
    int hit = 0;
    foreach (cov[key])
      if (cov[key] > 0) hit++;
      else $display("COVERAGE HOLE %s", key);
    $display("COVERAGE %0d/%0d bins hit", hit, cov.num());
    return cov.num() - hit;
  endfunction

  // ---------------------------------------------------------------- Phase 1 golden vectors

  typedef struct packed {
    int      num;          // "Vector #"
    alu_op_t op;           // "Code"
    int      a;
    int      b;
    bit      carry_in;
    int      result;       // "Expected result"
    bit      carry_given;  // 0 when "Expected carry" is "unchanged"
    bit      carry;
  } vector_t;

  vector_t gv[$];

  function bit expected_carry(vector_t v);
    return v.carry_given ? v.carry : v.carry_in;
  endfunction

  typedef string fields_t[$];

  // Splits one CSV line at commas. Only the last column (Note) can hold quoted commas, and
  // it is not used, so a plain split is enough for the columns read here.
  function fields_t split_csv(string line);
    fields_t f;
    int start = 0;
    for (int i = 0; i < line.len(); i++)
      if (line[i] == "," || line[i] == CR || line[i] == LF) begin
        f.push_back(line.substr(start, i - 1));
        start = i + 1;
        if (line[i] != ",") return f;
      end
    f.push_back(line.substr(start, line.len() - 1));
    return f;
  endfunction

  // Columns: Vector #, Operation, Code, A, B, Carry in, Expected result, Result hex,
  //          Expected carry, Note
  function void load_vectors(string path);
    int      fd;
    string   line;
    fields_t f;
    fd = $fopen(path, "r");
    if (fd == 0) $fatal(1, "cannot open %s (Phase 1 golden vectors)", path);
    void'($fgets(line, fd));  // header row
    while ($fgets(line, fd) > 0) begin
      vector_t v;
      alu_op_t op;
      string   code_bits;
      int      num, a, b, result;
      f = split_csv(line);
      if (f.size() < 9) continue;  // blank line
      if (f[2].len() != 7 || f[2].substr(0, 2) != "4'b")
        $fatal(1, "golden vector %s: Code '%s' is not 4'bxxxx. Ask Phase 1.", f[0], f[2]);
      code_bits = f[2].substr(3, 6);
      op        = alu_op_t'(4'(code_bits.atobin()));
      void'($sscanf(f[0], "%d", num));
      void'($sscanf(f[3], "%d", a));
      void'($sscanf(f[4], "%d", b));
      void'($sscanf(f[6], "%d", result));
      v.num         = num;
      v.op          = op;
      v.a           = a;
      v.b           = b;
      v.carry_in    = (f[5] == "1");
      v.result      = result;
      v.carry_given = (f[8] != "unchanged");
      v.carry       = (f[8] == "1");
      gv.push_back(v);
      // TC-024 (FR-011, D-001): the DUT enum gives this code the name Phase 1 uses
      check_text(24, {"alu_op_t name of ", f[2]}, op.name(), f[1]);
    end
    $fclose(fd);
    if (gv.size() == 0) $fatal(1, "no golden vectors in %s", path);
  endfunction

  // ---------------------------------------------------------------- reference model
  // Written from alu_spec.json "operations" and "data_semantics" (D-002 to D-006, D-017),
  // independently of the Phase 2 code. carry is the arithmetic_alu flag; only ADD, ADDC,
  // SUB and SUBB change it.

  localparam longint unsigned MAX_U32 = 64'hFFFF_FFFF;

  function void model(alu_op_t op, int a, int b, bit carry_in,
                      output int result, output bit carry_out);
    longint unsigned ua  = {32'b0, a};  // operands as unsigned 32-bit values
    longint unsigned ub  = {32'b0, b};
    bit [31:0]       u   = a;           // A as a bit pattern
    bit [63:0]       uu  = {u, u};      // rotates read a 32-bit window of two copies
    int              amt = b[4:0];      // D-003
    carry_out = carry_in;
    case (op)
      OP_SEL_B: result = b;              // OP-001, D-017
      OP_INC_B: result = b + 1;          // OP-002, wraps (D-004)
      OP_DEC_B: result = b - 1;          // OP-003, wraps (D-004)
      OP_ADD: begin                      // OP-004
        result    = int'(ua + ub);
        carry_out = (ua + ub) > MAX_U32;
      end
      OP_ADDC: begin                     // OP-005, D-005
        result    = int'(ua + ub + carry_in);
        carry_out = (ua + ub + carry_in) > MAX_U32;
      end
      OP_SUB: begin                      // OP-006, D-006: carry = borrow out
        result    = int'(ua - ub);
        carry_out = ua < ub;
      end
      OP_SUBB: begin                     // OP-007, D-006
        result    = int'(ua - ub - carry_in);
        carry_out = ua < ub + carry_in;
      end
      OP_AND: result = a & b;            // OP-008
      OP_OR:  result = a | b;            // OP-009
      OP_XOR: result = a ^ b;            // OP-010
      OP_SHL: result = int'(u << amt);   // OP-011
      OP_SHR: result = int'(u >> amt);   // OP-012, logical (D-004)
      OP_ROL: result = int'(uu >> (32 - amt));  // OP-013
      OP_ROR: result = int'(uu >> amt);         // OP-014
      default: $fatal(1, "model called with invalid code %0d", op);
    endcase
  endfunction

  // The model is used only after it reproduces every Phase 1 golden vector.
  function void check_model();
    foreach (gv[i]) begin
      int r;
      bit c;
      model(gv[i].op, gv[i].a, gv[i].b, gv[i].carry_in, r, c);
      // Fix the model to match alu_spec.json; if the two Phase 1 files contradict each
      // other, ask Phase 1. Never edit the vector.
      if (r != gv[i].result || c != expected_carry(gv[i]))
        $fatal(1, "reference model disagrees with Phase 1 golden vector %0d", gv[i].num);
    end
  endfunction

  // ---------------------------------------------------------------- helpers

  // D-007 state: A = 0, B = 0, alu_op = OP_SEL_B, alu_result = 0
  function void check_d007(int tc, string who, base_alu x);
    check(tc, {who, " operand_A = 0 (D-007)"}, x.operand_A, 0);
    check(tc, {who, " operand_B = 0 (D-007)"}, x.operand_B, 0);
    check(tc, {who, " alu_op = OP_SEL_B (D-007)"}, x.alu_op, OP_SEL_B);
    check(tc, {who, " alu_result = 0 (D-007)"}, x.alu_result, 0);
  endfunction

  function void make_dirty(base_alu x);
    x.load_operand_A(5);
    x.load_operand_B(7);
    x.alu_op     = OP_XOR;
    x.alu_result = 99;
  endfunction

  function string state_of(CPU cpu);
    return $sformatf("a_alu A=%0d B=%0d op=%0d result=%0d carry=%0b, l_alu A=%0d B=%0d op=%0d result=%0d",
                     cpu.a_alu.operand_A, cpu.a_alu.operand_B, cpu.a_alu.alu_op,
                     cpu.a_alu.alu_result, cpu.a_alu.get_carry(),
                     cpu.l_alu.operand_A, cpu.l_alu.operand_B, cpu.l_alu.alu_op,
                     cpu.l_alu.alu_result);
  endfunction

  // One operand in four is a corner value (int limits, shift amounts 31 and 32); the rest
  // are uniform.
  function int random_operand();
    int corners[7] = '{0, 1, -1, 31, 32, 32'h7FFF_FFFF, 32'h8000_0000};
    if ($urandom_range(3) == 0) return corners[$urandom_range(6)];
    return $urandom();
  endfunction

  // ---------------------------------------------------------------- tests, by Phase 1 TC

  // TC-001 (FR-001, D-001, D-004): base_alu has operand_A, operand_B and alu_result as int
  // (32-bit, signed) and alu_op as the 4-bit alu_op_t.
  task automatic tc001_properties();
    base_alu x = new();
    check(1, "operand_A is 32 bits", $bits(x.operand_A), 32);
    check(1, "operand_B is 32 bits", $bits(x.operand_B), 32);
    check(1, "alu_result is 32 bits", $bits(x.alu_result), 32);
    check(1, "alu_op is 4 bits", $bits(x.alu_op), 4);
    x.operand_A  = -1;
    x.operand_B  = -1;
    x.alu_result = -1;
    check(1, "operand_A is signed", x.operand_A < 0, 1);
    check(1, "operand_B is signed", x.operand_B < 0, 1);
    check(1, "alu_result is signed", x.alu_result < 0, 1);
  endtask

  // TC-002 / TC-003 (FR-002, FR-003, D-011): load_operand_A/B store the value given.
  // 17 and -4 are the Phase 1 example inputs; the others are the int limits.
  task automatic tc002_tc003_load();
    int      vals[5] = '{17, -4, 0, 32'h7FFF_FFFF, 32'h8000_0000};
    base_alu x       = new();
    foreach (vals[i]) begin
      x.load_operand_A(vals[i]);
      check(2, $sformatf("load_operand_A(%0d)", vals[i]), x.operand_A, vals[i]);
      x.load_operand_B(vals[i]);
      check(3, $sformatf("load_operand_B(%0d)", vals[i]), x.operand_B, vals[i]);
    end
  endtask

  // TC-004 (FR-004, D-007, D-018): new() and initialize() give the D-007 state in every ALU
  // class, and carry = 0 in arithmetic_alu.
  task automatic tc004_initialize();
    base_alu       x = new();
    logical_alu    l = new();
    arithmetic_alu a = new();
    check_d007(4, "base_alu after new()", x);
    check_d007(4, "logical_alu after new()", l);
    check_d007(4, "arithmetic_alu after new()", a);
    check(4, "arithmetic_alu carry after new()", a.get_carry(), 0);
    make_dirty(x);
    x.initialize();
    check_d007(4, "base_alu after initialize()", x);
    make_dirty(l);
    l.initialize();
    check_d007(4, "logical_alu after initialize()", l);
    make_dirty(a);
    a.set_carry(1);
    a.initialize();
    check_d007(4, "arithmetic_alu after initialize()", a);
    check(4, "arithmetic_alu carry after initialize()", a.get_carry(), 0);
  endtask

  // TC-005 (FR-005, D-010): display() prints "[<class>] op=<name> A=<n> B=<n> result=<n>".
  // A program cannot read its own output, so it prints the text it expects after
  // EXPECT-DISPLAY, and run.sh checks that a display() line contains that text.
  function void expect_display(base_alu x, string cls, alu_op_t op, int a, int b, int r);
    x.load_operand_A(a);
    x.load_operand_B(b);
    x.alu_op     = op;
    x.alu_result = r;
    $display("EXPECT-DISPLAY [%s] op=%s A=%0d B=%0d result=%0d", cls, op.name(), a, b, r);
    x.display();
  endfunction

  task automatic tc005_display();
    base_alu       x = new();
    logical_alu    l = new();
    arithmetic_alu a = new();
    expect_display(x, "base_alu", OP_SEL_B, 1, 2, 3);
    expect_display(l, "logical_alu", OP_AND, 12, 10, 8);
    expect_display(a, "arithmetic_alu", OP_SUB, -5, 4, -9);
  endtask

  // TC-006 to TC-019: every golden vector through CPU.Calc (D-012). carry is state (Phase 2
  // review flag F2), so each vector first sets it to the vector's "Carry in".
  task automatic golden_vectors();
    CPU cpu = new();
    foreach (gv[i]) begin
      vector_t v  = gv[i];
      alu_op_t op = v.op;
      string   id = $sformatf("GV-%s %s A=%0d B=%0d carry_in=%0b",
                              two_digits(v.num), op.name(), v.a, v.b, v.carry_in);
      int      r;
      cpu.a_alu.set_carry(v.carry_in);
      r = cpu.Calc(v.a, v.b, v.op);
      check(tc_of(v.op), {id, " result"}, r, v.result);
      check(tc_of(v.op), {id, " carry"}, cpu.a_alu.get_carry(), expected_carry(v));
      cov_sample(v.op, v.b, v.carry_in, expected_carry(v));
    end
  endtask

  // TC-006 to TC-019: random calls through CPU.Calc, compared with the reference model.
  // carry is never reset between calls, so carry chains from one call to the next are
  // checked too. Invalid codes are tested only in TC-027.
  task automatic random_test(int n);
    CPU cpu = new();
    for (int i = 0; i < n; i++) begin
      alu_op_t op       = alu_op_t'(4'($urandom_range(13)));
      int      a        = random_operand();
      int      b        = random_operand();
      bit      carry_in = cpu.a_alu.get_carry();  // checked after the previous call
      string   id       = $sformatf("random #%0d %s A=%0d B=%0d carry_in=%0b",
                                    i, op.name(), a, b, carry_in);
      int      expected, r;
      bit      expected_c;
      model(op, a, b, carry_in, expected, expected_c);
      r = cpu.Calc(a, b, op);
      check(tc_of(op), {id, " result"}, r, expected);
      check(tc_of(op), {id, " carry"}, cpu.a_alu.get_carry(), expected_c);
      cov_sample(op, b, carry_in, expected_c);
    end
  endtask

  // TC-020 (FR-008, D-018): CPU has l_alu (logical_alu) and a_alu (arithmetic_alu), built by
  // CPU.new(). The two assignments compile only with those member types.
  task automatic tc020_members();
    CPU            cpu = new();
    logical_alu    l   = cpu.l_alu;
    arithmetic_alu a   = cpu.a_alu;
    check(20, "l_alu built by CPU.new()", l != null, 1);
    check(20, "a_alu built by CPU.new()", a != null, 1);
  endtask

  // TC-021 (FR-009, D-008): Reset() returns both ALUs to the D-007 state with carry = 0 and
  // keeps the same objects.
  task automatic tc021_reset();
    CPU            cpu = new();
    logical_alu    l   = cpu.l_alu;
    arithmetic_alu a   = cpu.a_alu;
    void'(cpu.Calc(5, 7, OP_ADD));
    void'(cpu.Calc(5, 7, OP_XOR));
    cpu.a_alu.set_carry(1);
    cpu.Reset();
    check_d007(21, "a_alu after Reset()", cpu.a_alu);
    check(21, "a_alu carry after Reset()", cpu.a_alu.get_carry(), 0);
    check_d007(21, "l_alu after Reset()", cpu.l_alu);
    check(21, "Reset() keeps the l_alu object", cpu.l_alu == l, 1);
    check(21, "Reset() keeps the a_alu object", cpu.a_alu == a, 1);
  endtask

  // TC-022 / TC-023 (FR-010, D-012): Calc loads A, B and the code into the ALU that owns the
  // code (4'b0000-4'b0110 a_alu, 4'b0111-4'b1101 l_alu), returns that ALU's alu_result and
  // leaves the other ALU alone. The Phase 1 examples are checked first.
  task automatic tc022_tc023_dispatch();
    CPU cpu;
    cpu = new();
    check(22, "Calc(7, 5, OP_ADD)", cpu.Calc(7, 5, OP_ADD), 12);
    cpu = new();
    check(23, "Calc(12, 10, OP_AND)", cpu.Calc(12, 10, OP_AND), 8);
    for (int code = 0; code < 14; code++) begin
      alu_op_t op = alu_op_t'(4'(code));
      int      tc = (code <= 4'b0110) ? 22 : 23;
      int      r;
      base_alu used, other;
      cpu = new();
      r   = cpu.Calc(3, 1, op);
      if (code <= 4'b0110) begin
        used  = cpu.a_alu;
        other = cpu.l_alu;
      end else begin
        used  = cpu.l_alu;
        other = cpu.a_alu;
      end
      check(tc, {op.name(), ": routed ALU operand_A"}, used.operand_A, 3);
      check(tc, {op.name(), ": routed ALU operand_B"}, used.operand_B, 1);
      check(tc, {op.name(), ": routed ALU alu_op"}, used.alu_op, op);
      check(tc, {op.name(), ": Calc returns routed alu_result"}, r, used.alu_result);
      check_d007(tc, {op.name(), ": other ALU untouched,"}, other);
    end
  endtask

  // TC-024 (FR-011, D-001): alu_op_t has the 14 listed codes. The name of each code is
  // checked against the golden vectors' Operation column in load_vectors().
  task automatic tc024_enum();
    alu_op_t e;
    check(24, "alu_op_t has 14 members", e.num(), 14);
  endtask

  // TC-025 (FR-012, D-014): cpu_pkg compiles and its definitions resolve through the package.
  task automatic tc025_package();
    cpu_pkg::base_alu       x   = new();
    cpu_pkg::logical_alu    l   = new();
    cpu_pkg::arithmetic_alu a   = new();
    cpu_pkg::CPU            cpu = new();
    check(25, "cpu_pkg::base_alu", x != null, 1);
    check(25, "cpu_pkg::logical_alu", l != null, 1);
    check(25, "cpu_pkg::arithmetic_alu", a != null, 1);
    check(25, "cpu_pkg::CPU", cpu != null, 1);
    check(25, "cpu_pkg::alu_op_t is 4 bits", $bits(cpu_pkg::alu_op_t), 4);
  endtask

  // TC-027 (FR-010, D-009): codes 4'b1110 and 4'b1111 make Calc return 0 and change no ALU
  // state. Calc also reports each one with $error; run.sh checks those two log lines.
  task automatic tc027_invalid();
    CPU cpu = new();
    for (int code = 4'b1110; code <= 4'b1111; code++) begin
      string before;
      int    r;
      void'(cpu.Calc(9, 4, OP_SUB));  // known state in both ALUs
      void'(cpu.Calc(12, 10, OP_AND));
      before = state_of(cpu);
      r      = cpu.Calc(1, 2, alu_op_t'(4'(code)));
      check(27, $sformatf("Calc(1, 2, 4'b%b) returns 0", 4'(code)), r, 0);
      check_text(27, $sformatf("4'b%b changes no ALU state", 4'(code)), state_of(cpu), before);
      cov_sample(4'(code), 2, 0, 0);
    end
  endtask

  // TC-028 (FR-002 to FR-004, D-007): initialize() clears operands loaded before it, and
  // loads after it stick.
  task automatic tc028_load_then_initialize();
    base_alu x = new();
    x.load_operand_A(11);
    x.load_operand_B(22);
    x.initialize();
    check(28, "operand_A cleared by initialize()", x.operand_A, 0);
    check(28, "operand_B cleared by initialize()", x.operand_B, 0);
    x.load_operand_A(33);
    x.load_operand_B(44);
    check(28, "operand_A loaded after initialize()", x.operand_A, 33);
    check(28, "operand_B loaded after initialize()", x.operand_B, 44);
  endtask

  // ---------------------------------------------------------------- summary

  function void report();
    int    failures = 0, unchecked = 0, holes;
    string st;
    $display("SUMMARY per Phase 1 test (TC-005 is checked by run.sh from this log)");
    for (int tc = 1; tc <= 28; tc++) begin
      if (tc == 5) continue;
      if (fail_n[tc] > 0) st = "FAIL";
      else if (pass_n[tc] > 0) st = "PASS";
      else st = "NOT-CHECKED";
      $display("%s %s pass=%0d fail=%0d", tc_id(tc), st, pass_n[tc], fail_n[tc]);
      failures += fail_n[tc];
      if (pass_n[tc] + fail_n[tc] == 0) unchecked++;
    end
    holes = cov_report();
    if (failures == 0 && unchecked == 0 && holes == 0) $display("RESULT PASS");
    else $display("RESULT FAIL (%0d failed checks, %0d tests not checked, %0d coverage holes)",
                  failures, unchecked, holes);
  endfunction

  initial begin
    string       golden;
    int unsigned seed;
    int          n;
    golden = "../phase 1/ALU_Golden_Vectors.csv";
    seed   = 1;
    n      = 2000;
    void'($value$plusargs("GOLDEN=%s", golden));
    void'($value$plusargs("SEED=%d", seed));
    void'($value$plusargs("RANDOM_N=%d", n));
    corrupt_next = $test$plusargs("CHECKER_SELFTEST");
    void'($urandom(seed));
    $display("tb_cpu: golden=%s seed=%0d random_n=%0d checker_selftest=%0b",
             golden, seed, n, corrupt_next);

    cov_init();
    load_vectors(golden);
    check_model();
    $display("tb_cpu: %0d golden vectors read; reference model agrees with all of them", gv.size());

    tc001_properties();
    tc002_tc003_load();
    tc004_initialize();
    tc005_display();
    golden_vectors();
    random_test(n);
    tc020_members();
    tc021_reset();
    tc022_tc023_dispatch();
    tc024_enum();
    tc025_package();
    tc027_invalid();
    tc028_load_then_initialize();
    // TC-026 (FR-013, D-015): this program imported cpu_pkg and exercised CPU and every ALU
    // class. Reaching this line is the check.
    check(26, "test program ran every section", 1, 1);

    report();
    $finish;
  end

endprogram : tb_cpu
