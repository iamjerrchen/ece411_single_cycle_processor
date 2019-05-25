module zext #(parameter in_width = 1,
				parameter out_width = 32)
(
	input [in_width-1:0] in,
	output logic [out_width-1:0] out
);

always_comb begin
	out = 0;
	out = out + in;
end
	
endmodule : zext