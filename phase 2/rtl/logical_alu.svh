
class logical_alu extends base_alu;

    // @FR-006 @D-013
    extern virtual function void execute();

endclass

function void logical_alu::execute();
    logic [31:0] a_bits;
    logic [31:0] b_bits;
    logic [31:0] result_bits;
    int unsigned shift_amount;

    a_bits = operand_A;
    b_bits = operand_B;
    shift_amount = b_bits[4:0];

    // @OP-008
    // @FR-006
    // @OP-009
    // @OP-010
    // @OP-011
    // @OP-012
    // @OP-013
    // @OP-014
    case (alu_op)
        OP_AND: begin
            alu_result = a_bits & b_bits;
        end

        OP_OR: begin
            alu_result = a_bits | b_bits;
        end

        OP_XOR: begin
            alu_result = a_bits ^ b_bits;
        end

        OP_SHL: begin
            alu_result = a_bits << shift_amount;
        end

        OP_SHR: begin
            alu_result = a_bits >> shift_amount;
        end

        OP_ROL: begin
            if (shift_amount == 0)
                result_bits = a_bits;
            else
                result_bits = (a_bits << shift_amount) |
                              (a_bits >> (32 - shift_amount));
            alu_result = result_bits;
        end

        OP_ROR: begin
            if (shift_amount == 0)
                result_bits = a_bits;
            else
                result_bits = (a_bits >> shift_amount) |
                              (a_bits << (32 - shift_amount));
            alu_result = result_bits;
        end

        default: begin
            alu_result = 0;
        end
    endcase
end
