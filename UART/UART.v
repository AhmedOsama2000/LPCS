module UART #(
	parameter INPUT_WIDTH  = 8,
	parameter OUTPUT_WIDTH = 8,
	parameter PRESCALE_IN  = 5
)
(
	input  wire 			       rst_n,
	input  wire 			       TX_CLK,
	input  wire					   RX_CLK,
	input  wire					   RX_IN,
	input  wire [OUTPUT_WIDTH-1:0] TX_P_DATA,
	input  wire 				   PAR_EN,
    input  wire 				   PAR_TYP,
	input  wire 				   TX_DATA_VALID,
	input  wire [PRESCALE_IN-1:0]  prescale,
	output wire 				   TX_OUT,
	output wire [INPUT_WIDTH-1:0]  RX_P_DATA,
	output wire 			       Busy,
	output wire 				   RX_DATA_VALID,
	output wire					   PAR_ERR,
	output wire					   STP_ERR	
);

UART_TX TX (
	.rst_n(rst_n),
	.CLK(TX_CLK),
	.P_DATA(TX_P_DATA),
	.DATA_VALID(TX_DATA_VALID),
	.PAR_EN(PAR_EN),
	.PAR_TYP(PAR_TYP),
	.TX_OUT(TX_OUT),
	.Busy(Busy)
);

UART_RX RX (
	.rst_n(rst_n),
	.CLK(RX_CLK),
	.RX_IN(RX_IN),
	.prescale(prescale),
	.PAR_EN(PAR_EN),
	.PAR_TYP(PAR_TYP),
	.P_DATA(RX_P_DATA),
	.DATA_VALID(RX_DATA_VALID),
	.PAR_ERR(PAR_ERR),
	.STP_ERR(STP_ERR)	
);

endmodule