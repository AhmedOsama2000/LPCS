module CRC_tb;

	reg  rst_n_tb;
	reg  CLK_tb;
	reg  DATA_tb;
	reg  Active_tb;
	wire CRC_tb;
	wire Valid_tb;

	CRC DUT 
	(
		.rst_n(rst_n_tb),
		.CLK(CLK_tb),
		.DATA(DATA_tb),
		.Active(Active_tb),
		.CRC(CRC_tb),
		.Valid(Valid_tb)
	);

	always begin
		
		#50 CLK_tb = ~CLK_tb;

	end

	integer i;
	integer bits_num = 16;

	initial begin
		
		CLK_tb = 0;
		rst_n_tb = 0;
		Active_tb = 0;
		DATA_tb = 0;
		repeat (3) @(negedge CLK_tb);

		rst_n_tb = 1;
		Active_tb = 1;

		for (i = 0;i < bits_num;i = i + 1) begin
			
			DATA_tb = $random;
			@(negedge CLK_tb);

		end

		Active_tb = 0;

		// Wait for data to be retrieved
		repeat (20) @(negedge CLK_tb);

		$stop;

	end

endmodule