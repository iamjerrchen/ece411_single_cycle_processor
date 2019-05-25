module zext_1b #(parameter width = 32)
(
	input in,
	output [width-1:0] out
);

	assign out = {31'd0, in};

endmodule : zext_1b