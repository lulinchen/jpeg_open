// Copyright (c) 2018  LulinChen, All Rights Reserved
// AUTHOR : 	LulinChen
// AUTHOR'S EMAIL : lulinchen@aliyun.com 
// Release history
// VERSION Date AUTHOR DESCRIPTION
`include "jpeg_global.v"
module jpeg_enc(
	input 					 		clk,
	input 					 		rstn,
	input							encoder_active,	
	
	input							ee_clk,
	input							rstn_ee,
	
	input							cam_clk,
	input							rstn_cam,
	
	input							cam_vsync_i,
	input							cam_href_i,
	input		[`W_CAMD_I:0]		cam_data_i,	
	input     	[`W_PW:0]  			PicWidth_i,	
    input     	[`W_PH:0]  			PicHeight_i,	
	
	output reg 	                    data_valid,
    output reg 	       [ 7:0]       data_out, 	
	output reg						pic_ready,
	output reg						err_sensor_too_fast,
	output reg						err_eefifo_overflow
	);
	

	wire	[`W_ACAMBUF:0]	ab_camera_buf;
	wire	[`W8:0]			db_camera_buf;
	wire					cenb_camera_buf;
	reg		[`W_ACAMBUF:0]	aa_camera_buf;
	reg						cena_camera_buf;
	wire	[`W8:0]			qa_camera_buf;
`ifdef YUV444_ONLY
	rfdp12288x64 camera_buf(
`elsif YUV422_ONLY    // 16xluma  16xchroma
	rfdp8192x64 camera_buf(  
`endif
		.CLKA   (clk),
		.CENA   (cena_camera_buf),
		.AA     (aa_camera_buf),
		.QA     (qa_camera_buf),
		.CLKB   (clk),
		.CENB   (cenb_camera_buf),
		.AB     (ab_camera_buf),
		.DB     (db_camera_buf)
		);
		
	camera camera(
		.clk				(clk), 
		.rstn				(rstn),
		.cam_clk			(cam_clk),
		.rstn_cam			(rstn_cam),
		.encoder_active		(encoder_active),	
		.cam_vsync_i		(cam_vsync_i),
		.cam_href_i			(cam_href_i),
		.cam_data_i			(cam_data_i),			
		.PicWidth_i			(PicWidth_i),	
		.PicHeight_i		(PicHeight_i),		
		.cam_pic_start_f	(cam_pic_start_f),
		.camfifo_o_f		(camfifo_o_f),
		.cenb_cam			(cenb_camera_buf),
		.wenb_cam			(),		
		.ab_cam				(ab_camera_buf),
		.db_cam             (db_camera_buf)

		);

	reg     [`W_PWInMbs:0]  PicWidthInMbs;
    reg     [`W_PHInMbs:0]  PicHeightInMbs;

	always @(`CLK_RST_EDGE)
		if (`RST)	{PicWidthInMbs, PicHeightInMbs }  <= 0;
		else begin
`ifdef YUV444_ONLY
			PicWidthInMbs <= PicWidth_i>>3;
`elsif YUV422_ONLY
			PicWidthInMbs <= PicWidth_i>>4;
`endif
			PicHeightInMbs <= PicHeight_i>>3;
		end

	
	reg		[`W_PWInMbs:0]		MB_semaphore;
	reg		[`W_PWInMbsM1:0]	MB_Col;
	reg		[`W_PHInMbsM1:0]	MB_Row;
	
	reg				ee_fifo_afull;
	reg				ee_fifo_afull_Dm;
	always @(`CLK_RST_EDGE)
		if (`RST)	ee_fifo_afull_Dm <= 0;
		else 		ee_fifo_afull_Dm <= ee_fifo_afull;

	// wire		fdct_go;	
	wire		fdct_ready_for_next;
	reg			doing_fdct;
	wire		fdct_go = !doing_fdct && (MB_semaphore!=0) && (!ee_fifo_afull_Dm);
	
	always @(`CLK_RST_EDGE)
		if (`RST)					MB_semaphore <= 0;
		else if (camfifo_o_f)		MB_semaphore <= PicWidthInMbs;
		else if (fdct_go)			MB_semaphore <= MB_semaphore - 1;
		
	always @(`CLK_RST_EDGE)
		if (`RST)	err_sensor_too_fast <= 0;
		else 		err_sensor_too_fast <= camfifo_o_f && MB_semaphore!=0;
		
`ifdef SIMULATING
	always @(`CLK_RST_EDGE)
		if (camfifo_o_f && MB_semaphore!=0 ) begin
			$display("T %d============== camera too fast  ============", $time);
			#100 $finish();
		end	
`endif	
	always @(`CLK_RST_EDGE)
		if (`RST)						doing_fdct <= 0;
		else if (fdct_go)				doing_fdct <= 1;
		else if (fdct_ready_for_next)	doing_fdct <= 0;
	
	// here can use register

	wire	MB_Col_max_f = MB_Col == (PicWidthInMbs-1);
	wire	MB_Row_max_f = MB_Row == (PicHeightInMbs-1);
	always @(`CLK_RST_EDGE)
        if (`RST) begin
            MB_Col <= 0;                  
            MB_Row <= 0;
        end else if (fdct_ready_for_next) begin
            if (MB_Col_max_f) begin
                MB_Row <= MB_Row_max_f ? 0 : MB_Row+1;
                MB_Col <= 0;
            end else begin
                MB_Col <= MB_Col + 1;
            end
        end
	
	wire	last_mb_in_pic = MB_Col_max_f & MB_Row_max_f;
	
	wire						cenb_ee_buf;
	wire	[`W_AEEBUF :0]		ab_ee_buf;
	wire	[`W_DEEBUF :0]		db_ee_buf;
	wire	[`W_AEEBUF_ID :0]	wid_ee_buf;
	wire						wr_ee_buf_ready;	
	
	fdct_quant  fdct_quant(
		.clk				(clk), 
		.rstn				(rstn),
		.fdct_go			(fdct_go),
		.last_mb_in_pic_i	(last_mb_in_pic),
		.last_mb_in_row_i	(MB_Col_max_f),
		.MB_Col				(MB_Col),
		.MB_Row				(MB_Row),
		.aa_camera_buf		(aa_camera_buf),
		.cena_camera_buf	(cena_camera_buf),
		.qa_camera_buf		(qa_camera_buf),
		.ready_for_next     (fdct_ready_for_next),
		.cenb_ee_buf		(cenb_ee_buf),
		.ab_ee_buf			(ab_ee_buf),
		.db_ee_buf			(db_ee_buf),
		.wid_ee_buf			(wid_ee_buf),
		.wr_ee_buf_ready	(wr_ee_buf_ready)
	);
	
	wire	[`W_AEEBUF_ID :0]	rid_ee_buf;
	wire						cena_ee_buf;
	wire	[`W_AEEBUF :0]		aa_ee_buf;
	wire	[`W_DEEBUF :0]		qa_ee_buf;
`ifdef YUV444_ONLY
	rfdp512x96 ee_buf(
`elsif YUV422_ONLY
	rfdp1024x96 ee_buf(
`endif
		.CLKA   (ee_clk),
		.CENA   (cena_ee_buf),
		.AA     ({rid_ee_buf, aa_ee_buf}),
		.QA     (qa_ee_buf),
		.CLKB   (clk),
		.CENB   (cenb_ee_buf),
		.AB     ({wid_ee_buf, ab_ee_buf}),
		.DB     (db_ee_buf)
	);
	
	go_CDC_go  go2go_wr_ee_buf_ready(
		clk,
		rstn,
		wr_ee_buf_ready,	
		ee_clk,
		rstn_ee,
		wr_ee_buf_ready_Dee
		);
	
	reg							doing_ee;
	wire						ee_ready_for_next;
	reg		[`W_AEEBUF_ID+1:0]	ee_semaphore;
	wire		ee_go = !doing_ee & (ee_semaphore!=0);

	wire		ee_semaphore_inc = wr_ee_buf_ready_Dee;
	wire		ee_semaphore_dec = ee_go;
	
	always @(posedge ee_clk)
		if (!rstn_ee)	ee_semaphore <= 0;
		else case({ee_semaphore_inc, ee_semaphore_dec})		
			2'b10: ee_semaphore <=  ee_semaphore + 1;
			2'b01: ee_semaphore <=  ee_semaphore - 1;
		endcase
	always @(posedge ee_clk)
		if (!rstn_ee) 	ee_fifo_afull <= 0;
		else 			ee_fifo_afull <= ee_semaphore >= ( (1<<(`W_AEEBUF_ID+1)) - 3)?  1 : 0;
	always @(posedge ee_clk)
		if (!rstn_ee)					doing_ee <= 0;
		else if (ee_go)					doing_ee <= 1;
		else if (ee_ready_for_next)		doing_ee <= 0;
	always @(posedge ee_clk)
		if (!rstn_ee)		err_eefifo_overflow <= 0;
		else 				err_eefifo_overflow <= ee_semaphore[`W_AEEBUF_ID+1];
	
`ifdef SIMULATING
	always @(posedge ee_clk)	
		if(ee_semaphore[`W_AEEBUF_ID+1]) begin
			$display("T %d============== ee_fifo overflow============", $time);
			#100 $finish();
		end
`endif
	
	
	wire						entropy_o_f;
	wire		[`W_VLCO:0]		entropy_o_bits;
	wire		[`W_VLCL:0]		entropy_o_bits_len;
	
	entropy_encoder entropy_encoder(
		.clk				(ee_clk), 
		.rstn				(rstn_ee),
		.ee_go				(ee_go),
		.rid_ee_buf			(rid_ee_buf),
		.aa_ee_buf			(aa_ee_buf),
		.qa_ee_buf			(qa_ee_buf),
		.cena_ee_buf		(cena_ee_buf),
		
		.entropy_o_f		(entropy_o_f),
		.entropy_o_bits		(entropy_o_bits),
		.entropy_o_bits_len	(entropy_o_bits_len),
	
		.ee_frame_ready		(ee_frame_ready),
		.ee_ready_for_next	(ee_ready_for_next)
		);
	
	wire				bs_data_valid;
	wire	[7:0]		bs_data_out;
	wire				bs_frame_ready;
	wire				header_byte_f;
	wire	[7:0]		header_byte;
	wire				header_ready;
	
	bitstream bitstream(
		.clk				(ee_clk), 
		.rstn				(rstn_ee),
		.bs_load_i			(entropy_o_f),
		.bs_data_in_i		(entropy_o_bits),
		.bs_data_len_i		(entropy_o_bits_len),
		.ee_frame_ready_i	(ee_frame_ready),
		.bs_frame_ready		(bs_frame_ready),
		.data_valid			(bs_data_valid),
		.data_out			(bs_data_out)
	);	

`ifdef WITH_ETHER_RTP_TX	
	assign	header_byte_f = 1'b0;
	always @(posedge ee_clk)
		if (!rstn_ee)	pic_ready <= 0;
		else 			pic_ready <= bs_frame_ready;
	
`else
	go_CDC_go  go2go_cam_pic_start_f(
		clk,
		rstn,
		cam_pic_start_f,	
		ee_clk,
		rstn_ee,
		cam_pic_start_f_Dee
		);
	
	header_gen header_gen(
		.clk				(ee_clk), 
		.rstn				(rstn_ee),
		.header_go			(cam_pic_start_f_Dee),
		.eoi				(bs_frame_ready),
		.PicWidth_i			(PicWidth_i),
		.PicHeight_i		(PicHeight_i),
		.header_byte_f		(header_byte_f),
		.header_byte		(header_byte),
		.header_ready       (header_ready),
		.frame_ready        (pic_ready)
		);
`endif	
`ifdef SIMULATING
	reg	[31:0]	bytes_cnt;
	always @(posedge ee_clk)
		if (!rstn_ee)				bytes_cnt <= 0;
		else if (pic_ready)			bytes_cnt <= 0;
		else if (data_valid) 		bytes_cnt <= bytes_cnt + 1;
	
`endif
	always @(posedge ee_clk)
		if (!rstn_ee)	data_out <= 0;
		else 			data_out <= header_byte_f? header_byte : bs_data_out;
	always @(posedge ee_clk)
		if (!rstn_ee)	data_valid <= 0;
		else 			data_valid <= header_byte_f | bs_data_valid;
		
endmodule