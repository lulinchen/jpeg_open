
`ifndef jpeg_pkg
`define jpeg_pkg

`ifdef TIMESCALE_PS	
	`timescale 1ps/1ps
	`define TIME_COEFF		1000
`else
	`timescale 1ns/1ps
	`define TIME_COEFF		1
`endif

`define	W_VLCO	27
`define	W_VLCL	4

`define	W_BSDI	27
`define	W_BSDIL 4


`define 	INPUT_RGB_FILE 

`define MAX_PIC_WIDTH	2048
// in 8x8 size
`define W_PWInMbs 	 8 - 1  //   1280x720
`define W_PHInMbs 	 8 - 1  // 


`define W_PWInMbsM1		 `W_PWInMbs
`define W_PHInMbsM1		 `W_PHInMbs

`define	W_PICMBS	(`W_PWInMbs + `W_PHInMbs + 1)

`define W_PW	`W_PWInMbs+3     // 11-1 
`define W_PH	`W_PHInMbs+3	 // 11-1

`define LUMA_LINE_WORDS 			(`MAX_PIC_WIDTH /  8)
`define CAM_YA0                                      		   0 
`define CAM_YA1   			(`CAM_YA00 + `LUMA_LINE_WORDS   *  1)
`define CAM_YA2   			(`CAM_YA00 + `LUMA_LINE_WORDS   *  2)
`define CAM_YA3   			(`CAM_YA00 + `LUMA_LINE_WORDS   *  3)
`define CAM_YA4   			(`CAM_YA00 + `LUMA_LINE_WORDS   *  4)
`define CAM_YA5   			(`CAM_YA00 + `LUMA_LINE_WORDS   *  5)
`define CAM_YA6   			(`CAM_YA00 + `LUMA_LINE_WORDS   *  6)
`define CAM_YA7   			(`CAM_YA00 + `LUMA_LINE_WORDS   *  7)
`define CAM_YA8   			(`CAM_YA00 + `LUMA_LINE_WORDS   *  8)


`define W_WCAMBUF			3
//`define W_DCAMBUF	   		`W16
`define W_DCAMBUF	   		`W8
`ifdef YUV444_ONLY
	`define W_ACAMBUF			(`W_PW+3)		// MAX_PIC_WIDTH *48 line / 8pix
`elsif YUV422_ONLY
	`define W_ACAMBUF			(`W_PW+2)		// MAX_PIC_WIDTH *32 line / 8pix 
`endif

`define W1                 7
`define W2                15
`define W3                23
`define W4                31
`define W5                39
`define W6                47
`define W7                55
`define W8                63
`define W9                71
`define W10               79
`define W11               87
`define W12               95
`define W13              103
`define W14              111
`define W15              119
`define W16              127
`define W17              135
`define W18              143
`define W19              151
`define W20              159
`define W21              167
`define W22              175
`define W23              183
`define W24              191
`define W25              199
`define W26              207
`define W27              215
`define W28              223
`define W29              231
`define W30              239
`define W31              247
`define W32              255
`define W48              383
`define W64              511
`define W63              503
`define W71				 567
`define W72				 575
`define W78				 623
`define W79				 631	
`define W80			     639
`define W128            1023
`define W256            2047
`define W512            4095

`define W1P                 (`W1  + 1)          // P = Plus1
`define W2P                 (`W2  + 1)
`define W3P                 (`W3  + 1)
`define W4P                 (`W4  + 1)
`define W5P                 (`W5  + 1)
`define W6P                 (`W6  + 1)
`define W7P                 (`W7  + 1)
`define W8P                 (`W8  + 1)
`define W9P                 (`W9  + 1)
`define W10P                (`W10 + 1)
`define W11P                (`W11 + 1)
`define W12P                (`W12 + 1)
`define W13P                (`W13 + 1)
`define W14P                (`W14 + 1)
`define W15P                (`W15 + 1)
`define W16P                (`W16 + 1)
`define W17P                (`W17 + 1)
`define W18P                (`W18 + 1)
`define W19P                (`W19 + 1)
`define W20P                (`W20 + 1)
`define W32P                (`W32 + 1)
`define W48P                (`W48 + 1)
`define W64P                (`W64 + 1)

`define NO_JFIF_MARKER

`ifdef NO_JFIF_MARKER
	`define		ADDR_SIZE_Y_H   (25-18)
	`define		HEADER_SIZE   	(623-18)
`else
	`define		ADDR_SIZE_Y_H   25
	`define		HEADER_SIZE		623
`endif

`define		C_MAX_LINE_WIDTH    2048
`define 	W_ADDR_BUF_FIFO		(11+4)		// 16 line pixels  2048 *16 =
 
`define		C_PIXEL_BITS   		24
`define 	C_NUM_LINES         16

`ifndef YUV422_ONLY
	`define YUV444_ONLY
`endif
`ifdef YUV422_ONLY
	`define 	W_CMP_IDX         2
	`define 	CMP_IDX_MAX       4
	`define 	CMP_PORTION       2
`else
	`define 	W_CMP_IDX         1
	`define 	CMP_IDX_MAX       3
	`define 	CMP_PORTION       3
`endif

`ifdef YUV422_ONLY 
	`define W_CAMD_I  `W2
`else
	`define W_CAMD_I  `W3
`endif
`define BD_OFFSET	0 



`define  IP_W 8
`define  OP_W 12
`define  N 8
`define  COE_W 12
`define  ROMDATA_W (`COE_W + 2)   // dct1d crop  
`define  ROMADDR_W 6
`define  RAMDATA_W 10
`define  RAMADRR_W 6
`define  COL_MAX `N - 1
`define  ROW_MAX `N - 1
`define  LEVEL_SHIFT 128
`define  DA_W (`ROMDATA_W + `IP_W)	// dct1d
`define  DA2_W (`DA_W + 2)

`define W_COE	11
`define W_COEP	12

`define W_DCT1DO  9
`define W_DCT2DO  11

`define W_QUANTO  11

`ifdef YUV444_ONLY
	`define	W_AEEBUF		(5-1)   // 32
`elsif YUV422_ONLY
	`define	W_AEEBUF		(6-1)   // 64  y+y+u+v 32 + mbinfo
`endif
`define	W_DEEBUF			(96-1)
`define	W_AEEBUF_ID			3		// 16 mb


//1448    1448    1448    1448    1448    1448    1448    1448
//2009    1703    1138     400    -400   -1138   -1703   -2009
//1892     784    -784   -1892   -1892    -784     784    1892
//1703    -400   -2009   -1138    1138    2009     400   -1703
//1448   -1448   -1448    1448    1448   -1448   -1448    1448
//1138   -2009     400    1703   -1703    -400    2009   -1138
// 784   -1892    1892    -784    -784    1892   -1892     784
// 400   -1138    1703   -2009    2009   -1703    1138    -400
 
// AP    AP    AP    AP    AP    AP    AP    AP
// DP    EP    FP    GP   -GP   -FP   -EP   -DP
// BP    CP   -CP   -BP   -BP   -CP    CP    BP
// EP   -GP   -DP   -FP    FP    DP    GP   -EP
// AP   -AP   -AP    AP    AP   -AP   -AP    AP
// FP   -DP    GP    EP   -EP   -GP    DP   -FP
// CP   -BP    BP   -CP   -CP    BP   -BP    CP
// GP   -FP    EP   -DP    DP   -EP    FP   -GP






 
 

`define  AP (12'd1448 )
`define  BP (12'd1892 )
`define  CP (12'd784  )
`define  DP (12'd2009 )
`define  EP (12'd1703 )
`define  FP (12'd1138 )
`define  GP (12'd400  )
`define  AM (-12'd1448)
`define  BM (-12'd1892)
`define  CM (-12'd784 )
`define  DM (-12'd2009)
`define  EM (-12'd1703)
`define  FM (-12'd1138)
`define  GM (-12'd400 )


`define       C_Y_1  4899
`define       C_Y_2  9617
`define       C_Y_3  1868
`define       C_Cb_1 -2764
`define       C_Cb_2 -5428
`define       C_Cb_3 8192
`define       C_Cr_1 8192
`define       C_Cr_2 -6860
`define       C_Cr_3 -1332





`ifdef SIMULATION_FREQ_133MHZ
	`define	CLK_PERIOD_DIV2			(3.750*`TIME_COEFF) 		// 133.3 MHz
`elsif SIMULATION_FREQ_333MHZ
	`define	CLK_PERIOD_DIV2			(1.500*`TIME_COEFF) 		// 333.3 MHz
`elsif SIMULATION_FREQ_200MHZ
	`define	CLK_PERIOD_DIV2			(2.500*`TIME_COEFF) 		// 200.0 MHz
	`define	EE_CLOCK_PERIOD_DIV2	(1.670*`TIME_COEFF) 		// 300MHz
`elsif SIMULATION_FREQ_300MHZ
	`define	CLK_PERIOD_DIV2			(1.670*`TIME_COEFF) 		// 300MHz
`elsif SIMULATION_FREQ_275MHZ
	`define	CLK_PERIOD_DIV2			(1.800*`TIME_COEFF) 		// 275MHz
`elsif SIMULATION_FREQ_250MHZ
	`define	CLK_PERIOD_DIV2			(2.000*`TIME_COEFF) 		// 250MHz	
`else
	`define	CLK_PERIOD_DIV2			(2.500*`TIME_COEFF) 		// 200.0 MHz
	`define	EE_CLOCK_PERIOD_DIV2	(1.670*`TIME_COEFF) 		// 300MHz
`endif 	
`define	CLOCK_PERIOD		(  2 * `CLK_PERIOD_DIV2)
`define	RESET_DELAY			(200 * `CLOCK_PERIOD   )



`define RST_CAM				!rstn_cam

`ifdef SIMULATING
	`define RST          !rstn
	`define ZST          1'b0
	`define ZST_CAM			1'b0
	`define CLK_RST_EDGE posedge clk
	`define CLK_EDGE     posedge clk
	`define RST_EDGE
	`define RST_EDGE_CAM	or negedge rstn_cam
	`define RESET_ACTIVE 1'b0
	`define RESET_IDLE   1'b1
`elsif FPGA_0_XILINX
	`define RST          !rstn
	`define ZST          1'b0
	`define ZST_CAM			1'b0
	`define CLK_RST_EDGE posedge clk
	`define CLK_EDGE     posedge clk
	`define RST_EDGE
	`define RST_EDGE_CAM 	
	`define RESET_ACTIVE 1'b0
	`define RESET_IDLE   1'b1
`else
	`define RST          !rstn
	`define ZST          !rstn
	`define ZST_CAM			!rstn_cam
	`define CLK_RST_EDGE posedge clk or negedge rstn
	`define CLK_EDGE     posedge clk
	`define RST_EDGE    
	`define RST_EDGE_CAM	or negedge rstn_cam
	`define RESET_ACTIVE 1'b0
	`define RESET_IDLE   1'b1
`endif	
`endif
