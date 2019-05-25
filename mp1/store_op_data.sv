import rv32i_types::*;

module store_op_data
(
	input rv32i_word rs2_out, // input data
	input logic [1:0] mem_offset,
	
	output rv32i_word sb_d,
	output rv32i_word sh_d,
	output rv32i_word sw_d
);

logic [7:0] LSB_byte; 
logic [15:0] LSB_half;

assign LSB_byte = rs2_out[7:0];
assign LSB_half = rs2_out[15:0];

always_comb
begin
	sb_d = 32'd0 + LSB_byte;
	if(mem_offset == 2'b00) sb_d[7:0] = LSB_byte;
	else if(mem_offset == 2'b01) sb_d[15:8] = LSB_byte;
	else if(mem_offset == 2'b10) sb_d[23:16] = LSB_byte;
	else sb_d[31:24] = LSB_byte;
end

always_comb
begin
	sh_d = 32'd0;
	if(mem_offset == 2'b10) sh_d[31:16] = LSB_half;
	else sh_d[15:0] = LSB_half;
end

assign sw_d = rs2_out;

endmodule : store_op_data