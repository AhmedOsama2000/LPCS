module CLKGate (
	input wire CLK,
	input wire Enable,
	output wire gate_clk
);

reg latch_en;

always @(CLK,Enable) begin
	
	if (!CLK) begin
		latch_en <= Enable;
	end

end

assign gate_clk = latch_en && CLK;

// For Physical Design purpose ( From Standard Cell Library)
/*
TLATNCAX12M U0_TLATNCAX12M (
	.E(Enable),
	.CK(CLK),
	.ECK(gate_clk)
);
*/

endmodule
