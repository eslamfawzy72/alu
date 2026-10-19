
class arithmetic_alu extends base_alu;

    // @D-005
    bit carry;

    // @D-006
    bit borrow;

    // @FR-007 @D-013
    extern virtual function void execute();

    // @D-005 @D-006
    function void initialize();
        super.initialize();
        carry = 0;
        borrow = 0;
    endfunction

endclass

function void arithmetic_alu::execute();
    logic [31:0] a_bits;
    logic [31:0] b_bits;
    logic [32:0] wide;
    logic [32:0] b_ext;

    a_bits = operand_A;
    b_bits = operand_B;

    case (alu_op)
        OP_SEL_B: begin
            // @OP-001 @D-017
            alu_result = b_bits;
        end

        OP_INC_B: begin
            // @OP-002
            wide = {1'b0, b_bits} + 33'd1;
            alu_result = wide[31:0];
            carry = wide[32];
        end

        OP_DEC_B: begin
            // @OP-003
            alu_result = b_bits - 32'd1;
            borrow = (b_bits == 32'd0);
        end

        OP_ADD: begin
            // @OP-004
            wide = {1'b0, a_bits} + {1'b0, b_bits};
            alu_result = wide[31:0];
            carry = wide[32];
        end

        OP_ADDC: begin
            // @OP-005 @D-005
            wide = {1'b0, a_bits} + {1'b0, b_bits} + carry;
            alu_result = wide[31:0];
            carry = wide[32];
        end

        OP_SUB: begin
            // @OP-006
            wide = {1'b0, a_bits} - {1'b0, b_bits};
            alu_result = wide[31:0];
            borrow = (a_bits < b_bits);
        end

        OP_SUBB: begin
            // @OP-007 @D-006
            b_ext = {1'b0, b_bits} + borrow;
            wide = {1'b0, a_bits} - b_ext;
            alu_result = wide[31:0];
            borrow = ({1'b0, a_bits} < b_ext);
        end

        default: begin
            alu_result = 0;
        end
    endcase
end
