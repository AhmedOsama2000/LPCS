module UART_TX 
#(
	parameter INPUT_WIDTH = 8

)
(
	input  wire 				  rst_n,
	input  wire 				  CLK,
	input  wire [INPUT_WIDTH-1:0] P_DATA,
	input  wire 				  DATA_VALID,
	input  wire 				  PAR_EN,
	input  wire 				  PAR_TYP,
	output reg 					  TX_OUT,
	output wire 			      Busy
);

// FSM States (GRAY CODING)
localparam IDLE 	  = 3'b000;
localparam START_BIT  = 3'b001;
localparam SEND_DATA  = 3'b011;
localparam PARITY     = 3'b010;
localparam STOP_BIT   = 3'b110;

// FSM STATES
reg [2:0] CS;
reg [2:0] NS;

// Serializer with counter
reg [INPUT_WIDTH-1:0] serial_reg;
reg [2:0]             serial_counter;

// Start & Stop bits
wire Start_bit;
wire Stop_bit;

assign Start_bit = 0;
assign Stop_bit  = 1;

// Flags to enable/indicate the conversion
wire ser_done;
reg  ser_en;

assign ser_done = (&serial_counter)? 1'b1:1'b0;

// Busy Signal
assign Busy = (CS != IDLE)? 1'b1:1'b0;

// Parity_bit Calculation
wire par_bit;

assign par_bit = (PAR_TYP)? !(^P_DATA) : (^P_DATA);

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

			if (DATA_VALID) begin
				NS = START_BIT;
			end
			else begin			
				NS = IDLE;
			end

		end
		START_BIT: begin

			if (ser_en) begin
				NS = SEND_DATA;
			end
			else begin
				NS = START_BIT;
			end

		end
		SEND_DATA: begin

			if (ser_done && !PAR_EN) begin
				NS = STOP_BIT;
			end
			else if (ser_done && PAR_EN) begin
				NS = PARITY;
			end
			else begin
				
				NS = SEND_DATA;

			end

		end
		PARITY: begin

			if (!ser_done) begin
				NS = STOP_BIT;
			end
			else begin
				NS = PARITY;
			end

		end
		STOP_BIT: begin

			if (DATA_VALID) begin
				NS = START_BIT;
			end
			else begin
				NS = IDLE;
			end

		end
		default: NS = IDLE;

	endcase
end

// FSM Logic
always @(posedge CLK , negedge rst_n) begin

	if (!rst_n) begin

		serial_reg 	   <= 0;
		serial_counter <= 0;
		ser_en         <= 0;

	end
	else if (!ser_done && CS == SEND_DATA) begin

		serial_counter <= serial_counter + 1;
		serial_reg <= {1'b0,serial_reg[7:1]};

	end
	else if (CS == SEND_DATA && ser_done) begin

		serial_counter <= 0;
		ser_en <= 0;

	end
	else if (DATA_VALID) begin

		serial_reg <= P_DATA;
		ser_en     <= 1;

	end

end

// TX_OUT_LOGIC
always @(*) begin

	case(CS)

		START_BIT: begin

			TX_OUT = Start_bit;

		end
		SEND_DATA: begin

			TX_OUT = serial_reg[0];

		end
		PARITY: begin

			TX_OUT = par_bit;

		end
		default: TX_OUT = Stop_bit;

	endcase

end

endmodule // UART_TX