module tag_cmp #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index
)
(
    input logic [s_tag-1:0] addr_tag,
	 input logic [s_tag-1:0] tag_out,
	 output logic out
);

always_comb
begin
	if(addr_tag == tag_out) out = 1'd1;
	else out = 1'd0;
end

endmodule : tag_cmp