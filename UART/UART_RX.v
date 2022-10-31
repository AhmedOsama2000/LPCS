module UART_RX 
#(
	parameter OUTPUT_WIDTH = 8,
	parameter PRESCALE_IN  = 5

)
(
	input  wire 				   rst_n,
	input  wire 				   CLK,
	input  wire					   RX_IN,
	input  wire [PRESCALE_IN-1:0]  prescale,
	input  wire 				   PAR_EN,
	input  wire 				   PAR_TYP,
	output reg  [OUTPUT_WIDTH-1:0] P_DATA,
	output reg 					   DATA_VALID,
	output wire					   PAR_ERR,
	output wire					   STP_ERR	  
);

localparam IDLE 	  	 = 3'b000;
localparam START_CHK  	 = 3'b001;
localparam RECEIVE_DATA  = 3'b010;
localparam PAR_CHK       = 3'b011;
localparam STOP_CHK   	 = 3'b100;

// FSM STATES
reg [2:0] CS;
reg [2:0] NS;

// Edge/bit_counters
reg [3:0] 			   bit_cnt;
reg [PRESCALE_IN-1:0]  edge_cnt;
reg enable_counters;


// Flag to enable/indicate the conversion
reg  deser_en;

// Data_sampler
wire data_samp_en;
wire [PRESCALE_IN-2:0] middle_edge;
wire [PRESCALE_IN-2:0] prev_edge;
wire [PRESCALE_IN-2:0] next_edge;

// Deserializer
reg [OUTPUT_WIDTH-1:0] Deser_reg;

// Start/Stop Check
wire Start_bit;
wire Stop_bit;
wire str_glitch;
reg str_chk_en;
reg stp_chk_en;

// Parity_bit Calculation
wire par_bit;
reg par_chk_en;


// Edge_bit_Counter
wire  sampled_bit;
reg	[2:0] majority_bits; 

assign Start_bit = 0;
assign Stop_bit  = 1;


assign str_glitch = (str_chk_en && sampled_bit != Start_bit && edge_cnt == prescale)? 1'b1 : 1'b0;
assign STP_ERR    = (stp_chk_en && sampled_bit != Stop_bit && edge_cnt == prescale)? 1'b1 : 1'b0;

assign par_bit = (PAR_TYP)? !(^Deser_reg) : (^Deser_reg);
assign PAR_ERR = (par_chk_en && edge_cnt == prescale && par_bit != sampled_bit)? 1'b1:1'b0;

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

			if (!RX_IN) begin
				NS = START_CHK;
			end
			else begin			
				NS = IDLE;
			end

		end
		START_CHK: begin

			if (edge_cnt == prescale && !str_glitch) begin
				NS = RECEIVE_DATA;
			end
			else if (!bit_cnt && !str_glitch) begin
				NS = START_CHK;
			end
			else begin
				NS = IDLE;
			end

		end
		RECEIVE_DATA: begin

			if (bit_cnt == 9 && !PAR_EN) begin
				NS = STOP_CHK;
			end
			else if (bit_cnt == 9 && PAR_EN) begin
				NS = PAR_CHK;
			end
			else begin
				NS = RECEIVE_DATA;
			end

		end
		PAR_CHK: begin

			if (edge_cnt != prescale) begin
				
				NS = PAR_CHK;
			end
			else if (!PAR_ERR) begin
				NS = STOP_CHK;
			end
			else begin
				NS = IDLE;
			end

		end
		STOP_CHK: begin

			if (edge_cnt != prescale) begin
				NS = STOP_CHK;
			end
			else if (!STP_ERR && !RX_IN) begin
				NS = START_CHK;
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

	// default values
	str_chk_en = 0;
	deser_en = 0;
	par_chk_en = 0;
	stp_chk_en = 0;
	enable_counters = 1;
	DATA_VALID = 0;

	if (CS == START_CHK) begin

		str_chk_en = 1;

	end
	else if (CS == RECEIVE_DATA) begin
		
		deser_en = 1;
		
	end
	else if (CS == PAR_CHK) begin
		
		par_chk_en = 1;

	end
	else if (CS == STOP_CHK) begin
		
		stp_chk_en = 1;
		if (!PAR_ERR && !STP_ERR && edge_cnt == prescale) begin
			
			DATA_VALID = 1;
			enable_counters  = 0;

		end
		else begin
			
			enable_counters = 1;

		end

	end
	else begin
		
		str_chk_en = 0;
		deser_en = 0;
		par_chk_en = 0;
		stp_chk_en = 0;
		enable_counters = 0;
		DATA_VALID = 0;

	end

end

// Data Sampler && Edge_bit_counter
always @(posedge CLK , negedge rst_n) begin
	
	if (!rst_n) begin
		
		majority_bits <= 0;
		bit_cnt <= 0;
		edge_cnt <= 1;
		Deser_reg <= 0;

	end
	else if (edge_cnt == prescale && str_glitch) begin
		
		edge_cnt <= 1;

	end
	else if (!enable_counters || STP_ERR) begin
		
		bit_cnt <= 0;
		edge_cnt <= 1;

	end
	else if (data_samp_en) begin
		
		majority_bits <= {RX_IN,majority_bits[2:1]};
		edge_cnt <= edge_cnt + 1;

	end
	else if (edge_cnt == prescale && deser_en) begin
			
		Deser_reg <= {sampled_bit,Deser_reg[7:1]};
		bit_cnt <= bit_cnt + 1;
		edge_cnt <= 1;

	end
	else if (edge_cnt == prescale && !deser_en) begin
		
		edge_cnt <= 1;
		bit_cnt <= bit_cnt + 1;

	end
	else if (enable_counters && !str_glitch) begin
		
		edge_cnt <= edge_cnt + 1;

	end

end

// Deserializer to P_DATA
always @(posedge CLK , negedge rst_n) begin
	
	if (!rst_n) begin
		
		P_DATA <= 0;

	end
	else if (bit_cnt == 9) begin
		
		P_DATA <= Deser_reg;

	end

end

assign middle_edge = prescale >> 1;
assign prev_edge = middle_edge - 1;
assign next_edge = middle_edge + 1;

assign data_samp_en = ((edge_cnt == prev_edge) || (edge_cnt == middle_edge) || (edge_cnt == next_edge))? 1'b1:1'b0;

assign sampled_bit = (majority_bits[0] & majority_bits[1]) 
					   |(majority_bits[1] & majority_bits[2]) 
					   |(majority_bits[2] & majority_bits[0]);


endmodule // UART_RX