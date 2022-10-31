module SYS_CTRL_TX 
#(
	parameter RD_DATA_WIDTH = 8,
	parameter ALU_OUT_WIDTH = 16
)
(
	input  wire						CLK,
	input  wire 					rst_n,
	input  wire [RD_DATA_WIDTH-1:0] Rd_data,
	input  wire 					Rd_data_valid,
	input  wire [ALU_OUT_WIDTH-1:0] ALU_OUT,
	input  wire 				    ALU_OUT_valid,
	input  wire 					BUSY,
	output reg [RD_DATA_WIDTH-1:0]  TX_P_DATA,
	output reg 						TX_D_VLD
);

localparam IDLE 	  	      = 3'b000;
localparam GET_ALU_DATA       = 3'b001;
localparam SEND_TX_RD_DATA    = 3'b010;
localparam SEND_TX_ALU_FIRST  = 3'b011;
localparam SEND_TX_ALU_SECOND = 3'b101;

// FSM STATES
reg [2:0] CS;
reg [2:0] NS;

//shifted ALU MSB
reg first_done;

// Register to hold data ALU_OUT
reg [ALU_OUT_WIDTH-1:0] temp_data;

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

			if (BUSY) begin
				NS = GET_ALU_DATA;
			end
			else if (!first_done) begin
				NS = SEND_TX_ALU_FIRST;
			end
			else begin
				NS = SEND_TX_ALU_SECOND;
			end

		end
		SEND_TX_RD_DATA: begin

			if (!BUSY) begin
				NS = SEND_TX_RD_DATA;
			end
			else begin
				NS = IDLE;
			end

		end
		SEND_TX_ALU_FIRST: begin

			if (!BUSY) begin
				NS = SEND_TX_ALU_FIRST;
			end
			else begin
				NS = GET_ALU_DATA;
			end

		end
		SEND_TX_ALU_SECOND: begin

			if (!BUSY) begin
				NS = SEND_TX_ALU_SECOND;
			end
			else begin
				NS = IDLE;
			end

		end
		default: NS = IDLE;

	endcase
end

// FSM OUTPUT
always @(*) begin


	if (CS == IDLE || CS == GET_ALU_DATA) begin
		
		TX_D_VLD = 0;

	end
	else begin
		
		TX_D_VLD = 1;

	end

end

always @(posedge CLK,negedge rst_n) begin
	

	if (!rst_n) begin
		
		first_done <= 0;
		TX_P_DATA <= 0;
		temp_data <= 0;

	end
	else if (NS == SEND_TX_RD_DATA) begin
		
		TX_P_DATA <= Rd_data;

	end
	else if (NS == GET_ALU_DATA && ALU_OUT_valid) begin

		temp_data <= ALU_OUT;

	end
	else if (NS == SEND_TX_ALU_FIRST) begin
		
		TX_P_DATA <= temp_data[(ALU_OUT_WIDTH/2)-1:0];
		first_done <= 1;

	end
	else if (NS == SEND_TX_ALU_SECOND) begin
		
		TX_P_DATA <= temp_data[ALU_OUT_WIDTH-1:ALU_OUT_WIDTH/2];
		first_done <= 0;

	end
end

endmodule