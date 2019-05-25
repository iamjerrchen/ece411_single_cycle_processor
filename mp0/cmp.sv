import rv32i_types::*;

module cmp
(
    input branch_funct3_t cmpop,
	 input rv32i_word op1,
    input rv32i_word op2,
    output logic br_en
);

always_comb
begin
    br_en = 1'b0;
    case (cmpop)
	    beq: // equal
			begin
				if(op1 == op2)
					br_en = 1'b1;
			end
	    bne: // not equal
			begin
				if(op1 != op2)
					br_en = 1'b1;
			end
		 blt: // less than (signed)
			begin
				if($signed(op1) < $signed(op2))
					br_en = 1'b1;
			end
	    bge: // greater-or-equal (signed)
			begin
				if($signed(op1) >= $signed(op2))
					br_en = 1'b1;
			end
	    bltu: // less than (unsigned)
			begin
				if(op1 < op2)
					br_en = 1'b1;
			end
		 bgeu: // greater-or-equal (unsigned)
			begin
				if(op1 >= op2)
					br_en = 1'b1;
			end
		 default: ;
    endcase
end

endmodule : cmp