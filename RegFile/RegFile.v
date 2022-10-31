module RegFile 
#(
	parameter reg_num      = 16,
	parameter reg_width    = 8,
	parameter ADDR_SIZE    = 4
)
(
	input  wire 					CLK,
	input  wire 					rst_n,
	input  wire 					WrEN,
	input  wire 					RdEN,
	input  wire [reg_width-1:0] 	WrData,
	input  wire [ADDR_SIZE-1:0]  	Address,
	output reg 	[reg_width-1:0] 	Rd_Data,
	output wire	[reg_width-1:0]		REG_0,
	output wire	[reg_width-1:0]		REG_1,
	output wire [reg_width-1:0]		REG_2,
	output wire [reg_width-1:0]		REG_3,
	output reg 						Rd_Data_VLD
);

integer i;
reg [reg_width-1:0] reg_data [reg_num-1:0];

always @(posedge CLK , negedge rst_n) begin
	
	if (!rst_n) begin
		
		for (i = 0;i < reg_num;i = i + 1) begin
			if (i == 2) begin
				// Default: PAR_EN = 1, PAR_TYP = ODD , Prescale = 8
				reg_data[i] <= 'b0_01000_1_1; 
			end
			else if (i == 3) begin
				// Default : Division ratio  = 8
				reg_data[i] <= 'b000_01000;
			end
			else begin
				reg_data[i] <= 'b0;
			end
		end
		Rd_Data <= 0;
		Rd_Data_VLD <= 0;

	end

	else if (WrEN) begin
		reg_data[Address] <= WrData;
		Rd_Data_VLD <= 0;
	end

	else if (RdEN) begin
		Rd_Data <= reg_data[Address];
		Rd_Data_VLD <= 1;
	end
	else begin
		Rd_Data_VLD <= 0;
	end

end

assign REG_0 = reg_data[0];
assign REG_1 = reg_data[1];
assign REG_2 = reg_data[2];
assign REG_3 = reg_data[3];

endmodule 