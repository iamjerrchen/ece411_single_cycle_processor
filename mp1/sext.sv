module sext #(parameter in_width = 1,
				parameter out_width = 32)
(
	input [in_width-1:0] in,
	output logic [out_width-1:0] out
);

logic [out_width-(in_width+1):0] sign;
assign sign = -1;

always_comb begin
	if(in[in_width-1] == 1'b1) out = {sign, in};
	else begin
		out = 0;
		out = out + in;
	end
end

endmodule : sext