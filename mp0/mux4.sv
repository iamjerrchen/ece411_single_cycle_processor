module mux4 #(parameter width = 32)
(
	input [1:0] sel,
	input [width-1:0] a, b, c, d,
	output logic [width-1:0] f
);

always_comb
begin
	if(sel == 2'b00)
		f = a;
	else if(sel == 2'b01)
		f = b;
	else if(sel == 2'b10)
		f = c;
	else
		f = d;
end

endmodule : mux4

module mux8 #(parameter width = 32)
(
	input [2:0] sel,
	input [width-1:0] a, b, c, d, e,
	output logic [width-1:0] i
);

always_comb
begin
	if(sel == 3'd0)
		i = a;
	else if(sel == 3'd1)
		i = b;
	else if(sel == 3'd2)
		i = c;
	else if(sel == 3'd3)
		i = d;
	else
		i = e;
end

endmodule : mux8