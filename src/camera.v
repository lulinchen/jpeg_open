// Copyright (c) 2018  LulinChen, All Rights Reserved
// AUTHOR : 	LulinChen
// AUTHOR'S EMAIL : lulinchen@aliyun.com 
// Release history
// VERSION Date AUTHOR DESCRIPTION

`include "jpeg_global.v"

module camera(
	input						clk, 
	input						rstn,
	input						cam_clk,
	input						rstn_cam,
	
	input						encoder_active,	
	
	input						cam_vsync_i,
	input						cam_href_i,
	input		[`W_CAMD_I:0]	cam_data_i,			
	input     	[`W_PW:0]  		PicWidth_i,	
    input     	[`W_PH:0]  		PicHeight_i,	
	output reg 					cam_pic_start_f,
	output reg 					camfifo_o_f,
	output reg 					cenb_cam,
	output reg 	[`W_WCAMBUF:0]	wenb_cam,		
	output reg 	[`W_ACAMBUF:0]  ab_cam,
	output reg 	[`W8:0]	  		db_cam
	);
	
	reg							cam_vsync;
	reg							cam_vsync_p1;
	wire	cam_vsync_rising  = {cam_vsync_p1, cam_vsync } == 2'b01;
	wire	cam_vsync_falling = {cam_vsync_p1, cam_vsync } == 2'b10;
	
	reg							cam_href;
	reg			[`W_CAMD_I:0]	cam_data;			
	reg							cam_href_p1;
	
	wire	_cam_href_rising  = {cam_href    , cam_href_i} == 2'b01;
	wire	cam_href_falling  = {cam_href_p1 , cam_href  } == 2'b10;
	
	always @(posedge cam_clk `RST_EDGE_CAM)
		if (`ZST_CAM) begin
			cam_href <= 0;
			cam_vsync <= 0;
			cam_data <= 0;
		end else begin
			cam_href <= cam_href_i;
			cam_vsync <= cam_vsync_i;
			cam_data <= cam_data_i;
		end
	always @(posedge cam_clk `RST_EDGE_CAM)
		if (`ZST_CAM) begin
			cam_vsync_p1 <= 0;
			cam_href_p1	<= 0;
		end else begin
			cam_vsync_p1 <= cam_vsync;
			cam_href_p1	<= cam_href;
		end
	
	reg							encoder_active_meta;
	reg							encoder_active_cam;
	reg							encoder_working;
	reg  						cam_vsync_working;
	
	always @(posedge cam_clk `RST_EDGE_CAM)
		if (`ZST_CAM) begin
			encoder_active_meta <= 0;
			encoder_active_cam <= 0;
		end else begin
			encoder_active_meta <= encoder_active;		
			encoder_active_cam <= encoder_active_meta;
		end

	always @(posedge cam_clk `RST_EDGE_CAM)
		if (`RST_CAM) encoder_working <= 0;
		else 
`ifdef SIMULATING								
			if (cam_vsync_falling) begin		
`else			
			if (cam_vsync_rising) begin			
`endif			
				encoder_working <= (encoder_active_cam);
			end	

    always @(posedge cam_clk `RST_EDGE_CAM)
        if (`RST_CAM) cam_vsync_working <= 1;		
        else          cam_vsync_working <= encoder_working ? cam_vsync : 1'b1;

	wire 	cam_pix_valid = (!cam_vsync_working & cam_href);
	
	parameter  W_CAMD  = 4*(`W_CAMD_I+1) - 1;
	parameter  W_ACAMD = 4;
`ifdef YUV444_ONLY
	`define CAM_D_FIFO  rfdp32x96
`else
	`define CAM_D_FIFO  rfdp32x64
`endif
	
	reg				[  1:0]		cam_pix_vparity;
	reg							cam_pix_vparity_p1;
    reg				[3:0][`W_CAMD_I:0]	db_cam_d;
    reg							cena_cam_d;
    reg							cenb_cam_d;
	reg             [W_ACAMD:0] aa_cam_d;
    wire            [W_CAMD :0] qa_cam_d;
    reg             [W_ACAMD:0] ab_cam_d;	
	wire			 [W_CAMD :0] _db_cam_d = db_cam_d;
	always @(posedge cam_clk `RST_EDGE_CAM)
		if (`RST_CAM) cenb_cam_d <= 1;
		else          cenb_cam_d <= ~(cam_pix_vparity == 3);
	
	always @(posedge cam_clk `RST_EDGE_CAM)
		if (`ZST_CAM)		db_cam_d[cam_pix_vparity] <= 0;
		else 				db_cam_d[cam_pix_vparity] <= cam_data;
	always @(posedge cam_clk `RST_EDGE_CAM)
		if (`RST_CAM)				cam_pix_vparity <= 0;
		else if (cam_pix_valid)		cam_pix_vparity <= cam_pix_vparity + 1;
		else						cam_pix_vparity <= 0;
	always @(posedge cam_clk `RST_EDGE_CAM)
		if (`RST_CAM) cam_pix_vparity_p1 <= 0;
		else          cam_pix_vparity_p1 <= (cam_pix_vparity == 3) & cam_pix_valid;

	`CAM_D_FIFO fifo_cam_d (
        .CLKA   (clk),
        .CENA   (cena_cam_d),
        .AA     (aa_cam_d),
        .QA     (qa_cam_d),
        .CLKB   (cam_clk),
        .CENB   (cenb_cam_d),
        .AB     (ab_cam_d),
        .DB     (db_cam_d));

	always @(posedge cam_clk `RST_EDGE_CAM)
		if (`RST_CAM)					ab_cam_d <= 0;
		else if (cam_pix_vparity_p1)	ab_cam_d <= ab_cam_d + 1;
	
	reg		cam_i_flip;
	always @(posedge cam_clk `RST_EDGE_CAM)
		if (`RST_CAM)					cam_i_flip <= 0;
		else if (cam_pix_vparity_p1)	cam_i_flip <= ~cam_i_flip;	
		
	//#########################################################################################################
	//#########################################################################################################
		
	reg							vsync_meta;
	reg							href_meta;
	reg							vsync;
	reg							href;

	reg							cam_i_flip_meta;
	reg 						cam_i_flip_c;
	reg							cam_i_flip_c_p1;

	always @(`CLK_RST_EDGE)
		if (`ZST) begin
			vsync_meta <= 0;
			href_meta <= 0;
			cam_i_flip_meta <= 0;
		end else begin
			vsync_meta <= cam_vsync_working;								// crossing domain
			href_meta <= 	cam_href_p1;	// crossing domain
			cam_i_flip_meta <= cam_i_flip;									// crossing domain
		end
	always @(`CLK_RST_EDGE)
		if (`ZST) begin
			vsync <= 0;
			href <= 0;
			cam_i_flip_c <= 0;
			cam_i_flip_c_p1 <= 0;
		end else begin
			vsync <= vsync_meta;
			href <= href_meta;
			cam_i_flip_c <= cam_i_flip_meta;
			cam_i_flip_c_p1 <= cam_i_flip_c;
		end

	reg							vsync_p1;
	reg							href_p1;
    reg    						href_rising;
    reg    						vsync_falling;
//	wire	href_falling  = {href_p1,  href } == 2'b10;
//	wire	vsync_rising  = {vsync_p1, vsync} == 2'b01;
	
	always @(`CLK_RST_EDGE)
		if (`ZST) begin
			vsync_p1 <= 0;
			href_p1	<= 0;
		end else begin
			vsync_p1 <= vsync;
			href_p1	<= href;
		end
    always @(`CLK_RST_EDGE)
        if (`ZST) href_rising <= 0;
        else      href_rising <= {href_p1,  href } == 2'b01;
    always @(`CLK_RST_EDGE)
        if (`ZST) vsync_falling <= 0;
        else      vsync_falling <= {vsync_p1, vsync} == 2'b10;

	reg							line_begin;
	reg							line_begin_p1;
	reg							line_end;
	reg				[`W_PH:0]	cnt_line;
 	reg				[3:0]		cnt_line_p1;
	reg							pix_valid;
	reg							pix_valid_p1, pix_valid_p2, pix_valid_p3;
	reg							line_end_p1, line_end_p2, line_end_p3, line_end_p4, line_end_p5, line_end_p6, line_end_p7, line_end_p8, line_end_p9;
	
	reg							fifo_rd_b2;
	reg							fifo_rd_b1;
	reg							fifo_rd;
	reg							fifo_rd_p1, fifo_rd_p2;
	
	always @(`CLK_RST_EDGE)
		if (`ZST) {line_end_p1, line_end_p2, line_end_p3, line_end_p4, line_end_p5, line_end_p6, line_end_p7, line_end_p8, line_end_p9} <= 0;
		else      {line_end_p1, line_end_p2, line_end_p3, line_end_p4, line_end_p5, line_end_p6, line_end_p7, line_end_p8, line_end_p9} <= {line_end, line_end_p1, line_end_p2, line_end_p3, line_end_p4, line_end_p5, line_end_p6, line_end_p7, line_end_p8};
	
	reg		vsync_falled; 
	always @(`CLK_RST_EDGE)
		if (`RST)					vsync_falled <= 0;
		else if (vsync_falling)		vsync_falled <= 1;
		else if (line_begin)		vsync_falled <= 0;
	always @(`CLK_RST_EDGE)
		if (`ZST) begin
			cam_pic_start_f <= 0;
			pix_valid <= 0;
		end else begin
			// cam_pic_start_f <= vsync_falling;
			cam_pic_start_f <= vsync_falled & line_begin;
			pix_valid <= (!vsync & href);
		end
	
	always @(`CLK_RST_EDGE)
		if (`ZST) {pix_valid_p1, pix_valid_p2, pix_valid_p3} <= 0;
		else      {pix_valid_p1, pix_valid_p2, pix_valid_p3} <= {pix_valid, pix_valid_p1, pix_valid_p2};			
	always @(`CLK_RST_EDGE)
		if (`ZST) begin
			line_begin	<= 0;
			line_begin_p1 <= 0;
		end else begin
			line_begin <= ({pix_valid, pix_valid_p1} == 2'b10);
			line_begin_p1 <= line_begin;
		end	
	always @(`CLK_RST_EDGE)
		if (`ZST) line_end	<= 0;
		else      line_end <= ({pix_valid_p2, pix_valid_p3} == 2'b01);
		
	always @(`CLK_RST_EDGE)
		if (`RST)				cnt_line <= 0;
		else if (vsync)			cnt_line <= 0;
		else if (line_end_p9)	cnt_line <= cnt_line + 1;
	reg     	[`W_PH:0]  		PicHeight_minus1;
	
	
	always @(`CLK_RST_EDGE)
		if (`RST)		PicHeight_minus1 <= 0;
		else 			PicHeight_minus1 <= PicHeight_i -1;
	always @(`CLK_RST_EDGE)
		if (`RST) camfifo_o_f <= 0;
		else      camfifo_o_f <= (line_end_p6 && ( cnt_line[2:0] == 7 || cnt_line==PicHeight_minus1));
		
	
	//#########################################################################################################
	//#########################################################################################################
	
	wire						_new_cam_data_f = (cam_i_flip_c_p1 != cam_i_flip_c);
	always @(`CLK_RST_EDGE)
		if (`ZST) 	fifo_rd <= 0;
		else      	fifo_rd <= fifo_rd_b1;
	always @(`CLK_RST_EDGE)
		if (`ZST) begin
			fifo_rd_b2 <= 0;
			fifo_rd_b1 <= 0;
		end else begin
			fifo_rd_b2 <= _new_cam_data_f;
			fifo_rd_b1 <= fifo_rd_b2;
		end	
	reg		[7:0]	fifo_rd_d;
	always @(*)	fifo_rd_d[0] = fifo_rd;
	always @(`CLK_RST_EDGE)
		if (`RST)	fifo_rd_d[7:1] <= 0;
		else 		fifo_rd_d[7:1] <= fifo_rd_d;	
	
	always @(`CLK_RST_EDGE)
		if (`RST) 	cena_cam_d <= 1;
		else      	cena_cam_d <= ~fifo_rd_b2;
	always @(`CLK_RST_EDGE)
		if (`RST)					aa_cam_d <= 0;
		else if (cam_pic_start_f)	aa_cam_d <= ab_cam_d; 
		else if (fifo_rd_b1)		aa_cam_d <= aa_cam_d + 1;
	
	reg		[W_CAMD:0]		qa_cam_d_d1;
	always @(`CLK_RST_EDGE)
		if (`ZST)	qa_cam_d_d1 <= 0;
		else 		qa_cam_d_d1 <= qa_cam_d;	
	
	// 	fifo_rd_b2
	// 				cena
	// 				aa		qa	qa_d1	
	//							cnt     cam_data_yuv	
	//									flush_y
	reg		[1:0] 	cnt_data;
	reg				flush_y;
	reg		[7:0]	flush_y_d;
	always @(*)	flush_y_d[0] = flush_y;
	always @(`CLK_RST_EDGE)
		if (`RST)	flush_y_d[7:1] <= 0;
		else 		flush_y_d[7:1] <= flush_y_d;	
	
	always @(`CLK_RST_EDGE)
		if (`RST)					cnt_data <= 0;
		else if (fifo_rd_d[1])		cnt_data <= cnt_data + 1;
	`ifdef YUV444_ONLY	
		reg		[0:7][`W1:0]	cam_data_y, cam_data_u, cam_data_v;
		always @(`CLK_RST_EDGE)
			if (`ZST) 	{cam_data_y, cam_data_u, cam_data_v} <= 0;
			else if (fifo_rd_d[1]) begin
				case(cnt_data[0])
				0:	{cam_data_v[3], cam_data_u[3], cam_data_y[3], cam_data_v[2], cam_data_u[2], cam_data_y[2], cam_data_v[1], cam_data_u[1], cam_data_y[1], cam_data_v[0], cam_data_u[0], cam_data_y[0]} <= qa_cam_d_d1;
				1:  {cam_data_v[7], cam_data_u[7], cam_data_y[7], cam_data_v[6], cam_data_u[6], cam_data_y[6], cam_data_v[5], cam_data_u[5], cam_data_y[5], cam_data_v[4], cam_data_u[4], cam_data_y[4]} <= qa_cam_d_d1;
				endcase
			end
		always @(`CLK_RST_EDGE)
			if (`RST) flush_y <= 0;
			else      flush_y <= fifo_rd_d[1] & cnt_data[0];
		
		reg			[`W_ACAMBUF:0]	y_addr, u_addr, v_addr;
		reg		[7:0][`W_ACAMBUF:0]	y_addr_d;
		always @(*)	y_addr_d[0] = y_addr;
		always @(`CLK_RST_EDGE)
			if (`RST)	y_addr_d[7:1] <= 0;
			else 		y_addr_d[7:1] <= y_addr_d;
		always @(`CLK_RST_EDGE)
			if (`RST) cenb_cam <= 1;
			else      cenb_cam <= ~(flush_y | flush_y_d[1] | flush_y_d[2]);
		always @(`CLK_RST_EDGE)
			if (`RST)				ab_cam <= 0;
			else if (flush_y) 		ab_cam <= y_addr;
			else if (flush_y_d[1])	ab_cam <= u_addr;
			else if (flush_y_d[2])	ab_cam <= v_addr;
		always @(`CLK_RST_EDGE)
			if (`RST)				db_cam <= 0;
			else if (flush_y) 		db_cam <= cam_data_y;
			else if (flush_y_d[1])	db_cam <= cam_data_u;
			else if (flush_y_d[2])	db_cam <= cam_data_v;
			
		parameter Y_ADDR_INIT = 0;	
		parameter U_ADDR_INIT = (`LUMA_LINE_WORDS   *  16);	
	`ifdef YUV444_ONLY
		parameter V_ADDR_INIT = (`LUMA_LINE_WORDS   *  32);	
	`elsif YUV422_ONLY
		parameter V_ADDR_INIT = (`LUMA_LINE_WORDS   *  (16+8));	
	`endif
		always @(`CLK_RST_EDGE)
			if (`RST) 					y_addr <= Y_ADDR_INIT;
			else if (flush_y_d[1]) 		y_addr <= y_addr + 1;
			else if (line_begin_p1)		y_addr <= `LUMA_LINE_WORDS * cnt_line[3:0];
		always @(`CLK_RST_EDGE)
			if (`RST) 					u_addr <= U_ADDR_INIT;
			else 						u_addr <= U_ADDR_INIT + y_addr;
		always @(`CLK_RST_EDGE)
			if (`RST) 					v_addr <= V_ADDR_INIT;
			else						v_addr <= V_ADDR_INIT + y_addr;
	`elsif YUV422_ONLY
		reg		[0:7][`W1:0]	cam_data_y, cam_data_u, cam_data_v;
		always @(`CLK_RST_EDGE)
			if (`ZST) 	{cam_data_y, cam_data_u, cam_data_v} <= 0;
			else if (fifo_rd_d[1]) begin
				case(cnt_data[1:0])
				0:	{cam_data_v[1], cam_data_y[3], cam_data_u[1], cam_data_y[2], cam_data_v[0], cam_data_y[1], cam_data_u[0], cam_data_y[0]} <= qa_cam_d_d1;
				1:	{cam_data_v[3], cam_data_y[7], cam_data_u[3], cam_data_y[6], cam_data_v[2], cam_data_y[5], cam_data_u[2], cam_data_y[4]} <= qa_cam_d_d1;
				2:	{cam_data_v[5], cam_data_y[3], cam_data_u[5], cam_data_y[2], cam_data_v[4], cam_data_y[1], cam_data_u[4], cam_data_y[0]} <= qa_cam_d_d1;
				3:	{cam_data_v[7], cam_data_y[7], cam_data_u[7], cam_data_y[6], cam_data_v[6], cam_data_y[5], cam_data_u[6], cam_data_y[4]} <= qa_cam_d_d1;
				endcase
			end
		reg		[7:0][2:0]	cnt_data_d;
		always @(*)	cnt_data_d[0] = cnt_data;
		always @(`CLK_RST_EDGE)
			if (`RST)	cnt_data_d[7:1] <= 0;
			else 		cnt_data_d[7:1] <= cnt_data_d;
		
		reg		flush_u, flush_v;
		always @(`CLK_RST_EDGE)
			if (`RST)	flush_y <= 0;
			else      	flush_y <= fifo_rd_d[1] & cnt_data[0];		
		always @(`CLK_RST_EDGE)
			if (`RST) 	flush_u <= 0;
			else 		flush_u <= flush_y && cnt_data_d[1]==3;
		//TODO  seperate flush_u and flush_v  can reduce the main clk req
		always @(`CLK_RST_EDGE)
			if (`RST) 	flush_v <= 0;	
			else 		flush_v <= flush_u;
		reg			[`W_ACAMBUF:0]	y_addr, u_addr, v_addr;	
		always @(`CLK_RST_EDGE)
			if (`RST) cenb_cam <= 1;
			else      cenb_cam <= ~(flush_y | flush_u | flush_v);
		always @(`CLK_RST_EDGE)
			if (`RST)				ab_cam <= 0;
			else if (flush_y) 		ab_cam <= y_addr;
			else if (flush_u)		ab_cam <= u_addr;
			else if (flush_v)		ab_cam <= v_addr;
		always @(`CLK_RST_EDGE)
			if (`RST)				db_cam <= 0;
			else if (flush_y) 		db_cam <= cam_data_y;
			else if (flush_u)		db_cam <= cam_data_u;
			else if (flush_v)		db_cam <= cam_data_v;	
			
			
		parameter Y_ADDR_INIT = 0;	
		parameter U_ADDR_INIT = (`LUMA_LINE_WORDS   *  16);	
		parameter V_ADDR_INIT = (`LUMA_LINE_WORDS   *  (16+8));	
		always @(`CLK_RST_EDGE)
			if (`RST) 					y_addr <= Y_ADDR_INIT;
			else if (flush_y_d[1]) 		y_addr <= y_addr + 1;
			else if (line_begin_p1)		y_addr <= `LUMA_LINE_WORDS * cnt_line[3:0];
		always @(`CLK_RST_EDGE)
			if (`RST) 					u_addr <= U_ADDR_INIT;
			else 						u_addr <= U_ADDR_INIT + (y_addr>>1);
		always @(`CLK_RST_EDGE)
			if (`RST) 					v_addr <= V_ADDR_INIT;
			else						v_addr <= V_ADDR_INIT + (y_addr>>1);
	`endif
		
	
endmodule