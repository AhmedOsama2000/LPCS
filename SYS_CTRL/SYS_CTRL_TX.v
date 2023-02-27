module SYS_CTRL_TX 
#(
	parameter RD_DATA_WIDTH = 8,
	parameter ALU_OUT_WIDTH = 16
)
(
	input  wire						CLK,
	input  wire 					rst_n,
	input  wire                     Full,
	input  wire [RD_DATA_WIDTH-1:0] Rd_data,
	input  wire 					Rd_data_valid,
	input  wire [ALU_OUT_WIDTH-1:0] ALU_OUT,
	input  wire 				    ALU_OUT_valid,
	output reg [RD_DATA_WIDTH-1:0]  FIFO_IN,
	output reg 						Wr_Req
);

// Gray Coding
localparam IDLE 	  	      = 3'b000;
localparam GET_ALU_DATA       = 3'b001;
localparam SEND_TX_RD_DATA    = 3'b010;
localparam SEND_TX_ALU_FIRST  = 3'b110;
localparam SEND_TX_ALU_SECOND = 3'b111;

// FSM STATES
reg [2:0] CS;
reg [2:0] NS;

// Register to hold data from ALU_OUT
reg [ALU_OUT_WIDTH/2-1:0] upper_data;
reg [ALU_OUT_WIDTH/2-1:0] lower_data;

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
			if (Rd_data_valid) begin
				NS = SEND_TX_RD_DATA;
			end
			else if (ALU_OUT_valid) begin			
				NS = GET_ALU_DATA;
			end
			else begin
				NS = IDLE;
			end
		end
		GET_ALU_DATA: begin
			if (!Full) begin
				NS = SEND_TX_ALU_FIRST;
			end
			else begin
				NS = GET_ALU_DATA;
			end
		end
		SEND_TX_RD_DATA: begin
			if (Full) begin
				NS = SEND_TX_RD_DATA;
			end
			else begin
				NS = IDLE;
			end
		end
		SEND_TX_ALU_FIRST: begin
			if (!Full) begin
				NS = SEND_TX_ALU_SECOND;
			end
			else begin
				NS = SEND_TX_ALU_FIRST;
			end
		end
		SEND_TX_ALU_SECOND: begin
			if (!Full) begin
				NS = IDLE;
			end
			else begin
				NS = SEND_TX_ALU_SECOND;
			end
		end
		default: NS = IDLE;

	endcase
end

// FSM OUTPUT
always @(*) begin

	if (CS == IDLE || CS == GET_ALU_DATA) begin
		Wr_Req = 1'b0;
	end
	else begin
		Wr_Req = 1'b1;
	end

end

always @(posedge CLK,negedge rst_n) begin
	
	if (!rst_n) begin
		FIFO_IN <= 'b0;
		{upper_data,lower_data} <= 'b0;
	end
	else if (NS == SEND_TX_RD_DATA) begin
		FIFO_IN <= Rd_data;
	end
	else if (NS == GET_ALU_DATA && ALU_OUT_valid) begin
		{upper_data,lower_data} <= ALU_OUT;
	end
	else if (NS == SEND_TX_ALU_FIRST) begin
		FIFO_IN   <= lower_data[(ALU_OUT_WIDTH/2)-1:0];
	end
	else if (NS == SEND_TX_ALU_SECOND) begin	
		FIFO_IN   <= upper_data[(ALU_OUT_WIDTH/2)-1:0];
	end
end

endmodule