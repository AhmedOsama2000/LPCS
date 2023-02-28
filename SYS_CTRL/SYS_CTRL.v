module SYS_CTRL 
#(
	parameter RD_DATA_WIDTH = 8,
	parameter ALU_OUT_WIDTH = 16,
	parameter RX_FRAME_WIDTH = 8,
	parameter ADDRESS_SIZE = 4
)
(
	input  wire						 CLK,
	input  wire 					 rst_n,
	input  wire                      Full,
	input  wire [RD_DATA_WIDTH-1:0]  Rd_data,
	input  wire 					 Rd_data_valid,
	input  wire [ALU_OUT_WIDTH-1:0]  ALU_OUT,
	input  wire 				     ALU_OUT_valid,
	input  wire [RX_FRAME_WIDTH-1:0] RX_P_DATA,
	input  wire 					 RX_D_VLD,
	output wire [RD_DATA_WIDTH-1:0]  FIFO_IN,
	output wire 					 Wr_Req,
	output wire                      WrEn,
	output wire [RX_FRAME_WIDTH-1:0] WrData,
	output wire [ADDRESS_SIZE-1:0]   Address,
	output wire                      RdEn,
	output wire   				     Gate_en,
	output wire   				     CLK_Div_EN,
	output wire [ADDRESS_SIZE-1:0]   ALU_FUN,
	output wire 				     ALU_EN
);

SYS_CTRL_TX CTRL_TX 
(
	.CLK(CLK),
	.rst_n(rst_n),
	.Rd_data(Rd_data),
	.Full(Full),
	.Rd_data_valid(Rd_data_valid),
	.ALU_OUT(ALU_OUT),
	.ALU_OUT_valid(ALU_OUT_valid),
	.FIFO_IN(FIFO_IN),
	.Wr_Req(Wr_Req)
);

SYS_CTRL_RX CTRL_RX
(
	.CLK(CLK),
	.rst_n(rst_n),
	.RX_P_DATA(RX_P_DATA),
	.RX_D_VLD(RX_D_VLD),
	.WrEn(WrEn),
	.WrData(WrData),
	.Address(Address),
	.RdEn(RdEn),
	.Gate_en(Gate_en),
	.CLK_Div_EN(CLK_Div_EN),
	.ALU_FUN(ALU_FUN),
	.ALU_EN(ALU_EN)
);

endmodule