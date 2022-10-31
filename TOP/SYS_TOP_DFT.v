// Number of scan chains is 3 (around 285 DFF)

module SYS_TOP 
#(
	parameter INPUT_WIDTH     = 8,
	parameter OUTPUT_WIDTH    = 8,
	parameter PRESCALE_WIDTH  = 5,
	parameter REG_WDITH       = 8,
	parameter ADDR_SIZE       = 4,
	parameter ALU_IN_WIDTH    = 8,
    parameter ALU_OUT_WIDTH   = ALU_IN_WIDTH*2,
    parameter ALU_FUN_WIDTH   = 4,

    parameter SCAN_CHAINS	  = 3

)
(
	input  wire rst_n,
	input  wire REF_CLK,
	input  wire UART_CLK,
	input  wire RX_IN,

	input  wire [SCAN_CHAINS-1:0] SI,
	input  wire 				  test_mode,
	input  wire 				  SE,
	input  wire 				  scan_clk,
	input  wire 				  scan_rst_n,

	output wire [SCAN_CHAINS-1:0] SO,

	output wire TX_OUT,
	output wire Parity_Error,
	output wire Frame_Error
);

// DFT signals interface
wire scan_ref_clk;
wire scan_uart_rx_clk;
wire scan_uart_tx_clk;
wire scan_glob_rst_n;
wire scan_domain1_rst_n;
wire scan_domain2_rst_n;

// CLOCK GATING INTERFACE
wire Gate_en;
wire ALU_CLK;

// SYNC_DATA INTERFACE
wire [INPUT_WIDTH-1:0]  SYNC_RX_DATA;
wire [OUTPUT_WIDTH-1:0] SYNC_TX_DATA;
wire SYNC_RX_D_VLD;
wire SYNC_TX_D_VLD;

wire sync_rst_1;
wire sync_rst_2;

wire Sync_Busy;

// UART INTERFACE
wire [INPUT_WIDTH-1:0]    RX_P_DATA;
wire [OUTPUT_WIDTH-1:0]   TX_P_DATA;
wire					  TX_D_VLD;
wire					  RX_D_VLD;
wire [PRESCALE_WIDTH-1:0] prescale;
wire					  PAR_EN;
wire					  PAR_TYP;
wire					  TX_CLK;
wire					  Busy;

// REG_FILE INTERFACE
wire [REG_WDITH-1:0] Rd_data;
wire [REG_WDITH-1:0] WrData;
wire [REG_WDITH-1:0] REG_2;
wire [REG_WDITH-1:0] REG_3;
wire [ADDR_SIZE-1:0] Address;
wire 				 Rd_data_valid;
wire 				 WrEn;
wire 				 RdEn;

assign PAR_EN   = REG_2[0];
assign PAR_TYP  = REG_2[1];
assign prescale = REG_2[6:2];

// CLOCK DIVIDER INTERFACE
wire [4:0] i_div_ratio;
wire i_clk_en;

assign i_div_ratio = REG_3[4:0];

// ALU_INTERFACE
wire [ALU_IN_WIDTH-1:0]  OPERAND_A;
wire [ALU_IN_WIDTH-1:0]  OPERAND_B;
wire [ALU_OUT_WIDTH-1:0] ALU_OUT;
wire [ALU_FUN_WIDTH-1:0] ALU_FUN;
wire 					 ALU_OUT_valid;
wire					 ALU_EN;

wire clk_gate_byp;

assign clk_gate_byp = Gate_en | test_mode;

mux2X1 mux_ref_clk (
	.IN_0(REF_CLK),
	.IN_1(scan_clk),
	.SEL(test_mode),
	.OUT(scan_ref_clk)
);

mux2X1 mux_uart_rx_clk (
	.IN_0(UART_CLK),
	.IN_1(scan_clk),
	.SEL(test_mode),
	.OUT(scan_uart_rx_clk)
);

mux2X1 mux_uart_tx_clk (
	.IN_0(TX_CLK),
	.IN_1(scan_clk),
	.SEL(test_mode),
	.OUT(scan_uart_tx_clk)
);

mux2X1 mux_global_reset (
	.IN_0(rst_n),
	.IN_1(scan_rst_n),
	.SEL(test_mode),
	.OUT(scan_glob_rst_n)
);

mux2X1 mux_domain1_reset (
	.IN_0(sync_rst_1),
	.IN_1(scan_glob_rst_n),
	.SEL(test_mode),
	.OUT(scan_domain1_rst_n)
);

mux2X1 mux_domain2_reset (
	.IN_0(sync_rst_2),
	.IN_1(scan_glob_rst_n),
	.SEL(test_mode),
	.OUT(scan_domain2_rst_n)
);

CLKGate Clock_Gate (
	.CLK(scan_ref_clk),
	.Enable(clk_gate_byp),
	.gate_clk(ALU_CLK)
);

BIT_SYNC busy_sync_domain1to2 (
	.CLK(scan_ref_clk),
	.rst_n(scan_domain1_rst_n),
	.Async(Busy),
	.Sync(Sync_Busy)
);

Data_Sync Domain2to1 (
	.CLK(scan_ref_clk),
	.rst_n(scan_domain1_rst_n),
	.bus_enable(RX_D_VLD),
	.unsync_bus(RX_P_DATA),
	.enable_pulse(SYNC_RX_D_VLD),
	.sync_bus(SYNC_RX_DATA)
);

Data_Sync Domain1to2 (
	.CLK(scan_uart_tx_clk),
	.rst_n(scan_domain2_rst_n),
	.bus_enable(TX_D_VLD),
	.unsync_bus(TX_P_DATA),
	.enable_pulse(SYNC_TX_D_VLD),
	.sync_bus(SYNC_TX_DATA)
);

RST_SYNC rst_domain_1 (
	.CLK(scan_ref_clk),
	.rst_n(scan_glob_rst_n),
	.sync_rst_n(sync_rst_1)
);

RST_SYNC rst_domain_2 (
	.CLK(scan_uart_rx_clk),
	.rst_n(scan_glob_rst_n),
	.sync_rst_n(sync_rst_2)
);

SYS_CTRL Control_Unit (
	.CLK(scan_ref_clk),
	.rst_n(scan_domain1_rst_n),
	.Rd_data(Rd_data),
	.Rd_data_valid(Rd_data_valid),
	.ALU_OUT(ALU_OUT),
	.ALU_OUT_valid(ALU_OUT_valid),
	.BUSY(Sync_Busy),
	.RX_P_DATA(SYNC_RX_DATA),
	.RX_D_VLD(SYNC_RX_D_VLD),
	.TX_P_DATA(TX_P_DATA),
	.TX_D_VLD(TX_D_VLD),
	.WrEn(WrEn),
	.WrData(WrData),
	.Address(Address),
	.RdEn(RdEn),
	.Gate_en(Gate_en),
	.CLK_Div_EN(i_clk_en),
	.ALU_FUN(ALU_FUN),
	.ALU_EN(ALU_EN)
);

ClkDiv Clock_Divider (
	.i_ref_clk(scan_uart_rx_clk),
	.i_rst_n(scan_domain2_rst_n),
	.i_clk_en(i_clk_en),
	.i_div_ratio(i_div_ratio),
	.o_div_clk(TX_CLK)
);

UART UART (
	.rst_n(scan_domain2_rst_n),
	.TX_CLK(scan_uart_tx_clk),
	.RX_CLK(scan_uart_rx_clk),
	.RX_IN(RX_IN),
	.RX_P_DATA(RX_P_DATA),
	.TX_P_DATA(SYNC_TX_DATA),
	.PAR_EN(PAR_EN),
	.PAR_TYP(PAR_TYP),
	.TX_DATA_VALID(SYNC_TX_D_VLD),
	.prescale(prescale),
	.TX_OUT(TX_OUT),
	.Busy(Busy),
	.RX_DATA_VALID(RX_D_VLD),
	.PAR_ERR(Parity_Error),
	.STP_ERR(Frame_Error)
);

RegFile Register_File (
	.CLK(scan_ref_clk),
	.rst_n(scan_domain1_rst_n),
	.WrEN(WrEn),
	.RdEN(RdEn),
	.WrData(WrData),
	.Address(Address),
	.Rd_Data(Rd_data),
	.REG_0(OPERAND_A),
	.REG_1(OPERAND_B),
	.REG_2(REG_2),
	.REG_3(REG_3),
	.Rd_Data_VLD(Rd_data_valid)
);

ALU ALU (
	.CLK(ALU_CLK),
	.rst_n(scan_domain1_rst_n),
	.ALU_EN(ALU_EN),
	.A(OPERAND_A),
	.B(OPERAND_B),
	.ALU_FUN(ALU_FUN),
	.ALU_OUT(ALU_OUT),
	.ALU_OUT_VLD(ALU_OUT_valid)
);

endmodule

