module even_mask #(parameter width = 32)
(
	input [width-1:0] in,
	output logic [width-1:0] out
);

always_comb begin
	out = in;
	out[0] = 1'b0;
end

endmodule : even_mask