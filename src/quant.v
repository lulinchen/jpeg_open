// Copyright (c) 2018  LulinChen, All Rights Reserved
// AUTHOR : 	LulinChen
// AUTHOR'S EMAIL : lulinchen@aliyun.com 
// Release history
// VERSION Date AUTHOR DESCRIPTION

`include "jpeg_global.v"
// /*
 // * Table K.1 from JPEG spec.
 // */
// static const int jpeg_luma_quantizer[64] = {
        // 16, 11, 10, 16, 24, 40, 51, 61,
        // 12, 12, 14,t 19, 26, 58, 60, 55,
        // 14, 13, 16, 24, 40, 57, 69, 56,
        // 14, 17, 22, 29, 51, 87, 80, 62,
        // 18, 22, 37, 56, 68, 109, 103, 77,
        // 24, 35, 55, 64, 81, 104, 113, 92,
        // 49, 64, 78, 87, 103, 121, 120, 101,
        // 72, 92, 95, 98, 112, 100, 103, 99
// };

// /*
 // * Table K.2 from JPEG spec.
 // */
// static const int jpeg_chroma_quantizer[64] = {
        // 17, 18, 24, 47, 99, 99, 99, 99,
        // 18, 21, 26, 66, 99, 99, 99, 99,
        // 24, 26, 56, 99, 99, 99, 99, 99,
        // 47, 66, 99, 99, 99, 99, 99, 99,
        // 99, 99, 99, 99, 99, 99, 99, 99,
        // 99, 99, 99, 99, 99, 99, 99, 99,
        // 99, 99, 99, 99, 99, 99, 99, 99,
        // 99, 99, 99, 99, 99, 99, 99, 99
// };

module rom_qtable8(
    input                 	    clk,
    input 		[3:0]  			addr,
    output reg	[63:0] 			q
    );    
   
    reg 	[63:0]  	mem[2**4-1:0];
    always @(posedge clk)
        q <= mem[addr];
	initial	begin
		mem[0  ] = { 8'd16, 8'd12, 8'd14, 8'd14, 8'd18, 8'd24, 8'd49, 8'd72 };
		mem[1  ] = { 8'd11, 8'd12, 8'd13, 8'd17, 8'd22, 8'd35, 8'd64, 8'd92 };
		mem[2  ] = { 8'd10, 8'd14, 8'd16, 8'd22, 8'd37, 8'd55, 8'd78, 8'd95 };
		mem[3  ] = { 8'd16, 8'd19, 8'd24, 8'd29, 8'd56, 8'd64, 8'd87, 8'd98 };
		mem[4  ] = { 8'd24, 8'd26, 8'd40, 8'd51, 8'd68, 8'd81, 8'd103,8'd112 };
		mem[5  ] = { 8'd40, 8'd58, 8'd57, 8'd87, 8'd109,8'd104,8'd121,8'd100 };
		mem[6  ] = { 8'd51, 8'd60, 8'd69, 8'd80, 8'd103,8'd113,8'd120,8'd103 };
		mem[7  ] = { 8'd61, 8'd55, 8'd56, 8'd62, 8'd77, 8'd92, 8'd101,8'd99 };
		mem[8  ] = { 8'd17, 8'd18, 8'd24, 8'd47, 8'd99, 8'd99, 8'd99, 8'd99 };
		mem[9  ] = { 8'd18, 8'd21, 8'd26, 8'd66, 8'd99, 8'd99, 8'd99, 8'd99 };
		mem[10 ] = { 8'd24, 8'd26, 8'd56, 8'd99, 8'd99, 8'd99, 8'd99, 8'd99 };
		mem[11 ] = { 8'd47, 8'd66, 8'd99, 8'd99, 8'd99, 8'd99, 8'd99, 8'd99 };
		mem[12 ] = { 8'd99, 8'd99, 8'd99, 8'd99, 8'd99, 8'd99, 8'd99, 8'd99 };
		mem[13 ] = { 8'd99, 8'd99, 8'd99, 8'd99, 8'd99, 8'd99, 8'd99, 8'd99 };
		mem[14 ] = { 8'd99, 8'd99, 8'd99, 8'd99, 8'd99, 8'd99, 8'd99, 8'd99 };
		mem[15 ] = { 8'd99, 8'd99, 8'd99, 8'd99, 8'd99, 8'd99, 8'd99, 8'd99 };	
	end
endmodule
	
module rom_qtable(
    input                 	    clk,
    input 		[6:0]  			addr,
    output reg	[7:0] 			q
    );    
   
    reg 	[7:0]  	mem[2**7-1:0];
    always @(posedge clk)
        q <= mem[addr];
	// in coloum order
	initial	begin
		mem[0  ] = 16; 
		mem[1  ] = 12; 
		mem[2  ] = 14; 
		mem[3  ] = 14; 
		mem[4  ] = 18; 
		mem[5  ] = 24; 
		mem[6  ] = 49; 
		mem[7  ] = 72; 
		mem[8  ] = 11; 
		mem[9  ] = 12; 
		mem[10 ] = 13; 
		mem[11 ] = 17; 
		mem[12 ] = 22; 
		mem[13 ] = 35; 
		mem[14 ] = 64; 
		mem[15 ] = 92; 
		mem[16 ] = 10; 
		mem[17 ] = 14; 
		mem[18 ] = 16; 
		mem[19 ] = 22; 
		mem[20 ] = 37; 
		mem[21 ] = 55; 
		mem[22 ] = 78; 
		mem[23 ] = 95; 
		mem[24 ] = 16; 
		mem[25 ] = 19; 
		mem[26 ] = 24; 
		mem[27 ] = 29; 
		mem[28 ] = 56; 
		mem[29 ] = 64; 
		mem[30 ] = 87; 
		mem[31 ] = 98; 
		mem[32 ] = 24;  
		mem[33 ] = 26;  
		mem[34 ] = 40;  
		mem[35 ] = 51;  
		mem[36 ] = 68;  
		mem[37 ] = 81;  
		mem[38 ] = 103; 
		mem[39 ] = 112; 
		mem[40 ] = 40;  
		mem[41 ] = 58;  
		mem[42 ] = 57;  
		mem[43 ] = 87;  
		mem[44 ] = 109; 
		mem[45 ] = 104; 
		mem[46 ] = 121; 
		mem[47 ] = 100;
		mem[48 ] = 51;  
		mem[49 ] = 60;  
		mem[50 ] = 69;  
		mem[51 ] = 80;  
		mem[52 ] = 103; 
		mem[53 ] = 113; 
		mem[54 ] = 120; 
		mem[55 ] = 103; 
		mem[56 ] = 61; 
		mem[57 ] = 55;
		mem[58 ] = 56;
		mem[59 ] = 62;
		mem[60 ] = 77;
		mem[61 ] = 92;
		mem[62 ] = 101;
		mem[63 ] = 99;

		mem[64 ] = 17; 
		mem[65 ] = 18; 
		mem[66 ] = 24; 
		mem[67 ] = 47; 
		mem[68 ] = 99; 
		mem[69 ] = 99; 
		mem[70 ] = 99; 
		mem[71 ] = 99; 
		mem[72 ] = 18; 
		mem[73 ] = 21; 
		mem[74 ] = 26; 
		mem[75 ] = 66; 
		mem[76 ] = 99; 
		mem[77 ] = 99; 
		mem[78 ] = 99; 
		mem[79 ] = 99; 
		mem[80 ] = 24; 
		mem[81 ] = 26; 
		mem[82 ] = 56; 
		mem[83 ] = 99; 
		mem[84 ] = 99; 
		mem[85 ] = 99; 
		mem[86 ] = 99; 
		mem[87 ] = 99; 
		mem[88 ] = 47; 
		mem[89 ] = 66; 
		mem[90 ] = 99; 
		mem[91 ] = 99; 
		mem[92 ] = 99; 
		mem[93 ] = 99; 
		mem[94 ] = 99; 
		mem[95 ] = 99; 
		mem[96 ] = 99; 
		mem[97 ] = 99; 
		mem[98 ] = 99; 
		mem[99 ] = 99; 
		mem[100] = 99; 
		mem[101] = 99; 
		mem[102] = 99; 
		mem[103] = 99; 
		mem[104] = 99; 
		mem[105] = 99; 
		mem[106] = 99; 
		mem[107] = 99; 
		mem[108] = 99; 
		mem[109] = 99; 
		mem[110] = 99; 
		mem[111] = 99; 
		mem[112] = 99; 
		mem[113] = 99; 
		mem[114] = 99; 
		mem[115] = 99; 
		mem[116] = 99; 
		mem[117] = 99; 
		mem[118] = 99; 
		mem[119] = 99; 
		mem[120] = 99; 
		mem[121] = 99; 
		mem[122] = 99; 
		mem[123] = 99; 
		mem[124] = 99; 
		mem[125] = 99; 
		mem[126] = 99; 
		mem[127] = 99; 
    end
endmodule

module rom_divide(
    input                 	    clk,
    input 		[7:0]  			addr,
    output reg	[15:0] 			q
    );    
   
    reg 	[15:0]  	mem[2**8-1:0];
    always @(posedge clk)
        q <= mem[addr];
		
	initial	begin
	mem[0  ] = 65536;
	mem[1  ] = 65536;
	mem[2  ] = 32768;
	mem[3  ] = 21845;
	mem[4  ] = 16384;
	mem[5  ] = 13107;
	mem[6  ] = 10922;
	mem[7  ] = 9362;
	mem[8  ] = 8192;
	mem[9  ] = 7281;
	mem[10 ] = 6553;
	mem[11 ] = 5957;
	mem[12 ] = 5461;
	mem[13 ] = 5041;
	mem[14 ] = 4681;
	mem[15 ] = 4369;
	mem[16 ] = 4096;
	mem[17 ] = 3855;
	mem[18 ] = 3640;
	mem[19 ] = 3449;
	mem[20 ] = 3276;
	mem[21 ] = 3120;
	mem[22 ] = 2978;
	mem[23 ] = 2849;
	mem[24 ] = 2730;
	mem[25 ] = 2621;
	mem[26 ] = 2520;
	mem[27 ] = 2427;
	mem[28 ] = 2340;
	mem[29 ] = 2259;
	mem[30 ] = 2184;
	mem[31 ] = 2114;
	mem[32 ] = 2048;
	mem[33 ] = 1985;
	mem[34 ] = 1927;
	mem[35 ] = 1872;
	mem[36 ] = 1820;
	mem[37 ] = 1771;
	mem[38 ] = 1724;
	mem[39 ] = 1680;
	mem[40 ] = 1638;
	mem[41 ] = 1598;
	mem[42 ] = 1560;
	mem[43 ] = 1524;
	mem[44 ] = 1489;
	mem[45 ] = 1456;
	mem[46 ] = 1424;
	mem[47 ] = 1394;
	mem[48 ] = 1365;
	mem[49 ] = 1337;
	mem[50 ] = 1310;
	mem[51 ] = 1285;
	mem[52 ] = 1260;
	mem[53 ] = 1236;
	mem[54 ] = 1213;
	mem[55 ] = 1191;
	mem[56 ] = 1170;
	mem[57 ] = 1149;
	mem[58 ] = 1129;
	mem[59 ] = 1110;
	mem[60 ] = 1092;
	mem[61 ] = 1074;
	mem[62 ] = 1057;
	mem[63 ] = 1040;
	mem[64 ] = 1024;
	mem[65 ] = 1008;
	mem[66 ] = 992;
	mem[67 ] = 978;
	mem[68 ] = 963;
	mem[69 ] = 949;
	mem[70 ] = 936;
	mem[71 ] = 923;
	mem[72 ] = 910;
	mem[73 ] = 897;
	mem[74 ] = 885;
	mem[75 ] = 873;
	mem[76 ] = 862;
	mem[77 ] = 851;
	mem[78 ] = 840;
	mem[79 ] = 829;
	mem[80 ] = 819;
	mem[81 ] = 809;
	mem[82 ] = 799;
	mem[83 ] = 789;
	mem[84 ] = 780;
	mem[85 ] = 771;
	mem[86 ] = 762;
	mem[87 ] = 753;
	mem[88 ] = 744;
	mem[89 ] = 736;
	mem[90 ] = 728;
	mem[91 ] = 720;
	mem[92 ] = 712;
	mem[93 ] = 704;
	mem[94 ] = 697;
	mem[95 ] = 689;
	mem[96 ] = 682;
	mem[97 ] = 675;
	mem[98 ] = 668;
	mem[99 ] = 661;
	mem[100] = 655;
	mem[101] = 648;
	mem[102] = 642;
	mem[103] = 636;
	mem[104] = 630;
	mem[105] = 624;
	mem[106] = 618;
	mem[107] = 612;
	mem[108] = 606;
	mem[109] = 601;
	mem[110] = 595;
	mem[111] = 590;
	mem[112] = 585;
	mem[113] = 579;
	mem[114] = 574;
	mem[115] = 569;
	mem[116] = 564;
	mem[117] = 560;
	mem[118] = 555;
	mem[119] = 550;
	mem[120] = 546;
	mem[121] = 541;
	mem[122] = 537;
	mem[123] = 532;
	mem[124] = 528;
	mem[125] = 524;
	mem[126] = 520;
	mem[127] = 516;
	mem[128] = 512;
	mem[129] = 508;
	mem[130] = 504;
	mem[131] = 500;
	mem[132] = 496;
	mem[133] = 492;
	mem[134] = 489;
	mem[135] = 485;
	mem[136] = 481;
	mem[137] = 478;
	mem[138] = 474;
	mem[139] = 471;
	mem[140] = 468;
	mem[141] = 464;
	mem[142] = 461;
	mem[143] = 458;
	mem[144] = 455;
	mem[145] = 451;
	mem[146] = 448;
	mem[147] = 445;
	mem[148] = 442;
	mem[149] = 439;
	mem[150] = 436;
	mem[151] = 434;
	mem[152] = 431;
	mem[153] = 428;
	mem[154] = 425;
	mem[155] = 422;
	mem[156] = 420;
	mem[157] = 417;
	mem[158] = 414;
	mem[159] = 412;
	mem[160] = 409;
	mem[161] = 407;
	mem[162] = 404;
	mem[163] = 402;
	mem[164] = 399;
	mem[165] = 397;
	mem[166] = 394;
	mem[167] = 392;
	mem[168] = 390;
	mem[169] = 387;
	mem[170] = 385;
	mem[171] = 383;
	mem[172] = 381;
	mem[173] = 378;
	mem[174] = 376;
	mem[175] = 374;
	mem[176] = 372;
	mem[177] = 370;
	mem[178] = 368;
	mem[179] = 366;
	mem[180] = 364;
	mem[181] = 362;
	mem[182] = 360;
	mem[183] = 358;
	mem[184] = 356;
	mem[185] = 354;
	mem[186] = 352;
	mem[187] = 350;
	mem[188] = 348;
	mem[189] = 346;
	mem[190] = 344;
	mem[191] = 343;
	mem[192] = 341;
	mem[193] = 339;
	mem[194] = 337;
	mem[195] = 336;
	mem[196] = 334;
	mem[197] = 332;
	mem[198] = 330;
	mem[199] = 329;
	mem[200] = 327;
	mem[201] = 326;
	mem[202] = 324;
	mem[203] = 322;
	mem[204] = 321;
	mem[205] = 319;
	mem[206] = 318;
	mem[207] = 316;
	mem[208] = 315;
	mem[209] = 313;
	mem[210] = 312;
	mem[211] = 310;
	mem[212] = 309;
	mem[213] = 307;
	mem[214] = 306;
	mem[215] = 304;
	mem[216] = 303;
	mem[217] = 302;
	mem[218] = 300;
	mem[219] = 299;
	mem[220] = 297;
	mem[221] = 296;
	mem[222] = 295;
	mem[223] = 293;
	mem[224] = 292;
	mem[225] = 291;
	mem[226] = 289;
	mem[227] = 288;
	mem[228] = 287;
	mem[229] = 286;
	mem[230] = 284;
	mem[231] = 283;
	mem[232] = 282;
	mem[233] = 281;
	mem[234] = 280;
	mem[235] = 278;
	mem[236] = 277;
	mem[237] = 276;
	mem[238] = 275;
	mem[239] = 274;
	mem[240] = 273;
	mem[241] = 271;
	mem[242] = 270;
	mem[243] = 269;
	mem[244] = 268;
	mem[245] = 267;
	mem[246] = 266;
	mem[247] = 265;
	mem[248] = 264;
	mem[249] = 263;
	mem[250] = 262;
	mem[251] = 261;
	mem[252] = 260;
	mem[253] = 259;
	mem[254] = 258;
	mem[255] = 257;
	end 
        
endmodule

module quant(
	input						clk,
	input						rstn,
	input						en,
	input		[`W_DCT2DO :0]	d,
	input		[7:0]			quant_step,
	output reg					q_en,
	output reg	[`W_QUANTO:0]	q
	);
	reg		[7:0]		quant_step_d1;
	always @(`CLK_RST_EDGE)
		if (`ZST)	quant_step_d1 <= 0;
		else 		quant_step_d1 <= quant_step;
	reg		[7:0][`W_DCT2DO:0]	d_d;
	always @(*)	d_d[0] = d;
	always @(`CLK_RST_EDGE)
		if (`RST)	d_d[7:1] <= 0;
		else 		d_d[7:1] <= d_d;
	reg		[7:0]	en_d;
	always @(*)	en_d[0] = en;
	always @(`CLK_RST_EDGE)
		if (`RST)	en_d[7:1] <= 0;
		else 		en_d[7:1] <= en_d;		
	
	wire	[15:0]	q_rom_divide;
	reg		[15:0]		q_rom_divide_d1;
	always @(`CLK_RST_EDGE)
		if (`ZST)	q_rom_divide_d1 <= 0;
		else 		q_rom_divide_d1 <= q_rom_divide;
		
	rom_divide rom_divide(
		clk,
		quant_step_d1,
		q_rom_divide
		);
	reg		[`W_DCT2DO+16:0]	mult;
	always @(`CLK_RST_EDGE)
		if (`ZST)	mult <= 0;
		else 		mult <= $signed(d_d[3]) * $signed({1'b0, q_rom_divide_d1});
	
	//  d	1	2	3	4
	//  quant_step		
	//		quant_step_d1
	//			q_rom_divide
	//				q_rom_divide_d1
	//					mult
	// 
	always @(`CLK_RST_EDGE)
		if (`ZST)	q <= 0;
		else  		q <= $signed(mult[`W_DCT2DO+16:16]) + {1'b0, mult[15]};
	always @(`CLK_RST_EDGE)
		if (`RST)	q_en <= 0;
		else 		q_en <= en_d[4];
endmodule
       



