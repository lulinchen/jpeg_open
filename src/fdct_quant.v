// Copyright (c) 2018  LulinChen, All Rights Reserved
// AUTHOR : 	LulinChen
// AUTHOR'S EMAIL : lulinchen@aliyun.com 
// Release history
// VERSION Date AUTHOR DESCRIPTION
`include "jpeg_global.v"
module fdct_quant(
	input 					 			clk,
	input 					 			rstn,
	input								fdct_go,
	input								last_mb_in_pic_i,
	input								last_mb_in_row_i,
	input			[`W_PWInMbsM1:0]	MB_Col,
	input			[`W_PHInMbsM1:0]	MB_Row,
	output	reg		[`W_ACAMBUF:0]		aa_camera_buf,
	output	reg							cena_camera_buf,
	input			[`W8:0]				qa_camera_buf,
	
	output	reg							ready_for_next,
	output	reg							cenb_ee_buf,
	output	reg		[`W_AEEBUF :0]		ab_ee_buf,
	output	reg		[`W_DEEBUF :0]		db_ee_buf,
	output	reg		[`W_AEEBUF_ID :0]	wid_ee_buf,
	output								wr_ee_buf_ready
	);
`ifdef YUV444_ONLY
	parameter MAX_VALUE = 24;
`else
	parameter MAX_VALUE = 32;    // YYUV
`endif
	
	reg		[`W_PWInMbsM1:0]	MB_Col_mbinfo;
	reg		[ 2:0]				cmp_idx;
	
	wire		MB_Row_ready = last_mb_in_row_i & ready_for_next;
	reg			last_mb_in_pic;
	always @(`CLK_RST_EDGE)
		if (`RST)				last_mb_in_pic <= 0;
		else if(fdct_go)		last_mb_in_pic <= last_mb_in_pic_i;
	reg			last_mb_in_pic_mbinfo;
	always @(`CLK_RST_EDGE)
		if (`RST)					last_mb_in_pic_mbinfo <= 0;
		else if(ready_for_next)		last_mb_in_pic_mbinfo <= last_mb_in_pic;
	always @(`CLK_RST_EDGE)
		if (`RST)					MB_Col_mbinfo <= 0;
		else if(ready_for_next)		MB_Col_mbinfo <= MB_Col;

	//go	+|
	//max_f  					 +|
	//en	 |++++++++++++++++++++|
	//cnt	 |0..............MAX-1| MAX		
	reg					cnt_fdct_e;
	reg		[ 4 :0]		cnt_fdct;
	wire				cnt_fdct_max_f = cnt_fdct == MAX_VALUE-1;
	always @(`CLK_RST_EDGE)
		if (`RST)					cnt_fdct_e <= 0;
		else if (fdct_go)			cnt_fdct_e <= 1;
		else if (cnt_fdct_max_f)	cnt_fdct_e <= 0;
	
	always @(`CLK_RST_EDGE)
		if (`RST)	cnt_fdct <= 0;
		else 		cnt_fdct <= cnt_fdct_e? cnt_fdct + 1 : 0;
	
	
	reg		[7:0]	cnt_fdct_max_f_d;
	always @(*)	cnt_fdct_max_f_d[0] = cnt_fdct_max_f;
	always @(`CLK_RST_EDGE)
		if (`RST)	cnt_fdct_max_f_d[7:1] <= 0;
		else 		cnt_fdct_max_f_d[7:1] <= cnt_fdct_max_f_d;
		
	always @(`CLK_RST_EDGE)
		if (`RST)	ready_for_next <= 0;
`ifdef YUV444_ONLY
		else 		ready_for_next <= cnt_fdct_max_f_d[1];
`elsif YUV422_ONLY
		else 		ready_for_next <= cnt_fdct_max_f_d[2];
`endif	
	
	
	always @(*) cmp_idx = cnt_fdct[4:3];
	
	reg			rid_camera_buf;
	always @(`CLK_RST_EDGE)
		if (`RST)				rid_camera_buf <= 0;
		// else if (MB_Row_ready)	rid_camera_buf <= rid_camera_buf + 1;
		else					rid_camera_buf <= MB_Row[0];
	always @(`CLK_RST_EDGE)
		if (`RST)	cena_camera_buf <= 1;
		else 		cena_camera_buf <= ~cnt_fdct_e;
	//TODO  change to adder
	always @(`CLK_RST_EDGE)
		if (`RST)	aa_camera_buf <= 0;
`ifdef YUV444_ONLY
		else 		aa_camera_buf <= MB_Col + cnt_fdct[2:0]*`LUMA_LINE_WORDS + `LUMA_LINE_WORDS*16*cmp_idx + rid_camera_buf*8*`LUMA_LINE_WORDS;
`elsif YUV422_ONLY
		else if (cmp_idx<2)
					aa_camera_buf <= (MB_Col<<1) + cmp_idx  + cnt_fdct[2:0]*`LUMA_LINE_WORDS + rid_camera_buf*8*`LUMA_LINE_WORDS;
		else if (cmp_idx==2)
					aa_camera_buf <= MB_Col + cnt_fdct[2:0]*`LUMA_LINE_WORDS/2 + rid_camera_buf*8*`LUMA_LINE_WORDS/2 + `LUMA_LINE_WORDS*16;		
		else 		aa_camera_buf <= MB_Col + cnt_fdct[2:0]*`LUMA_LINE_WORDS/2 + rid_camera_buf*8*`LUMA_LINE_WORDS/2 + `LUMA_LINE_WORDS*24;
`endif
	reg		[0:7][`W1:0]		qa_camera_buf_d1;
	always @(`CLK_RST_EDGE)
		if (`ZST)	qa_camera_buf_d1 <= 0;
		else 		qa_camera_buf_d1 <= qa_camera_buf;	
	
	// cnt_fdct_e  1        2        3      4 
	// cnt_fdct
	// cmp_idx		aa 		qa	
	//								qa_d1	
	//										fdct_d
	//
	
	reg		[15:0]	cnt_fdct_e_d;
	always @(*)		cnt_fdct_e_d[0] = cnt_fdct_e;
	always @(`CLK_RST_EDGE)
		if (`RST)	cnt_fdct_e_d[15:1] <= 0;
		else 		cnt_fdct_e_d[15:1] <= cnt_fdct_e_d;
	reg		[15:0][2:0]	cmp_idx_d;
	always @(*)	cmp_idx_d[0] = cmp_idx;
	always @(`CLK_RST_EDGE)
		if (`RST)	cmp_idx_d[15:1] <= 0;
		else 		cmp_idx_d[15:1] <= cmp_idx_d;
	reg		[15:0][2:0]	cnt_fdct_d;
	always @(*)	cnt_fdct_d[0] = cnt_fdct;
	always @(`CLK_RST_EDGE)
		if (`RST)	cnt_fdct_d[15:1] <= 0;
		else 		cnt_fdct_d[15:1] <= cnt_fdct_d;	
		
	
	reg	 [ 0:7][`W1:0]  fdct_di;
	always @(`CLK_RST_EDGE)
		if (`RST)	fdct_di <= 0;
		else begin
			for(int i=0; i<8; i=i+1)
				fdct_di[i] <= qa_camera_buf_d1[i] - `LEVEL_SHIFT;
		end
	wire		[ 2:0]			fdct_cmp_idx = cmp_idx_d[4];
	wire						fdcto_en;
	wire		[ 2:0]			fdcto_cnt_b1;
	wire		[ 2:0]			fdcto_cnt;
	wire		[`W_DCT2DO:0]	dct8_q0, dct8_q1, dct8_q2, dct8_q3, dct8_q4, dct8_q5, dct8_q6, dct8_q7;

	fdct8 fdct8(
		clk, 
		rstn, 
		cnt_fdct_e_d[4],
		fdct_di[0], fdct_di[1], fdct_di[2], fdct_di[3], fdct_di[4], fdct_di[5], fdct_di[6], fdct_di[7],
		fdcto_en,
		fdcto_cnt_b1, 
		fdcto_cnt,
		dct8_q0, dct8_q1, dct8_q2, dct8_q3, dct8_q4, dct8_q5, dct8_q6, dct8_q7
		);
	reg		[31:0][2:0]	fdct_cmp_idx_d;
	always @(*)	fdct_cmp_idx_d[0] = fdct_cmp_idx;
	always @(`CLK_RST_EDGE)
		if (`RST)	fdct_cmp_idx_d[31:1] <= 0;
		else 		fdct_cmp_idx_d[31:1] <= fdct_cmp_idx_d;

	wire	[1:0]	quant_cmp_idx_b2 = fdct_cmp_idx_d[15];
	wire	[1:0]	quant_cmp_idx_b1 = fdct_cmp_idx_d[16];
	wire	[1:0]	quant_cmp_idx = fdct_cmp_idx_d[17];
	
	wire	[4:0]	quant_cnt = {quant_cmp_idx, fdcto_cnt};
	
	reg		[7:0][4:0]	quant_cnt_d;
	always @(*)	quant_cnt_d[0] = quant_cnt;
	always @(`CLK_RST_EDGE)
		if (`RST)	quant_cnt_d[7:1] <= 0;
		else 		quant_cnt_d[7:1] <= quant_cnt_d;
	
	wire	[4:0]	quanto_cnt = quant_cnt_d[5];	
	
	
	wire	[0:7][7:0]	q_rom_qtable8;
	reg			[7:0]	fdcto_en_d;
	always @(*)	fdcto_en_d[0] = fdcto_en;
	always @(`CLK_RST_EDGE)
		if (`RST)	fdcto_en_d[7:1] <= 0;
		else 		fdcto_en_d[7:1] <= fdcto_en_d;
		
	reg		[0:7]						quanto_en;
	reg		[0:7][`W_QUANTO:0]			quanto;
	reg		[`W_QUANTO:0]				quanto_q0, quanto_q1, quanto_q2, quanto_q3, quanto_q4, quanto_q5, quanto_q6, quanto_q7;
	
	reg				table_select;
	
	
	always @(`CLK_RST_EDGE)
		if (`RST)	table_select <= 0;
`ifdef YUV444_ONLY
		else 		table_select <= quant_cmp_idx_b2==0? 0:1;
`elsif YUV422_ONLY
		else 		table_select <= quant_cmp_idx_b2[1];
`endif
	rom_qtable8 rom_qtable8(
		clk,
		{table_select, fdcto_cnt_b1},
		q_rom_qtable8
		);
	quant quant0(clk, rstn, fdcto_en, dct8_q0, q_rom_qtable8[0], quanto_en[0], quanto_q0);
	quant quant1(clk, rstn, fdcto_en, dct8_q1, q_rom_qtable8[1], quanto_en[1], quanto_q1);
	quant quant2(clk, rstn, fdcto_en, dct8_q2, q_rom_qtable8[2], quanto_en[2], quanto_q2);
	quant quant3(clk, rstn, fdcto_en, dct8_q3, q_rom_qtable8[3], quanto_en[3], quanto_q3);
	quant quant4(clk, rstn, fdcto_en, dct8_q4, q_rom_qtable8[4], quanto_en[4], quanto_q4);
	quant quant5(clk, rstn, fdcto_en, dct8_q5, q_rom_qtable8[5], quanto_en[5], quanto_q5);
	quant quant6(clk, rstn, fdcto_en, dct8_q6, q_rom_qtable8[6], quanto_en[6], quanto_q6);
	quant quant7(clk, rstn, fdcto_en, dct8_q7, q_rom_qtable8[7], quanto_en[7], quanto_q7);

	reg		[0:8*8*`CMP_IDX_MAX-1] quanto_nz;
	always @(`CLK_RST_EDGE)
		if (`RST)	quanto_nz <= 0;
		else if (quanto_en[7]) begin		
			quanto_nz[0:8*8*`CMP_IDX_MAX -1-8] <=	quanto_nz;
			quanto_nz[8*8*`CMP_IDX_MAX-8:8*8*`CMP_IDX_MAX-1] <= {|quanto_q0, |quanto_q1, |quanto_q2, |quanto_q3, |quanto_q4, |quanto_q5, |quanto_q6, |quanto_q7};
		end

	reg		[0:`CMP_IDX_MAX-1][0:63] 	quanto_nz_zigzag;
	always@* begin
		for(int j=0; j<`CMP_IDX_MAX; j=j+1)
			for(int i=0; i<64; i=i+1)
				quanto_nz_zigzag[j][i] = quanto_nz[dezigzag(i) + j *64];
	end
	
	//============== write ee_fifo =================================

	reg				quant_ready;
	always @(`CLK_RST_EDGE)
		if (`RST)	quant_ready <= 0;
		else 		quant_ready <= quanto_en[0] && quanto_cnt== (MAX_VALUE-1);
	reg		[7:0]	quant_ready_d;
	always @(*)	quant_ready_d[0] = quant_ready;
	
	assign			wr_ee_buf_ready = quant_ready_d[`CMP_IDX_MAX];
	always @(`CLK_RST_EDGE)
		if (`RST)	quant_ready_d[7:1] <= 0;
		else 		quant_ready_d[7:1] <= quant_ready_d;	
	
	always @(`CLK_RST_EDGE)
		if (`RST)						wid_ee_buf <= 0;
		else if (wr_ee_buf_ready) 		wid_ee_buf <= wid_ee_buf + 1;		
	always @(`CLK_RST_EDGE)
		if (`RST)						cenb_ee_buf <= 1;
		else if (quanto_en[0]) 			cenb_ee_buf <= 0;
		else if (quant_ready_d[0]) 		cenb_ee_buf <= 0;
		else if (quant_ready_d[1]) 		cenb_ee_buf <= 0;
		else if (quant_ready_d[2]) 		cenb_ee_buf <= 0;
`ifdef YUV422_ONLY
		else if (quant_ready_d[3]) 		cenb_ee_buf <= 0;
`endif
		else							cenb_ee_buf <= 1;
	always @(`CLK_RST_EDGE)
		if (`RST)						db_ee_buf <= 0;
		else if (quanto_en[0])			db_ee_buf <= {quanto_q0, quanto_q1, quanto_q2, quanto_q3, quanto_q4, quanto_q5, quanto_q6, quanto_q7};
`ifdef SIMULATING
		else begin
			for(int j=0; j<`CMP_IDX_MAX; j=j+1)
				if (quant_ready_d[j]) 		db_ee_buf <= {MB_Col_mbinfo, last_mb_in_pic_mbinfo, quanto_nz_zigzag[j]};
		end
		// else if (quant_ready_d[0]) 		db_ee_buf <= {MB_Col_mbinfo, last_mb_in_pic_mbinfo, quanto_nz_zigzag[0]};
		// else if (quant_ready_d[1]) 		db_ee_buf <= {MB_Col_mbinfo, last_mb_in_pic_mbinfo, quanto_nz_zigzag[1]};
		// else if (quant_ready_d[2]) 		db_ee_buf <= {MB_Col_mbinfo, last_mb_in_pic_mbinfo, quanto_nz_zigzag[2]};
`else
		else begin
			for(int j=0; j<`CMP_IDX_MAX; j=j+1)
				if (quant_ready_d[j]) 		db_ee_buf <= {last_mb_in_pic_mbinfo, quanto_nz_zigzag[j]};
		end
		// else if (quant_ready_d[0]) 		db_ee_buf <= {last_mb_in_pic_mbinfo, quanto_nz_zigzag[0]};
		// else if (quant_ready_d[1]) 		db_ee_buf <= {last_mb_in_pic_mbinfo, quanto_nz_zigzag[1]};
		// else if (quant_ready_d[2]) 		db_ee_buf <= {last_mb_in_pic_mbinfo, quanto_nz_zigzag[2]};
`endif
		
	always @(`CLK_RST_EDGE)
		if (`RST)						ab_ee_buf <= 0;
		else if(quanto_en[0])			ab_ee_buf <= quanto_cnt;	
		else begin
			for(int j=0; j<`CMP_IDX_MAX; j=j+1)
				if (quant_ready_d[j]) 	ab_ee_buf <= ab_ee_buf + 1;
		end
		// else if (quant_ready_d[0]) 		ab_ee_buf <= ab_ee_buf + 1;
		// else if (quant_ready_d[1]) 		ab_ee_buf <= ab_ee_buf + 1;
		// else if (quant_ready_d[2]) 		ab_ee_buf <= ab_ee_buf + 1;
	
	function [5:0]	dezigzag( input	[5:0] zigzaged	);
		begin
			case (zigzaged)
			6'd0 :  dezigzag = 0;
			6'd1 :  dezigzag = 8;
			6'd2 :  dezigzag = 1;
			6'd3 :  dezigzag = 2; 
			6'd4 :  dezigzag = 9;
			6'd5 :  dezigzag = 16;
			6'd6 :  dezigzag = 24;
			6'd7 :  dezigzag = 17; 
			6'd8 :  dezigzag = 10; 
			6'd9 :  dezigzag = 3; 
			6'd10:  dezigzag = 4; 
			6'd11:  dezigzag = 11; 
			6'd12:  dezigzag = 18; 
			6'd13:  dezigzag = 25; 
			6'd14:  dezigzag = 32;
			6'd15:  dezigzag = 40;
			6'd16:  dezigzag = 33; 
			6'd17:  dezigzag = 26; 
			6'd18:  dezigzag = 19; 
			6'd19:  dezigzag = 12; 
			6'd20:  dezigzag = 5; 
			6'd21:  dezigzag = 6; 
			6'd22:  dezigzag = 13; 
			6'd23:  dezigzag = 20; 
			6'd24:  dezigzag = 27; 
			6'd25:  dezigzag = 34; 
			6'd26:  dezigzag = 41; 
			6'd27:  dezigzag = 48;
			6'd28:  dezigzag = 56;
			6'd29:  dezigzag = 49; 
			6'd30:  dezigzag = 42; 
			6'd31:  dezigzag = 35; 
			6'd32:  dezigzag = 28; 
			6'd33:  dezigzag = 21; 
			6'd34:  dezigzag = 14; 
			6'd35:  dezigzag = 7; 
			6'd36:  dezigzag = 15; 
			6'd37:  dezigzag = 22; 
			6'd38:  dezigzag = 29; 
			6'd39:  dezigzag = 36; 
			6'd40:  dezigzag = 43; 
			6'd41:  dezigzag = 50; 
			6'd42:  dezigzag = 57; 
			6'd43:  dezigzag = 58; 
			6'd44:  dezigzag = 51; 
			6'd45:  dezigzag = 44; 
			6'd46:  dezigzag = 37; 
			6'd47:  dezigzag = 30; 
			6'd48:  dezigzag = 23; 
			6'd49:  dezigzag = 31; 
			6'd50:  dezigzag = 38; 
			6'd51:  dezigzag = 45; 
			6'd52:  dezigzag = 52; 
			6'd53:  dezigzag = 59; 
			6'd54:  dezigzag = 60; 
			6'd55:  dezigzag = 53; 
			6'd56:  dezigzag = 46; 
			6'd57:  dezigzag = 39; 
			6'd58:  dezigzag = 47; 
			6'd59:  dezigzag = 54; 
			6'd60:  dezigzag = 61; 
			6'd61:  dezigzag = 62; 
			6'd62:  dezigzag = 55; 
			6'd63:  dezigzag = 63;
			endcase	
		end
	endfunction
	
endmodule