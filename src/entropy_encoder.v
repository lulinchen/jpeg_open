// Copyright (c) 2018  LulinChen, All Rights Reserved
// AUTHOR : 	LulinChen
// AUTHOR'S EMAIL : lulinchen@aliyun.com 
// Release history
// VERSION Date AUTHOR DESCRIPTION

`include "jpeg_global.v"

module entropy_encoder(
	input								clk,
	input 								rstn,
	input								ee_go,

    output	reg  	[`W_AEEBUF_ID :0]	rid_ee_buf,
    output  		[`W_AEEBUF :0]  	aa_ee_buf,
    input 			[`W_DEEBUF:0] 		qa_ee_buf,
    output         						cena_ee_buf,
	
	output	reg							entropy_o_f,
	output	reg		[`W_VLCO:0]			entropy_o_bits,
	output	reg		[`W_VLCL:0]			entropy_o_bits_len,
	output	reg							ee_frame_ready,
		
	output	reg							ee_ready_for_next
	);
	
	wire							cena_coeff_buf;
    reg 	[`W_AEEBUF+3 :0]  		aa_coeff_buf;
    reg 	[11:0] 					qa_coeff_buf;
	reg		[ 5:0]					aa_coeff_buf_d1;
	always @(`CLK_RST_EDGE)
		if (`ZST)	aa_coeff_buf_d1 <= 0;
		else 		aa_coeff_buf_d1 <= aa_coeff_buf;
	assign	aa_ee_buf = aa_coeff_buf[`W_AEEBUF+3 :3]; 
	assign	cena_ee_buf = cena_coeff_buf; 
	always @(*) 
		qa_coeff_buf = qa_ee_buf[12*(8-aa_coeff_buf_d1[2:0])-1 -:12];	

	reg		[15:0]	ee_go_d;
	always @(*)	ee_go_d[0] = ee_go;
	always @(`CLK_RST_EDGE)
		if (`RST)	ee_go_d[15:1] <= 0;
		else 		ee_go_d[15:1] <= ee_go_d;
	// ee_go aa qa coeff_nz_i
	reg		[ 0:`CMP_IDX_MAX-1][63:0]	coeff_nz_i;
	always @(`CLK_RST_EDGE)
		if (`RST)						coeff_nz_i <= 0;
		else begin 
			for(int i=0; i<`CMP_IDX_MAX; i=i+1)
				if (ee_go_d[2+i]) 		coeff_nz_i[i] <= qa_ee_buf;
		end
	reg		last_mb_in_pic_rle;
	always @(`CLK_RST_EDGE)
		if (`RST)					last_mb_in_pic_rle <= 0;
		else if (ee_go_d[2]) 		last_mb_in_pic_rle <= qa_ee_buf[64];
	reg		last_mb_in_pic_huffman;
	always @(`CLK_RST_EDGE)
		if (`RST)					last_mb_in_pic_huffman <= 0;
		else if (ee_ready_for_next) last_mb_in_pic_huffman <= last_mb_in_pic_rle;

`ifdef SIMULATING		
	reg		[`W_PWInMbsM1:0]	MB_Col_rle;
	always @(`CLK_RST_EDGE)
		if (`RST)					MB_Col_rle <= 0;
		else if (ee_go_d[2]) 		MB_Col_rle <= qa_ee_buf[65 +: `W_PWInMbsM1+1];;
`endif		
	reg		[ 1:0]	cmp_rel_idx;
	reg				rle_go;
	wire			rle_end;
	
	wire	rle_go_b1 = ee_go_d[2] || rle_end && (cmp_rel_idx!=`CMP_IDX_MAX-1);
	wire	rle_ready = rle_end && (cmp_rel_idx==`CMP_IDX_MAX-1);
	
	reg		[15:0]	rle_ready_d;
	always @(*)	rle_ready_d[0] = rle_ready;
	always @(`CLK_RST_EDGE)
		if (`RST)	rle_ready_d[15:1] <= 0;
		else 		rle_ready_d[15:1] <= rle_ready_d;
	
	always @(*) ee_ready_for_next = rle_ready_d[1];
	
	always @(`CLK_RST_EDGE)
		if (`RST)						rid_ee_buf <= 0;
		else if (rle_ready_d[2])		rid_ee_buf <= rid_ee_buf + 1;
	
		//assign	ee_ready_for_next = rle_end && (cmp_rel_idx==`CMP_IDX_MAX-1);
	
	always @(`CLK_RST_EDGE)
		if (`RST)	rle_go <= 0;
		else 		rle_go <= rle_go_b1;
	always @(`CLK_RST_EDGE)
		if (`RST)						cmp_rel_idx <= `CMP_IDX_MAX-1;
		else if (rle_go_b1) 			cmp_rel_idx <= cmp_rel_idx == `CMP_IDX_MAX-1? 0: (cmp_rel_idx + 1);
	
	
	reg		[15:0]	rle_go_d;
	always @(*)	rle_go_d[0] = rle_go;
	always @(`CLK_RST_EDGE)
		if (`RST)	rle_go_d[15:1] <= 0;
		else 		rle_go_d[15:1] <= rle_go_d;
	reg		[15:0][1:0]	cmp_rel_idx_d;
	always @(*)	cmp_rel_idx_d[0] = cmp_rel_idx;
	always @(`CLK_RST_EDGE)
		if (`RST)	cmp_rel_idx_d[15:1] <= 0;
		else 		cmp_rel_idx_d[15:1] <= cmp_rel_idx_d;	
	
	reg				rle_e;
	reg		[ 6:0]	rle_cnt;
	reg		[ 0:62]	coeff_nz;	
	reg		[ 5:0]	runlength_trailing;	
	reg		[ 5:0]	runlength;	
	reg				runlength_valid;	
	
	reg		[ 6:0]		rle_cnt_d1;
	always @(`CLK_RST_EDGE)
		if (`ZST)	rle_cnt_d1 <= 0;
		else 		rle_cnt_d1 <= rle_cnt;
		
	reg		[ 0:62]	coeff_nz_d1;
	always @(`CLK_RST_EDGE)
		if (`ZST)	coeff_nz_d1 <= 0;
		else 		coeff_nz_d1 <= coeff_nz;
	reg				coeff_nz_zero;
	always @(`CLK_RST_EDGE)
		if (`ZST)	coeff_nz_zero <= 0;
		else 		coeff_nz_zero <= rle_e & (coeff_nz == 0);
	//reg				EOB;
	// assign		rle_end = rle_cnt>=63 && rle_e;
	assign		rle_end = (rle_cnt>=63 || coeff_nz_zero) && rle_e;
	wire		EOB = rle_end & !runlength_valid;
`ifdef SIMULATING
	wire 	xx = EOB &(rle_cnt==63);
`endif
	always @(`CLK_RST_EDGE)
		if (`RST)				rle_e <= 0;
		else if (rle_go)		rle_e <= 1;
		else if (rle_end)		rle_e <= 0;
		
	always @(`CLK_RST_EDGE)
		if (`RST)	begin
			coeff_nz <= 0;
			rle_cnt <= 0;
			runlength <= 0;
			runlength_valid <= 0;
			runlength_trailing <= 0;  		
		end else if (rle_go) begin
			coeff_nz  <= coeff_nz_i[cmp_rel_idx];
			rle_cnt <= 0;
			runlength <= 0;
			runlength_valid <= 1;
			runlength_trailing <= 0;
		end else if (rle_e) begin
			runlength <= 0;
			runlength_valid <= 0;
			runlength_trailing <= 0;
			//if (coeff_nz[0]) begin	coeff_nz  <= coeff_nz << 1; 
			for(int i=0; i<8; i=i+1)
				if (coeff_nz[i]) begin
					coeff_nz  <= coeff_nz << (i+1);
					rle_cnt <= rle_cnt + (i+1);
					runlength <= runlength_trailing +i;
					runlength_valid <= 1;
					break;
				end
			if (~|coeff_nz[0:7]) begin  // all zero
				runlength_trailing <=  runlength_trailing + 8;
				coeff_nz  <= coeff_nz << 8;
				rle_cnt <= rle_cnt + 8;
			end
		end else begin
			coeff_nz <= 0;
			rle_cnt <= 0;
			runlength <= 0;
			runlength_valid <= 0;
			runlength_trailing <= 0;  
		end
	
	reg		[15:0][5:0]	runlength_d;
	always @(*)	runlength_d[0] = runlength;
	always @(`CLK_RST_EDGE)
		if (`RST)	runlength_d[15:1] <= 0;
		else 		runlength_d[15:1] <= runlength_d;
	reg		[15:0]	runlength_valid_d;
	always @(*)	runlength_valid_d[0] = runlength_valid;
	always @(`CLK_RST_EDGE)
		if (`RST)	runlength_valid_d[15:1] <= 0;
		else 		runlength_valid_d[15:1] <= runlength_valid_d;
	
	reg		[15:0]	EOB_d;
	always @(*)	EOB_d[0] = EOB;
	always @(`CLK_RST_EDGE)
		if (`RST)	EOB_d[15:1] <= 0;
		else 		EOB_d[15:1] <= EOB_d;
		
	
	// runlength 16 eliminate
	reg		[5:0]	runlength_d1, runlength_d2, runlength_d3, runlength_d4, runlength_d5;
	reg				runlength_valid_d1, runlength_valid_d2, runlength_valid_d3, runlength_valid_d4, runlength_valid_d5;
	always @(`CLK_RST_EDGE)
		if (`RST)	{runlength_d1, runlength_d2, runlength_d3} <= 0;
		else 		{runlength_d1, runlength_d2, runlength_d3} <= {runlength, runlength_d1, runlength_d2};
	always @(`CLK_RST_EDGE)
		if (`RST)	{runlength_valid_d1, runlength_valid_d2, runlength_valid_d3, runlength_valid_d4} <= 0;
		else 		{runlength_valid_d1, runlength_valid_d2, runlength_valid_d3, runlength_valid_d4} <= {runlength_valid, runlength_valid_d1, runlength_valid_d2, runlength_valid_d3};

	always @(`CLK_RST_EDGE)
		if (`RST)							runlength_d4 <= 0;
		else 								runlength_d4 <= runlength_d3;

	reg		rl_gt48, rl_gt32, rl_gt16;
	always @(`CLK_RST_EDGE)
		if (`RST)		{rl_gt48, rl_gt32, rl_gt16} <= 0;
		else begin
			rl_gt48 <= runlength_valid    && runlength[5:4] == 2'b11;
			rl_gt32 <= runlength_valid_d1 && runlength_d1[5]   != 0;
			rl_gt16 <= runlength_valid_d2 && runlength_d2[5:4] != 0;
		end 
		
	always @(`CLK_RST_EDGE)
		if (`RST)				runlength_d5 <= 0;
		else if (rl_gt48)		runlength_d5 <= 4'hF;
		else if (rl_gt32)		runlength_d5 <= 4'hF;
		else if (rl_gt16)		runlength_d5 <= 4'hF;
		else 					runlength_d5 <= runlength_d4;
	always @(`CLK_RST_EDGE)
		if (`RST)				runlength_valid_d5 <= 0;
		else if (rl_gt48)		runlength_valid_d5 <= 1;
		else if (rl_gt32)		runlength_valid_d5 <= 1;
		else if (rl_gt16)		runlength_valid_d5 <= 1;
		else 					runlength_valid_d5 <= runlength_valid_d4;
	
	reg	[5:0]	aa_coeff_buf_b1;
	always @(`CLK_RST_EDGE)
		if (`RST)				aa_coeff_buf_b1 <= 0;
		else if (rle_cnt>63)	aa_coeff_buf_b1 <= 63;
		else 					aa_coeff_buf_b1 <= rle_cnt;
	always @(`CLK_RST_EDGE)
		if (`RST)				aa_coeff_buf <= 0;
		else if(ee_go) 			aa_coeff_buf <= `CMP_IDX_MAX*64;
		else if(ee_go_d[1]) 	aa_coeff_buf <= `CMP_IDX_MAX*64+8;
		else if(ee_go_d[2]) 	aa_coeff_buf <= `CMP_IDX_MAX*64+16;
`ifdef YUV422_ONLY
		else if(ee_go_d[3]) 	aa_coeff_buf <= `CMP_IDX_MAX*64+24;
`endif
		else					aa_coeff_buf <= dezigzag(aa_coeff_buf_b1) + 64 * cmp_rel_idx_d[2];
	assign	cena_coeff_buf = 1'b0;
	reg	signed	[`W_QUANTO:0]	   qa_coeff_buf_d1;

	reg	signed	[ 0:2][`W_QUANTO:0] prev_dc;
`ifdef YUV444_ONLY
	wire		[ 2:0]	cmp_idx_dc = cmp_rel_idx_d[5];
`elsif YUV422_ONLY
	reg			[ 2:0]	cmp_idx_dc;
	always @(*) begin
		case(cmp_rel_idx_d[5])
		0, 1 : cmp_idx_dc = 0;
		   2 : cmp_idx_dc = 1;
		   3 : cmp_idx_dc = 2;
		endcase
	end
`endif
	always @(`CLK_RST_EDGE)
		if (`RST)					prev_dc <= 0;
`ifdef YUV444_ONLY
		else if(rle_go_d[5])		prev_dc[cmp_idx_dc] <= last_mb_in_pic_rle? 0 : qa_coeff_buf_d1;
`elsif YUV422_ONLY
		else if(rle_go_d[5] )		prev_dc[cmp_idx_dc] <= last_mb_in_pic_rle&& cmp_rel_idx_d[5]!=0 ? 0 : qa_coeff_buf_d1;
`endif
	reg	signed	[`W_QUANTO+1:0]		qa_coeff_buf_d2;
	always @(`CLK_RST_EDGE)
		if (`ZST)			qa_coeff_buf_d1 <= 0;
		else 				qa_coeff_buf_d1 <= qa_coeff_buf;
		
	always @(`CLK_RST_EDGE)
		if (`ZST)				qa_coeff_buf_d2 <= 0;
		else if (rle_go_d[5])	qa_coeff_buf_d2 <= $signed(qa_coeff_buf_d1) - $signed(prev_dc[cmp_idx_dc]);
		else 					qa_coeff_buf_d2 <= $signed(qa_coeff_buf_d1);
		
	reg		[ 3:0]	rle_size;
	reg		[ 3:0]	rle_runlength;
	reg		[11:0]	rle_amplitude;
	reg				rle_valid;
	reg				rle_DC_valid;
	always @(`CLK_RST_EDGE)
		if (`RST)	rle_size <= 0;
		else 		rle_size <= VLI_size(qa_coeff_buf_d2);	
	
	always @(`CLK_RST_EDGE)
		if (`RST)	rle_runlength <= 0;
	//	else 		rle_runlength <= EOB_d[5]? 0 : runlength_d[5];
		else 		rle_runlength <= EOB_d[5]? 0 : runlength_d5;
	always @(`CLK_RST_EDGE)
		if (`RST)	rle_amplitude <= 0;
		else 		rle_amplitude <= $signed(qa_coeff_buf_d2) < 0? qa_coeff_buf_d2 - 1 : qa_coeff_buf_d2;
	always @(`CLK_RST_EDGE)
		if (`RST)	rle_valid <= 0;
	//	else 		rle_valid <= runlength_valid_d[5] | EOB_d[5];
		else 		rle_valid <= runlength_valid_d5 | EOB_d[5];
	always @(`CLK_RST_EDGE)
		if (`RST)	rle_DC_valid <= 0;
		else 		rle_DC_valid <= rle_go_d[6];
	
	
	//========================================================
	// huffman
	
	reg		[15:0]	rle_DC_valid_d;
	always @(*)	rle_DC_valid_d[0] = rle_DC_valid;
	always @(`CLK_RST_EDGE)
		if (`RST)	rle_DC_valid_d[15:1] <= 0;
		else 		rle_DC_valid_d[15:1] <= rle_DC_valid_d;
	reg		[15:0]	rle_valid_d;
	always @(*)	rle_valid_d[0] = rle_valid;
	always @(`CLK_RST_EDGE)
		if (`RST)	rle_valid_d[15:1] <= 0;
		else 		rle_valid_d[15:1] <= rle_valid_d;
	reg		[15:0][3:0]	rle_size_d;
	always @(*)	rle_size_d[0] = rle_size;
	always @(`CLK_RST_EDGE)
		if (`RST)	rle_size_d[15:1] <= 0;
		else 		rle_size_d[15:1] <= rle_size_d;
	reg		[15:0][11:0]	rle_amplitude_d;
	always @(*)	rle_amplitude_d[0] = rle_amplitude;
	always @(`CLK_RST_EDGE)
		if (`RST)	rle_amplitude_d[15:1] <= 0;
		else 		rle_amplitude_d[15:1] <= rle_amplitude_d;
		

	wire	[ 3:0]	rle_size_d2 = rle_size_d[2];
	
	wire [ 3:0]       	VLC_DC_size;
    wire [10:0]       	VLC_DC;
    wire [ 4:0]       	VLC_AC_size;
    wire [15:0]       	VLC_AC;
	
	wire [ 3:0]       	VLC_CR_DC_size;
    wire [10:0]       	VLC_CR_DC;
    wire [ 4:0]       	VLC_CR_AC_size;
    wire [15:0]      	VLC_CR_AC;


	dc_luma_rom dc_luma_rom(.clk(clk), .VLI_size(rle_size), .VLC_DC_size(VLC_DC_size), .VLC_DC(VLC_DC));
	ac_luma_rom ac_luma_rom(.clk(clk), .runlength(rle_runlength), .VLI_size(rle_size), .VLC_AC_size(VLC_AC_size), .VLC_AC(VLC_AC));

	dc_chroma_rom dc_chroma_rom(.clk(clk), .VLI_size(rle_size), .VLC_DC_size(VLC_CR_DC_size), .VLC_DC(VLC_CR_DC));
    ac_chroma_rom ac_chroma_rom(.clk(clk), .runlength(rle_runlength), .VLI_size(rle_size), .VLC_AC_size(VLC_CR_AC_size), .VLC_AC(VLC_CR_AC));

	
	reg 	[ 4:0]	VLC_size;
	reg 	[15:0]  VLC;
	wire	[ 1:0]	cmp_rel_idx_d7 = cmp_rel_idx_d[7];
	always @(`CLK_RST_EDGE)
		if (`RST)	{VLC_size, VLC} <= 0;
		else begin
`ifdef YUV444_ONLY
			if (cmp_rel_idx_d[7]==0) begin
`elsif YUV422_ONLY
			if (cmp_rel_idx_d[7][1]==0) begin
`endif
				VLC_size <= rle_DC_valid_d[1]? VLC_DC_size : VLC_AC_size;
				VLC	     <= rle_DC_valid_d[1]? VLC_DC : VLC_AC;
			end else begin
				VLC_size <= rle_DC_valid_d[1]? VLC_CR_DC_size : VLC_CR_AC_size;
				VLC	     <= rle_DC_valid_d[1]? VLC_CR_DC : VLC_CR_AC;
			end
		end
	
	// can no in rom
	wire	[`W_VLCO:0]	VLC_shift  =  {16'b0, VLC} << rle_size_d[2]; 
		// wire	[11:0]	rle_amplitude_d2 = rle_amplitude_d[2];
	wire	[`W_VLCO:0]	rle_amplitude_d2 = ( rle_amplitude_d[2] &~ (32'hffff << rle_size_d[2]));
	
	always @(`CLK_RST_EDGE)
		if (`RST)	entropy_o_bits <= 0;
	//	else 		entropy_o_bits <= VLC_shift | ( rle_amplitude_d[2] &~ (32'hffff << rle_size_d[2]));
		else 		entropy_o_bits <= VLC_shift | rle_amplitude_d2;
	always @(`CLK_RST_EDGE)
		if (`RST)	entropy_o_bits_len <= 0;
		else 		entropy_o_bits_len <= rle_size_d[2] +  VLC_size;
	always @(`CLK_RST_EDGE)
		if (`RST)	entropy_o_f <= 0;
		else 		entropy_o_f <= rle_valid_d[2] | rle_DC_valid_d[2];
	
	always @(`CLK_RST_EDGE)
		if (`RST)	ee_frame_ready <= 0;
		else 		ee_frame_ready <= rle_ready_d[9] & last_mb_in_pic_huffman;
	
	
	
	
	// use a case
	function [3:0]	VLI_size( input signed	[`W_QUANTO+1:0] coeff	);
		reg [`W_QUANTO+1:0]	 coeff_abs;
		begin
			coeff_abs = $signed(coeff) < 0?  (~coeff + 1'b1) : coeff;
			for(int i = `W_QUANTO;  i > 0; i--)
				if (coeff_abs[i-1]) begin
					VLI_size = i;
					return VLI_size;
				end
			VLI_size = 0;
			return VLI_size;
		end
	endfunction
	
	// function [3:0]	VLI_size( input signed	[`W_QUANTO+1:0] acc_reg	);
		// begin
			// if (acc_reg == -1) 
                // VLI_size = 1;
            // else if (acc_reg < -1 & acc_reg > -4 )
                // VLI_size = 2;
            // else if (acc_reg < -3 & acc_reg > -8 ) 
                // VLI_size = 3;
            // else if (acc_reg < -7 & acc_reg > -16 ) 
                // VLI_size = 4;
            // else if (acc_reg < -15 & acc_reg > -32 ) 
                // VLI_size = 5;
            // else if (acc_reg < -31 & acc_reg > -64 ) 
                // VLI_size = 6;
            // else if (acc_reg < -63 & acc_reg > -128 ) 
                // VLI_size = 7;
            // else if (acc_reg < -127 & acc_reg > -256 ) 
                // VLI_size = 8;
            // else if (acc_reg < -255 & acc_reg > -1024 ) 
                // VLI_size = 9;
            // else if (acc_reg < -511 & acc_reg > -2048 ) 
                // VLI_size = 10;
            // else if (acc_reg < -1023 & acc_reg > 1 ) 
                // VLI_size = 11;
            // else if (acc_reg == 1) 
                // VLI_size = 1;
            // else if (acc_reg > 1 & acc_reg < 4 )  
                // VLI_size = 2;
            // else if (acc_reg > 3 & acc_reg < 8 )  
                // VLI_size = 3;
            // else if (acc_reg > 7 & acc_reg < 16 )  
                // VLI_size = 4;
            // else if (acc_reg > 15 & acc_reg < 32 )  
                // VLI_size = 5;
            // else if (acc_reg > 31 & acc_reg < 64 )  
                // VLI_size = 6;
            // else if (acc_reg > 63 & acc_reg < 128 )  
                // VLI_size = 7;
            // else if (acc_reg > 127 & acc_reg < 256 )  
                // VLI_size = 8;
            // else if (acc_reg > 255 & acc_reg < 512 )  
                // VLI_size = 9;
            // else if (acc_reg > 511 & acc_reg < 1024 )  
                // VLI_size = 10;
            // else if (acc_reg > 1023 & acc_reg < 2048 )  
                // VLI_size = 11;
            // else if (acc_reg == 0)
                // VLI_size = 0;
		// end
	// endfunction
	function [ 5:0]	dezigzag( input	[ 5:0] zigzaged	);
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
	// function [5:0]	dezigzag( input	[5:0] zigzaged	);
		// begin
			// case (zigzaged)
			// 6'd0 :  dezigzag = 0 ;
			// 6'd1 :  dezigzag = 1 ;
			// 6'd2 :  dezigzag = 8 ;
			// 6'd3 :  dezigzag = 16; 
			// 6'd4 :  dezigzag = 9 ;
			// 6'd5 :  dezigzag = 2 ;
			// 6'd6 :  dezigzag = 3 ;
			// 6'd7 :  dezigzag = 10; 
			// 6'd8 :  dezigzag = 17; 
			// 6'd9 :  dezigzag = 24; 
			// 6'd10:  dezigzag = 32; 
			// 6'd11:  dezigzag = 25; 
			// 6'd12:  dezigzag = 18; 
			// 6'd13:  dezigzag = 11; 
			// 6'd14:  dezigzag = 4 ;
			// 6'd15:  dezigzag = 5 ;
			// 6'd16:  dezigzag = 12; 
			// 6'd17:  dezigzag = 19; 
			// 6'd18:  dezigzag = 26; 
			// 6'd19:  dezigzag = 33; 
			// 6'd20:  dezigzag = 40; 
			// 6'd21:  dezigzag = 48; 
			// 6'd22:  dezigzag = 41; 
			// 6'd23:  dezigzag = 34; 
			// 6'd24:  dezigzag = 27; 
			// 6'd25:  dezigzag = 20; 
			// 6'd26:  dezigzag = 13; 
			// 6'd27:  dezigzag = 6 ;
			// 6'd28:  dezigzag = 7 ;
			// 6'd29:  dezigzag = 14; 
			// 6'd30:  dezigzag = 21; 
			// 6'd31:  dezigzag = 28; 
			// 6'd32:  dezigzag = 35; 
			// 6'd33:  dezigzag = 42; 
			// 6'd34:  dezigzag = 49; 
			// 6'd35:  dezigzag = 56; 
			// 6'd36:  dezigzag = 57; 
			// 6'd37:  dezigzag = 50; 
			// 6'd38:  dezigzag = 43; 
			// 6'd39:  dezigzag = 36; 
			// 6'd40:  dezigzag = 29; 
			// 6'd41:  dezigzag = 22; 
			// 6'd42:  dezigzag = 15; 
			// 6'd43:  dezigzag = 23; 
			// 6'd44:  dezigzag = 30; 
			// 6'd45:  dezigzag = 37; 
			// 6'd46:  dezigzag = 44; 
			// 6'd47:  dezigzag = 51; 
			// 6'd48:  dezigzag = 58; 
			// 6'd49:  dezigzag = 59; 
			// 6'd50:  dezigzag = 52; 
			// 6'd51:  dezigzag = 45; 
			// 6'd52:  dezigzag = 38; 
			// 6'd53:  dezigzag = 31; 
			// 6'd54:  dezigzag = 39; 
			// 6'd55:  dezigzag = 46; 
			// 6'd56:  dezigzag = 53; 
			// 6'd57:  dezigzag = 60; 
			// 6'd58:  dezigzag = 61; 
			// 6'd59:  dezigzag = 54; 
			// 6'd60:  dezigzag = 47; 
			// 6'd61:  dezigzag = 55; 
			// 6'd62:  dezigzag = 62; 
			// 6'd63:  dezigzag = 63;
			// endcase	
		// end
	// endfunction

endmodule