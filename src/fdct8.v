// Copyright (c) 2018  LulinChen, All Rights Reserved
// AUTHOR : 	LulinChen
// AUTHOR'S EMAIL : lulinchen@aliyun.com 
// Release history
// VERSION Date AUTHOR DESCRIPTION

`include "jpeg_global.v"



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

// AP    AP
// AP   -AP

//AP    AP    AP    AP 
//BP    CP   -CP   -BP
//AP   -AP   -AP    AP
//CP   -BP    BP   -CP 

// BP   CP
// CP  -BP


// 2clks
module  bf2#(parameter DI_W=`W1P, DO_W=`W1P+`W_COEP+1)(
	input									clk,
	input									rstn,
	input			signed		[DI_W:0]	d0, d1,
	output 	reg 	signed		[DO_W:0]	q0, q1
	);
	
	reg	signed	[DI_W+1:0]	e0, o0;
	wire 		signed 	[`W_COE:0] 			m00 = `AP;
	always @(`CLK_RST_EDGE)
		if (`ZST)	{e0, o0} <= 0;
		else begin
			e0 <= d0 + d1;
			o0 <= d0 - d1;
		end
	always @(`CLK_RST_EDGE)  
        if (`ZST) {q0, q1} <= 0; 
		else begin
			q0 <= $signed(e0) * $signed(m00); 
			q1 <= $signed(o0) * $signed(m00);  
		end		
endmodule

// BP   CP
// CP  -BP

module  mult2#(parameter DI_W=`W1P, DO_W=`W1P+`W_COEP+1)(
	input									clk,
	input									rstn,
	input			signed		[DI_W:0]	d0, d1,
	output 	reg 	signed		[DO_W:0]	q0, q1
	);
	
	wire 		signed 	[`W_COE:0] 			m00, m01,
											m10, m11;	
	assign		m00  =  `BP;
	assign		m01  =  `CP;
	assign		m10  =  `CP;
	assign		m11  =  `BM;
	
	reg	signed	[DI_W+`W_COEP :0]	d0_m0, d0_m1, d1_m0, d1_m1;
	
	always @(`CLK_RST_EDGE)
		if (`ZST)	{d0_m0, d0_m1, d1_m0, d1_m1} <= 0;
		else begin
			d0_m0 <= $signed(d0) * $signed(m00);
			d1_m0 <= $signed(d1) * $signed(m01);
			d0_m1 <= $signed(d0) * $signed(m10);
			d1_m1 <= $signed(d1) * $signed(m11);
		end
	always @(`CLK_RST_EDGE)
		if (`ZST)	{q0, q1} <= 0;
		else begin
			q0 <= d0_m0 + d1_m0;
			q1 <= d0_m1 + d1_m1;
		end
endmodule
// 3clks
module  bf4#(parameter DI_W=`W1P, DO_W=`W1P+`W_COEP+2)(
    input         			clk,
    input         			rstn,
	input	signed		[DI_W:0]	d0, d1, d2, d3,
	output  signed		[DO_W:0]	q0, q1, q2, q3
	);
	wire	signed		[DO_W:0]	Eq0, Eq1, Oq0, Oq1;
	reg 	signed 		[DI_W+1:0]	E0, E1;
	reg 	signed 		[DI_W+1:0]	O0, O1;				
	always @(`CLK_RST_EDGE)  
        if (`ZST) begin
			{E0, E1} <= 0; 
			{O0, O1} <= 0;
		end else begin  
			E0 <= d0 + d3;
			E1 <= d1 + d2;
			O0 <= d0 - d3;
			O1 <= d1 - d2;
		end		
	bf2 #(.DI_W(DI_W+1), .DO_W(DI_W+1+`W_COEP+1))
		e (clk, rstn , E0, E1, Eq0, Eq1); 
	mult2 #(.DI_W(DI_W+1), .DO_W(DI_W+1+`W_COEP+1))
		o (clk, rstn , O0, O1, Oq0, Oq1); 
	assign q0 = Eq0;
	assign q1 = Oq0;
	assign q2 = Eq1;
	assign q3 = Oq1;	
endmodule


// DP    EP    FP    GP
// EP   -GP   -DP   -FP
// FP   -DP    GP    EP
// GP   -FP    EP   -DP
module  mult4#(parameter DI_W=`W1P, DO_W=`W1P+`W_COEP+2)(
	input						clk,
	input						rstn,
	input	signed	[DI_W:0]	d0, d1, d2, d3,
	output  reg  	[DO_W:0]	q0, q1, q2, q3
	);
	wire 	signed [`W_COE:0] 	m00, m01, m02, m03,
								m10, m11, m12, m13,
								m20, m21, m22, m23,
								m30, m31, m32, m33 ;	
							
	wire	[0:3][DI_W:0]	d = {d0, d1, d2, d3};
	wire	[0:3][0:3][`W_COE:0]	 m;
	reg		[0:3][0:3][DI_W+`W_COEP:0]	d_m;	
	assign m = {`DP, `EP, `FP, `GP,
	            `EP, `GM, `DM, `FM,
	            `FP, `DM, `GP, `EP,
	            `GP, `FM, `EP, `DM};
	genvar i;
	genvar j;
	generate 
		for (i=0; i<4; i=i+1) begin 
			for (j=0; j<4; j=j+1) begin 
				always @(`CLK_RST_EDGE)
					if (`ZST)	d_m[i][j] <= 0;
					else 		d_m[i][j] <= $signed(d[j]) * $signed(m[i][j]);
			end
		end
	endgenerate
	
	reg		[0:3][0:1][DO_W-1:0]	temp;
	generate 
		for (i=0; i<4; i=i+1) begin 
			for (j=0; j<2; j=j+1) begin 
				always @(`CLK_RST_EDGE)
					if (`ZST)	temp[i][j] <= 0;
					else 		temp[i][j] <= $signed(d_m[i][j*2]) + $signed(d_m[i][j*2+1]);
			end
		end
	endgenerate
	always @(`CLK_RST_EDGE)  
        if (`ZST) {q0, q1, q2, q3} <= 0;
		else begin
			q0 <=  $signed(temp[0][0]) +  $signed(temp[0][1]);
			q1 <=  $signed(temp[1][0]) +  $signed(temp[1][1]);
			q2 <=  $signed(temp[2][0]) +  $signed(temp[2][1]);
			q3 <=  $signed(temp[3][0]) +  $signed(temp[3][1]);
		end
endmodule

// 4clks
module  bf8#(parameter DI_W=`W1P, DO_W=`W1P+`W_COEP+3)(
	input							clk,
	input							rstn,
	input	signed		[DI_W:0]	d0, d1, d2, d3, d4, d5, d6, d7,
	output  signed		[DO_W:0]	q0, q1, q2, q3, q4, q5, q6, q7
	);
	
	reg 	signed 		[DI_W+1:0]	E0, E1, E2, E3;
	reg 	signed 		[DI_W+1:0]	O0, O1, O2, O3;		
	always @(`CLK_RST_EDGE)  
        if (`ZST) begin
			{E0, E1, E2, E3} <= 0; 
			{O0, O1, O2, O3} <= 0;
		end
		else begin 
			E0 <= d0 + d7; 
			E1 <= d1 + d6;	
			E2 <= d2 + d5;
			E3 <= d3 + d4;
			O0 <= d0 - d7; 
			O1 <= d1 - d6;	
			O2 <= d2 - d5;
			O3 <= d3 - d4;
		end			
	wire 	signed		[DO_W:0]	Eq0, Eq1, Eq2, Eq3;
	wire 	signed		[DO_W:0]	Oq0, Oq1, Oq2, Oq3;	
	bf4 #(.DI_W(DI_W+1), .DO_W(DI_W+1+`W_COEP+2)) 
		e (clk, rstn, E0, E1, E2, E3, Eq0, Eq1, Eq2, Eq3);
	mult4 #(.DI_W(DI_W+1), .DO_W(DI_W+1+`W_COEP+2)) 
		o (clk, rstn, O0, O1, O2, O3, Oq0, Oq1, Oq2, Oq3);
	
	assign 	q0 = Eq0;
	assign	q1 = Oq0;
	assign	q2 = Eq1;
	assign	q3 = Oq1;
	assign	q4 = Eq2;
	assign	q5 = Oq2;
	assign	q6 = Eq3;
	assign	q7 = Oq3;
endmodule
	

module fdct8(
	input								clk,
	input								rstn,	
	input								en,	
	input	signed		[`W1:0]			d0, d1, d2, d3, d4, d5, d6, d7,
	output								q_en,
	output				[2:0]			q_cnt_b1,
	output				[2:0]			q_cnt,
	output  signed		[`W_DCT2DO:0]	q0, q1, q2, q3, q4, q5, q6, q7
	);
	
	reg		[7:0]	en_d;
	always @(*)	en_d[0] = en;
	always @(`CLK_RST_EDGE)
		if (`RST)	en_d[7:1] <= 0;
		else 		en_d[7:1] <= en_d;
	wire	[`W1+`W_COEP+3 :0 ]	bf1_q0, bf1_q1, bf1_q2, bf1_q3, bf1_q4, bf1_q5, bf1_q6, bf1_q7;
	bf8	#(.DI_W(`W1), .DO_W(`W1+`W_COEP+3)) bf8(
		clk, 
		rstn,
		d0, d1, d2, d3, d4, d5, d6, d7,
		bf1_q0, bf1_q1, bf1_q2, bf1_q3, bf1_q4, bf1_q5, bf1_q6, bf1_q7
		);
	wire [`W_DCT1DO :0]	bf1_crop_q0, bf1_crop_q1, bf1_crop_q2, bf1_crop_q3, bf1_crop_q4, bf1_crop_q5, bf1_crop_q6, bf1_crop_q7;
	assign 	bf1_crop_q0 = bf1_q0[`W1+`W_COEP+3 : 12];
	assign 	bf1_crop_q1 = bf1_q1[`W1+`W_COEP+3 : 12];
	assign 	bf1_crop_q2 = bf1_q2[`W1+`W_COEP+3 : 12];
	assign 	bf1_crop_q3 = bf1_q3[`W1+`W_COEP+3 : 12];
	assign 	bf1_crop_q4 = bf1_q4[`W1+`W_COEP+3 : 12];
	assign 	bf1_crop_q5 = bf1_q5[`W1+`W_COEP+3 : 12];
	assign 	bf1_crop_q6 = bf1_q6[`W1+`W_COEP+3 : 12];
	assign 	bf1_crop_q7 = bf1_q7[`W1+`W_COEP+3 : 12];
	
	reg		[0:15][0:7][`W_DCT1DO :0] trans_r;
	always @(`CLK_RST_EDGE)
		if (`ZST)				trans_r <= 0;
		//else if (en_d[4]) begin
		else begin
			trans_r[0:14]  <= trans_r;
			trans_r[15]    <= {bf1_crop_q0, bf1_crop_q1, bf1_crop_q2, bf1_crop_q3, bf1_crop_q4, bf1_crop_q5, bf1_crop_q6, bf1_crop_q7};
		end
	reg		[2:0]	trans_r_cnt;
	always @(`CLK_RST_EDGE)
		if (`RST)				trans_r_cnt <= 0;
		else if (en_d[4])		trans_r_cnt <= trans_r_cnt + 1;
	
	// reg		bf2_go;
	// always @(`CLK_RST_EDGE)
		// if (`RST)	bf2_go <= 0;
		// else 		bf2_go <= en_d[4] && trans_r_cnt==7;
	
	wire	bf2_go = en_d[4] && trans_r_cnt==7;
	
	//go	+|
	//max_f  					 +|
	//en	 |++++++++++++++++++++|
	//cnt	 |0..............MAX-1| MAX		
	reg					cnt_bf2_e;
	reg		[ 2 :0]		cnt_bf2;
	wire				cnt_bf2_max_f = cnt_bf2 == 8-1;
	always @(`CLK_RST_EDGE)
		if (`RST)					cnt_bf2_e <= 0;
		else if (bf2_go)			cnt_bf2_e <= 1;
		else if (cnt_bf2_max_f)		cnt_bf2_e <= 0;
	
	always @(`CLK_RST_EDGE)
		if (`RST)	cnt_bf2 <= 0;
		else 		cnt_bf2 <= cnt_bf2_e? cnt_bf2 + 1 : 0;
	reg		[7:0]	cnt_bf2_e_d;
	always @(*)	cnt_bf2_e_d[0] = cnt_bf2_e;
	always @(`CLK_RST_EDGE)
		if (`RST)	cnt_bf2_e_d[7:1] <= 0;
		else 		cnt_bf2_e_d[7:1] <= cnt_bf2_e_d;
	reg		[7:0][2:0]	cnt_bf2_d;
	always @(*)	cnt_bf2_d[0] = cnt_bf2;
	always @(`CLK_RST_EDGE)
		if (`RST)	cnt_bf2_d[7:1] <= 0;
		else 		cnt_bf2_d[7:1] <= cnt_bf2_d;	
	
	wire dct2o_valid = cnt_bf2_e_d[5];
	
	reg   [`W_DCT1DO :0]  bf2_d0, bf2_d1, bf2_d2, bf2_d3, bf2_d4, bf2_d5, bf2_d6, bf2_d7;
	always @(`CLK_RST_EDGE)
		if (`ZST)	{bf2_d0, bf2_d1, bf2_d2, bf2_d3, bf2_d4, bf2_d5, bf2_d6, bf2_d7} <= 0;
		else begin
			bf2_d0 <= trans_r[0+8-cnt_bf2][cnt_bf2];
			bf2_d1 <= trans_r[1+8-cnt_bf2][cnt_bf2];
			bf2_d2 <= trans_r[2+8-cnt_bf2][cnt_bf2];
			bf2_d3 <= trans_r[3+8-cnt_bf2][cnt_bf2];
			bf2_d4 <= trans_r[4+8-cnt_bf2][cnt_bf2];
			bf2_d5 <= trans_r[5+8-cnt_bf2][cnt_bf2];
			bf2_d6 <= trans_r[6+8-cnt_bf2][cnt_bf2];
			bf2_d7 <= trans_r[7+8-cnt_bf2][cnt_bf2];		
		end
	wire [`W_DCT1DO+`W_COEP+3:0]	bf2_q0, bf2_q1, bf2_q2, bf2_q3, bf2_q4, bf2_q5, bf2_q6, bf2_q7;
	bf8	#(.DI_W(`W_DCT1DO), .DO_W(`W_DCT1DO+`W_COEP+3)) bf8_2(
		clk, 
		rstn,
		bf2_d0, bf2_d1, bf2_d2, bf2_d3, bf2_d4, bf2_d5, bf2_d6, bf2_d7,
		bf2_q0, bf2_q1, bf2_q2, bf2_q3, bf2_q4, bf2_q5, bf2_q6, bf2_q7
		);
		
	assign	q0 = bf2_q0[`W_DCT1DO+`W_COEP+3 :`W_COEP];
	assign	q1 = bf2_q1[`W_DCT1DO+`W_COEP+3 :`W_COEP];
	assign	q2 = bf2_q2[`W_DCT1DO+`W_COEP+3 :`W_COEP];
	assign	q3 = bf2_q3[`W_DCT1DO+`W_COEP+3 :`W_COEP];
	assign	q4 = bf2_q4[`W_DCT1DO+`W_COEP+3 :`W_COEP];
	assign	q5 = bf2_q5[`W_DCT1DO+`W_COEP+3 :`W_COEP];
	assign	q6 = bf2_q6[`W_DCT1DO+`W_COEP+3 :`W_COEP];
	assign	q7 = bf2_q7[`W_DCT1DO+`W_COEP+3 :`W_COEP];
	
	assign	q_en = cnt_bf2_e_d[5];
	assign	q_cnt = cnt_bf2_d[5];
	assign	q_cnt_b1 = cnt_bf2_d[4];
	
endmodule


