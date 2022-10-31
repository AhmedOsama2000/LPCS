module SYS_CTRL_RX 
#(
	parameter RX_FRAME_WIDTH = 8,
	parameter ADDRESS_SIZE = 4
)
(
	input  wire						 CLK,
	input  wire 					 rst_n,
	input  wire [RX_FRAME_WIDTH-1:0] RX_P_DATA,
	input  wire 					 RX_D_VLD,
	output reg                       WrEn,
	output reg  [RX_FRAME_WIDTH-1:0] WrData,
	output reg  [ADDRESS_SIZE-1:0]   Address,
	output reg                       RdEn,
	output reg   				 	 Gate_en,
	output reg   					 CLK_Div_EN,
	output reg 	[ADDRESS_SIZE-1:0]   ALU_FUN,
	output reg 						 ALU_EN
);

localparam IDLE 	  = 4'b0000;
localparam CMD_1   	  = 4'b0001;
localparam WRITE_ADDR = 4'b0010;
localparam WRITE_DATA = 4'b0011;

localparam CMD_2   	  = 4'b0100;
localparam READ_ADDR  = 4'b0101;

localparam CMD_3      = 4'b0110;
localparam OPERAND_A  = 4'b0111;
localparam OPERAND_B  = 4'b1000;
localparam FUN_EXC 	  = 4'b1001;

localparam CMD_4      = 4'b1010;


// FSM STATES
reg [3:0] CS;
reg [3:0] NS;

reg done;

// State Memory
always @(posedge CLK,negedge rst_n) begin
	if (!rst_n) begin

		CS <= IDLE;

	end
	else begin
		
		CS <= NS;

	end
end

// next state logic
always @(*) begin
	case(CS)

		IDLE: begin

			if (RX_D_VLD && RX_P_DATA == 8'hAA) begin
				NS = CMD_1;
			end
			else if (RX_D_VLD && RX_P_DATA == 8'hBB) begin			
				NS = CMD_2;
			end
			else if (RX_D_VLD && RX_P_DATA == 8'hCC) begin
				NS = CMD_3;
			end
			else if(RX_D_VLD && RX_P_DATA == 8'hDD) begin
				NS = CMD_4;
			end
			else begin
				NS = IDLE;
			end

		end
		CMD_1: begin

			if (!RX_D_VLD) begin
				NS = CMD_1;
			end
			else begin
				NS = WRITE_ADDR;
			end

		end
		WRITE_ADDR: begin

			if (!RX_D_VLD) begin
				NS = WRITE_ADDR;
			end
			else begin
				NS = WRITE_DATA;
			end

		end
		WRITE_DATA: begin

			if (!done) begin
				NS = WRITE_DATA;
			end
			else begin
				NS = IDLE;
			end

		end
		CMD_2: begin

			if (!RX_D_VLD) begin
				NS = CMD_2;
			end
			else begin
				NS = READ_ADDR;
			end

		end
		READ_ADDR: begin

			if (!done) begin
				NS = WRITE_ADDR;
			end
			else begin
				NS = IDLE;
			end

		end
		CMD_3: begin

			if (!RX_D_VLD) begin
				NS = CMD_3;
			end
			else begin
				NS = OPERAND_A;
			end

		end
		OPERAND_A: begin

			if (!RX_D_VLD) begin
				NS = OPERAND_A;
			end
			else begin
				NS = OPERAND_B;
			end

		end
		OPERAND_B: begin

			if (!RX_D_VLD) begin
				NS = OPERAND_B;
			end
			else begin
				NS = FUN_EXC;
			end

		end
		FUN_EXC: begin

			if (!done) begin
				NS = FUN_EXC;
			end
			else begin
				NS = IDLE;
			end

		end
		CMD_4: begin

			if (!RX_D_VLD) begin
				NS = CMD_4;
			end
			else begin
				NS = FUN_EXC;
			end

		end
		default: NS = IDLE;

	endcase
end

// FSM OUTPUT
always @(*) begin

	WrEn = 0;
	RdEn = 0;
	done = 0;
	ALU_EN = 0;

	// CLK DIV is always ON
	CLK_Div_EN = 1;

	if (CS == WRITE_DATA) begin
		
		WrEn = 1;
		done = 1;

	end
	else if (CS == READ_ADDR) begin
		
		RdEn = 1;
		done = 1;

	end
	else if (CS == OPERAND_A || CS == OPERAND_B) begin
		
		WrEn = 1;

	end	
	else if (CS == FUN_EXC) begin
	
		ALU_EN = 1;
		done  = 1;

	end
	else begin
		
		WrEn = 0;
		RdEn = 0;
		ALU_EN = 0;
		done = 0;

	end


end

always @(posedge CLK,negedge rst_n) begin
	
	if (!rst_n) begin
		
		Address <= 0;
		ALU_FUN <= 0;
		WrData  <= 0;

	end
	else if (NS == WRITE_ADDR || NS == READ_ADDR) begin
		
		Address <= RX_P_DATA[(RX_FRAME_WIDTH/2)-1:0];

	end
	else if (NS == WRITE_DATA) begin
		
		WrData <= RX_P_DATA;

	end
	else if (NS == OPERAND_A) begin
		
		WrData <= RX_P_DATA;
		Address <= 8'b0;

	end
	else if (NS == OPERAND_B) begin
		
		WrData <= RX_P_DATA;
		Address <= 8'b1;

	end
	else if (NS == FUN_EXC) begin
		
		ALU_FUN <= RX_P_DATA[(RX_FRAME_WIDTH/2)-1:0];

	end

end

// Gate_en
always @(posedge CLK,negedge rst_n) begin
	
	if (!rst_n) begin
		Gate_en <= 0;
	end
	else if (CS == IDLE) begin
		Gate_en <= 0;
	end
	else if (NS == OPERAND_B || NS == CMD_4) begin
		Gate_en <= 1;
	end

end

endmodule