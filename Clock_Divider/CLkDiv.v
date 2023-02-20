module ClkDiv 
(
	input  wire 	  i_ref_clk,
	input  wire 	  i_rst_n,
	input  wire 	  i_clk_en,
	input  wire [4:0] i_div_ratio,
	output reg  	  o_div_clk
);

reg  [4:0] counter;
wire  [3:0] shift;
reg  	   counter_flag;
reg        output_div;
wire odd;

assign odd = (i_div_ratio[0])? 1'b1:1'b0;
assign shift  = i_div_ratio >> 1;

// sequential clk_divider
always @(posedge i_ref_clk , negedge i_rst_n) begin

	if (!i_rst_n) begin
		output_div   <= 0;
		counter_flag <= 0;
	end
	else if (!counter) begin	
		output_div <= ~output_div;
	end
	// even counter
	else if (counter == shift && !odd) begin	
		output_div <= ~output_div;
	end
	// odd counter
	else if ( (counter == shift && odd && !counter_flag) || (counter == (shift + 1) && odd && counter_flag) ) begin
		
		output_div   <= ~output_div;
		counter_flag <= ~counter_flag;
	end

end

// syncronous counter
always @(posedge i_ref_clk , negedge i_rst_n) begin

	if(!i_rst_n) begin
		counter <= 0;
	end
	else if (counter == shift && !odd) begin		
		counter <= 1;
	end
	else if ((counter == shift && odd && !counter_flag) || (counter == (shift + 1) && odd && counter_flag)) begin	
		counter <= 1;
	end
	else if (i_clk_en) begin
		counter <= counter + 1;
	end
end

// enable signal
always @(*) begin
	
	if (!i_clk_en || i_div_ratio == 1 || i_div_ratio == 0) begin
		o_div_clk = i_ref_clk;
	end
	else begin
		o_div_clk = output_div;
	end
end

endmodule // ClkDiv
