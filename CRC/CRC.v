module CRC (
	input  wire rst_n,
	input  wire CLK,
	input  wire DATA,
	input  wire Active,
	output reg  CRC,
	output reg  Valid
);

localparam IDLE 	= 2'b00;
localparam RECIEVE  = 2'b01;
localparam TRANSMIT = 2'b10;

reg [1:0] NS;
reg [1:0] CS;

// Feedback signal
wire 					 FB;
wire					 done;
reg [7:0] 				 LFSR_REG;
reg [3:0] 				 count;

// FSM Memory
always @(posedge CLK,negedge rst_n) begin
	
	if (!rst_n) begin
		
		CS <= IDLE;

	end
	else begin
			
		CS <= NS;

	end

end

// Next State Logic
always @(*) begin
	
	case (CS) 

		IDLE: begin

			if (!Active) begin
				NS = IDLE;
			end
			else begin
				NS = RECIEVE;
			end

		end
		RECIEVE: begin

			if (Active) begin
				NS = RECIEVE;
			end
			else begin
				NS = TRANSMIT;
			end

		end
		TRANSMIT: begin

			if (!done) begin
				NS = TRANSMIT;
			end
			else begin
				NS = IDLE;
			end

		end

	endcase

end

assign FB   = DATA ^ LFSR_REG[0];
assign done = (count[3])? 1'b1:1'b0;

// LFSR Register
always @(posedge CLK,negedge rst_n) begin
	
	if (!rst_n) begin
		
		LFSR_REG <= 'b0;
		CRC      <= 1'b0;
		Valid    <= 1'b0;

	end
	else if (NS == RECIEVE) begin
		
		LFSR_REG    <= {FB,LFSR_REG[7] ^ FB,LFSR_REG[6:4],LFSR_REG[3] ^ FB,LFSR_REG[2:1]};

	end
	else if (NS == TRANSMIT) begin
		
		CRC		   <= LFSR_REG[0];
		LFSR_REG   <= {FB,LFSR_REG[7:1]};
		Valid	   <= 1;

	end
	else begin
		
		Valid <= 0;

	end

end

// Synchronous Counter
always @(posedge CLK,negedge rst_n) begin
	
	if (!rst_n) begin
		
		count <= 0;

	end
	else if (NS == TRANSMIT) begin
		
		count <= count + 1;

	end
	else begin
		
		count <= 0;

	end

end

endmodule
