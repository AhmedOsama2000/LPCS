`timescale 1ns/1ps
module SYS_TOP_tb;

 	reg  rst_n_tb;
	reg  REF_CLK_tb;
	reg  UART_CLK_tb;
	reg  RX_IN_tb;
	wire TX_OUT_tb;
	wire Parity_Error_tb;
	wire Frame_Error_tb;

	reg [7:0] CMD_1 = 8'hAA; // 1010_1010
	reg [7:0] CMD_2 = 8'hBB; // 1011_1011
	reg [7:0] CMD_3 = 8'hCC; // 1100_1100
	reg [7:0] CMD_4 = 8'hDD; // 1101_1101

	reg [7:0] temp_addr [15:0];

	reg [7:0] old_config = 8'b0_01000_1_1; // Default: PAR_EN = 1, PAR_TYP = ODD , Prescale = 8
	reg [7:0] new_config; // To change the config of the UART

	reg [7:0] hold_RX_IN;

	reg TX_CLK;

	integer counter;
	integer i;

	SYS_TOP DUT (
		.rst_n(rst_n_tb),
		.REF_CLK(REF_CLK_tb),
		.UART_CLK(UART_CLK_tb),
		.RX_IN(RX_IN_tb),
		.TX_OUT(TX_OUT_tb),
		.Parity_Error(Parity_Error_tb),
		.Frame_Error(Frame_Error_tb)
	);

	always #10 REF_CLK_tb = ~REF_CLK_tb;
	always #6510 UART_CLK_tb = ~UART_CLK_tb; // Prescale X8
	always #52083 TX_CLK = ~TX_CLK;

	initial begin
		for (i = 0;i < 16;i = i + 1) begin
			if (i == 2) begin				
				i = i + 1;
			end
			if (i == 3) begin
				i = i + 1;
			end
			temp_addr[i] = i;
		end
		
		REF_CLK_tb = 0;
		UART_CLK_tb = 0;
		TX_CLK = 0;

		// Perfrom a RST to set the configuration of the regsiters 0x0 ==> 0x3
		RST;

		RX_IN_tb = 1;
		// Wait for the rst_sync to deassert the reset
		repeat (2) @(negedge TX_CLK);

		// Check Regsiter File Write Command with randomize the data in all address (Except reserved ones)
		for (i = 0;i < 16;i = i + 1) begin
			if (i == 2) begin				
				i = i + 2;
			end
			REG_FILE_WRITE(i);
		end

		// Check Register File Read Command
		for (i = 0;i < 5;i = i + 1) begin	
			REG_FILE_READ;
		end

		// Check ALU_WITH_OP Command
		for (i = 0;i < 5;i = i + 1) begin
			ALU_WITH_OP;
		end

		// Check ALU_WITH_NOP Command
		for (i = 0;i < 10;i = i + 1) begin	
			ALU_WITH_NOP;
		end

		repeat (20) @(negedge TX_CLK);

		// Change the configuration of the UART parity
		new_config = 8'b0_01000_0_1; // Set the parity to even calculation
		set_configure(new_config);

		// Wait for data to settle
		repeat (10) @(negedge TX_CLK);

		REG_FILE_READ;

		repeat (20) @(negedge TX_CLK);
		$stop;
	end

	task REG_FILE_WRITE(input integer case_num);
		begin
			// FIRST_FRAME (Command)
			STR_BIT;

			for (counter = 0;counter < 8;counter = counter + 1) begin
				@(negedge TX_CLK)
				RX_IN_tb = CMD_1[counter];
			end

			if (old_config[0] && old_config[1]) begin
				ODD_CLC_PAR(CMD_1);
			end
			else if (old_config[0] && !old_config[1]) begin
				EVEN_CLC_PAR(CMD_1);
			end

			STP_BIT;

			// SECOND_FRAME (Address)
			STR_BIT;

			for (counter = 0;counter < 8;counter = counter + 1) begin
				@(negedge TX_CLK)
				RX_IN_tb = temp_addr[case_num][counter];
			end

			if (old_config[0] && old_config[1]) begin
				ODD_CLC_PAR(temp_addr[case_num]);
			end
			else if (old_config[0] && !old_config[1]) begin
				EVEN_CLC_PAR(temp_addr[case_num]);
			end

			STP_BIT;

			// THIRD_FRAME (Data)
			STR_BIT;

			for (counter = 0;counter < 8;counter = counter + 1) begin
				@(negedge TX_CLK)
				RX_IN_tb = $random;
				hold_RX_IN[counter] = RX_IN_tb;
			end

			if (old_config[0] && old_config[1]) begin
				ODD_CLC_PAR(hold_RX_IN);
			end
			else if (old_config[0] && !old_config[1]) begin
				EVEN_CLC_PAR(hold_RX_IN);
			end
			
			STP_BIT;
		end
	endtask

	task REG_FILE_READ;
		begin
			
			// FIRST_FRAME (Command)
			STR_BIT;

			for (counter = 0;counter < 8;counter = counter + 1) begin
				@(negedge TX_CLK)
				RX_IN_tb = CMD_2[counter];
			end

			if (old_config[0] && old_config[1]) begin
				ODD_CLC_PAR(CMD_2);
			end
			else if (old_config[0] && !old_config[1]) begin
				EVEN_CLC_PAR(CMD_2);
			end

			STP_BIT;

			// SECOND_FRAME (Address)
			STR_BIT;

			for (counter = 0;counter < 8;counter = counter + 1) begin
				@(negedge TX_CLK)
				RX_IN_tb = $random;
				hold_RX_IN[counter] = RX_IN_tb;
			end

			if (old_config[0] && old_config[1]) begin
				ODD_CLC_PAR(hold_RX_IN);
			end
			else if (old_config[0] && !old_config[1]) begin
				EVEN_CLC_PAR(hold_RX_IN);
			end

			STP_BIT;
		end
	endtask

	task ALU_WITH_OP;
		begin
			
			// FIRST_FRAME (Command)
			STR_BIT;

			for (counter = 0;counter < 8;counter = counter + 1) begin
				@(negedge TX_CLK)
				RX_IN_tb = CMD_3[counter];
			end

			if (old_config[0] && old_config[1]) begin
				ODD_CLC_PAR(CMD_3);
			end
			else if (old_config[0] && !old_config[1]) begin
				EVEN_CLC_PAR(CMD_3);
			end

			STP_BIT;

			// SECOND_FRAME (OPERAND_A)
			STR_BIT;

			for (counter = 0;counter < 8;counter = counter + 1) begin
				@(negedge TX_CLK)
				RX_IN_tb = $random;
				hold_RX_IN[counter] = RX_IN_tb;
			end

			if (old_config[0] && old_config[1]) begin
				ODD_CLC_PAR(hold_RX_IN);
			end
			else if (old_config[0] && !old_config[1]) begin
				EVEN_CLC_PAR(hold_RX_IN);
			end

			STP_BIT;

			// THIRD_FRAME (OPERAND_B)
			STR_BIT;

			for (counter = 0;counter < 8;counter = counter + 1) begin
				@(negedge TX_CLK)
				RX_IN_tb = $random;
				hold_RX_IN[counter] = RX_IN_tb;
			end

			if (old_config[0] && old_config[1]) begin
				ODD_CLC_PAR(hold_RX_IN);
			end
			else if (old_config[0] && !old_config[1]) begin
				EVEN_CLC_PAR(hold_RX_IN);
			end

			STP_BIT;

			// FOURTH_FRAME (ALU_FUN)
			STR_BIT;

			for (counter = 0;counter < 8;counter = counter + 1) begin
				@(negedge TX_CLK)
				RX_IN_tb = $random;
				hold_RX_IN[counter] = RX_IN_tb;
			end

			if (old_config[0] && old_config[1]) begin
				ODD_CLC_PAR(hold_RX_IN);
			end
			else if (old_config[0] && !old_config[1]) begin
				EVEN_CLC_PAR(hold_RX_IN);
			end

			STP_BIT;
		
		end
	endtask

	task ALU_WITH_NOP;
		begin
			
			// FIRST_FRAME (Command)
			STR_BIT;

			for (counter = 0;counter < 8;counter = counter + 1) begin
				@(negedge TX_CLK)
				RX_IN_tb = CMD_4[counter];
			end

			if (old_config[0] && old_config[1]) begin
				ODD_CLC_PAR(CMD_4);
			end
			else if (old_config[0] && !old_config[1]) begin
				EVEN_CLC_PAR(CMD_4);
			end

			STP_BIT;

			// SECOND_FRAME (ALU_FUN)
			STR_BIT;

			for (counter = 0;counter < 8;counter = counter + 1) begin
				@(negedge TX_CLK)
				RX_IN_tb = $urandom_range(12);
				hold_RX_IN[counter] = RX_IN_tb;
			end

			if (old_config[0] && old_config[1]) begin
				ODD_CLC_PAR(hold_RX_IN);
			end
			else if (old_config[0] && !old_config[1]) begin
				EVEN_CLC_PAR(hold_RX_IN);
			end

			STP_BIT;

		end
	endtask

	task set_configure(input [7:0] config_set);
		begin
			
			temp_addr[2] = 8'b0000_0010;

			// FIRST_FRAME (Command)
			STR_BIT;

			for (counter = 0;counter < 8;counter = counter + 1) begin
				@(negedge TX_CLK)
				RX_IN_tb = CMD_1[counter];
			end

			if (old_config[0] && old_config[1]) begin
				ODD_CLC_PAR(CMD_1);
			end
			else if (old_config[0] && !old_config[1]) begin
				EVEN_CLC_PAR(CMD_1);
			end

			STP_BIT;

			// SECOND_FRAME (Address)
			STR_BIT;

			for (counter = 0;counter < 8;counter = counter + 1) begin
				@(negedge TX_CLK)
				RX_IN_tb = temp_addr[2][counter];
			end

			if (old_config[0] && old_config[1]) begin
				ODD_CLC_PAR(temp_addr[2]);
			end
			else if (old_config[0] && !old_config[1]) begin
				EVEN_CLC_PAR(temp_addr[2]);
			end

			STP_BIT;

			// THIRD_FRAME (Data)
			STR_BIT;

			for (counter = 0;counter < 8;counter = counter + 1) begin
				@(negedge TX_CLK)
				RX_IN_tb = config_set[counter];
			end

			if (old_config[0] && old_config[1]) begin
				ODD_CLC_PAR(config_set);
			end
			else if (old_config[0] && !old_config[1]) begin
				EVEN_CLC_PAR(config_set);
			end

			STP_BIT;

			old_config = new_config;

		end
	endtask

	task STR_BIT;
		begin
			
			@(negedge TX_CLK)
			RX_IN_tb = 0;

		end
	endtask

	task STP_BIT;
		begin
			
			@(negedge TX_CLK)
			RX_IN_tb = 1;

		end
	endtask

	task RST;
		begin

			rst_n_tb = 0;
			@(negedge REF_CLK_tb)
			rst_n_tb = 1;

		end
	endtask

	task EVEN_CLC_PAR(input [7:0] DATA);
		begin
			
			@(negedge TX_CLK)
			RX_IN_tb = ^DATA;

		end
	endtask

	task ODD_CLC_PAR(input [7:0] DATA);
		begin
			
			@(negedge TX_CLK)
			RX_IN_tb = !(^DATA);

		end
	endtask

endmodule
