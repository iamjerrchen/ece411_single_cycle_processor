import rv32i_types::*;

// Formats various values loaded from memory.
module load_op_data
(
	input rv32i_word mdrreg_out,
	input logic [1:0] mem_offset,
	output rv32i_word lb_d,
	output rv32i_word lh_d,
	output rv32i_word lw_d,
	output rv32i_word lbu_d,
	output rv32i_word lhu_d
);

logic [7:0] extract_byte;
logic [15:0] extract_half;

always_comb
begin
	// byte
	if(mem_offset == 2'b00) extract_byte = mdrreg_out[7:0];
	else if(mem_offset == 2'b01) extract_byte = mdrreg_out[15:8];
	else if(mem_offset == 2'b10) extract_byte = mdrreg_out[23:16];
	else extract_byte = mdrreg_out[31:24];
end

always_comb
begin
	// half
	if(mem_offset == 2'b10) extract_half = mdrreg_out[31:16]; // upper half
	else extract_half = mdrreg_out[15:0]; // lower half
end

sext #(.in_width(8)) sext_lb
(
	.in(extract_byte[7:0]),
	.out(lb_d)
);

sext #(.in_width(16)) sext_lh
(
	.in(extract_half[15:0]),
	.out(lh_d)
);

assign lw_d = mdrreg_out;

zext #(.in_width(8)) zext_lbu
(
	.in(extract_byte[7:0]),
	.out(lbu_d)
);

zext #(.in_width(16)) zext_lhu
(
	.in(extract_half[15:0]),
	.out(lhu_d)
);

endmodule : load_op_data