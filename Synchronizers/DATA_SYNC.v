module Data_Sync 
#(
	parameter BUS_WIDTH  = 8,
	parameter NUM_STAGES = 2
)
(
	input  wire 				CLK,
	input  wire 				rst_n,
	input  wire 				bus_enable,
	input  wire [BUS_WIDTH-1:0] unsync_bus,
	output reg 				    enable_pulse,
	output reg [BUS_WIDTH-1:0]  sync_bus
);

// Number of stages
reg [NUM_STAGES-1:0] NFFS;

// output signal of pulse_gen block
wire pulse_gen_out;

// FF of pulse_gen block
reg pulse_gen_FF;


always @(posedge CLK ,  negedge rst_n) begin

	if(!rst_n) begin

		enable_pulse <= 0;
		pulse_gen_FF <= 0;
		NFFS  		 <= 0;

	end
	else begin
		
		enable_pulse <= pulse_gen_out;
		{pulse_gen_FF,NFFS} <= {NFFS[0],bus_enable,NFFS[NUM_STAGES-1:1]};

	end

end

always @(posedge CLK , negedge rst_n) begin

	if (!rst_n) begin

		sync_bus <= 0;

	end
	else if (pulse_gen_out) begin
		
		sync_bus <= unsync_bus;

	end

end

assign pulse_gen_out = NFFS[0] && !pulse_gen_FF;

endmodule // Data_Sync

