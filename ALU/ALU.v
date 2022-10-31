module ALU
#(
	parameter IN_WIDTH  = 8,
    parameter OUT_WIDTH = IN_WIDTH*2
)
(
	input  wire          	    CLK,
	input  wire				    rst_n,
	input  wire				    ALU_EN,
	input  wire [IN_WIDTH-1:0]  A,
	input  wire [IN_WIDTH-1:0]  B,
	input  wire [3:0] 		    ALU_FUN,
	output reg  [OUT_WIDTH-1:0] ALU_OUT,
	output reg 				    ALU_OUT_VLD
);

reg [OUT_WIDTH-1:0] ALU_result;
reg 			  	ALU_VLD_COMP;

always @(posedge CLK , negedge rst_n) begin

	if (!rst_n) begin
	
		ALU_OUT 	<= 16'b0;
		ALU_OUT_VLD <= 1'b0;

	end
	else begin
		
		ALU_OUT 	<= ALU_result;
		ALU_OUT_VLD <= ALU_VLD_COMP;

	end

end 

always @(*) begin

	if (ALU_EN) begin
		
		ALU_result = 16'h0000;
		ALU_VLD_COMP = 1;

		case (ALU_FUN)

			4'b0000 : begin  ALU_result = A + B; 				       end
			4'b0001 : begin  ALU_result = A - B;  				       end
			4'b0010 : begin  ALU_result = A * B;				       end
			4'b0011 : begin  ALU_result = A / B;				       end

			4'b0100 : begin  ALU_result[(OUT_WIDTH/2)-1:0] = A & B;	   end
			4'b0101 : begin  ALU_result[(OUT_WIDTH/2)-1:0] = A | B;	   end
			4'b0110 : begin  ALU_result[(OUT_WIDTH/2)-1:0] = ~(A & B); end
			4'b0111 : begin  ALU_result[(OUT_WIDTH/2)-1:0] = ~(A | B); end
			4'b1000 : begin  ALU_result[(OUT_WIDTH/2)-1:0] = A ^ B;	   end
			4'b1001 : begin  ALU_result[(OUT_WIDTH/2)-1:0] = ~(A ^ B); end

			4'b1010 : begin  ALU_result = (A == B)? 16'h0001:16'h0000; end
			4'b1011 : begin  ALU_result = (A > B)?  16'h0002:16'h0000; end
			4'b1100 : begin  ALU_result = (A < B)?  16'h0003:16'h0000; end
				
			4'b1101 : begin  ALU_result = A >> 1; 				   	   end
			4'b1110 : begin  ALU_result = A << 1; 				   	   end

			default : begin  ALU_result = 16'h0000; 			   	   end

		endcase 

	end
	else begin
		
		ALU_result = 16'h0000;
		ALU_VLD_COMP = 1'b0;

	end

end

endmodule 



