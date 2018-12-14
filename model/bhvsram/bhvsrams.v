// Copyright (c) 2018  Lulinchen, All Rights Reserved
// AUTHOR : 	Lulinchen
// AUTHOR'S EMAIL : lulinchen@aliyun.com 
// Release history
// VERSION Date AUTHOR DESCRIPTION


`define RFDP(dpeth, width)    \
module rfdp``dpeth``x``width (					\
	output 		[width-1:0]				QA,     \
	input 		[$clog2(dpeth)-1:0] 	AA,     \
	input 								CLKA,   \
	input 								CENA,   \
	input 		[$clog2(dpeth)-1:0] 	AB,     \
	input 		[width-1:0] 			DB,     \
	input 								CLKB,   \
	input 								CENB    \
	);                                          \
	bhv_1w1r_sram #(                            \
		.WWORD		(width),                    \
		.WADDR		($clog2(dpeth)),            \
		.DEPTH		(dpeth)                     \
		) u (                                   \
		.clka		(CLKA),                     \
		.aa			(AA),                       \
		.cena		(CENA),                     \
		.qa			(QA),                       \
                                                \
		.clkb		(CLKB),                     \
		.ab			(AB),                       \
		.cenb		(CENB),                     \
		.db			(DB));                      \
endmodule



`define RFDPWP(dpeth, width, wpwidth)    \
module rfdp``dpeth``x``width``_wp``wpwidth (		\
	output 		[width-1:0]				QA,     \
	input 		[$clog2(dpeth)-1:0] 	AA,     \
	input 								CLKA,   \
	input 								CENA,   \
	input 		[$clog2(dpeth)-1:0] 	AB,     \
	input 		[width-1:0] 			DB,     \
	input 								CLKB,   \
	input 		[width/wpwidth-1:0]		WENB,	\
	input 								CENB	\
	);                                          \
	bhv_1w1r_sram_wp #(                         \
		.WWORD		(width),                    \
		.WADDR		($clog2(dpeth)),            \
		.DEPTH		(dpeth),                    \
		.WP			(wpwidth)                   \
		) u (                                   \
		.clka		(CLKA),                     \
		.aa			(AA),                       \
		.cena		(CENA),                     \
		.qa			(QA),                       \
		.clkb		(CLKB),                     \
		.ab			(AB),                       \
		.wenb		(WENB),                     \
		.cenb		(CENB),                     \
		.db			(DB));                      \
endmodule


`RFDP(32,32)
`RFDP(32,64)
`RFDP(32,96)
`RFDP(8192,8)
`RFDP(8192,64)
`RFDP(12288, 64)
`RFDP(8,96)
`RFDP(512,96)
`RFDP(1024,96)
`RFDP(8,12)
`RFDP(16,12)
`RFDP(512,32)
`RFDP(512,36)
// `RFDPWP(2048,128,32)
// `RFDP(2048,128)
// `RFDP(256,32)
// `RFDP(512,32)
// `RFDP(1024,32)
// `RFDP(256,24)
// `RFDP(64,38)
// `RFDP(32,128)
// `RFDP(32,130)

// `RFDP(262144,8)
// `RFDP(143360,8)


