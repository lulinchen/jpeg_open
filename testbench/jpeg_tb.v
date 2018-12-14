// Copyright (c) 2018  LulinChen, All Rights Reserved
// AUTHOR : 	LulinChen
// AUTHOR'S EMAIL : lulinchen@aliyun.com 
// Release history
// VERSION Date AUTHOR DESCRIPTION

`include "jpeg_global.v"

`define	MAX_PATH			256
module tb();

	parameter  FRAME_WIDTH = 112;
	parameter  FRAME_HEIGHT = 48;
	parameter  SIM_FRAMES = 2;
	reg						rstn;
	reg						clk;
	reg						ee_clk;
	
	wire		rstn_ee = rstn;
	initial begin
		rstn = `RESET_ACTIVE;
		#(`RESET_DELAY); 
		$display("T%d rstn done#############################", $time);
		rstn = `RESET_IDLE;
	end
	
	initial begin
		clk = 1;
		forever begin
			clk = ~clk;
			#(`CLK_PERIOD_DIV2);
		end
	end
	
	initial begin
		ee_clk = 1;
		forever begin
			ee_clk = ~ee_clk;
			#(`EE_CLOCK_PERIOD_DIV2);
		end
	end
	
	reg			[15:0]			frame_width_0;
	reg			[15:0]			frame_height_0;
	reg			[31:0]			pic_to_sim;
	reg		[`MAX_PATH*8-1:0]	sequence_name_0;

	task process_cmdline;
		frame_width_0			= FRAME_WIDTH;
		frame_height_0			= FRAME_HEIGHT;
		pic_to_sim				= SIM_FRAMES;
		
		if (!$value$plusargs("width=%d", frame_width_0)) begin
			$display("Frame width is NOT specified");
		end
		if (!$value$plusargs("height=%d", frame_height_0)) begin
			$display("Frame height is NOT specified");
		end
		if (!$value$plusargs("frames=%d", pic_to_sim)) begin
			$display("Frames to be encoded is NOT specified, use whole file");
		end
		if (!$value$plusargs("inputuyvy=%s", sequence_name_0)) begin
			$display("Missing input sequence file.");
			$finish;
		end

		
		$display(" Geometry:            %0dx%0d",	frame_width_0, frame_height_0				);
		$display(" InputSequence:       %0s",		sequence_name_0								);
		$display(" SimFrames:           %0d",		pic_to_sim								    );
	endtask
	
	initial 
		process_cmdline;

	wire	[`W_CAMD_I:0]	cam_data_0;
	wire					sdc_init_done  = 1'b1;
	sensor	sensor0 (
		.sequence_name	(sequence_name_0),
		.width    		(frame_width_0),
		.height    		(frame_height_0),
		.pic_to_sim   	(pic_to_sim),
		.cam_active		(sdc_init_done),
		.cam_clk    	(cam_clk),
		.cam_href    	(cam_href_0),
		.cam_vsync    	(cam_vsync_0),
		.cam_data    	(cam_data_0));	
	
	
	wire  [7:0]             data_out;
    wire                    data_valid;
	wire					pic_start_f;
	jpeg_enc jpeg_enc(
		.clk			(clk),
		.rstn			(rstn),
		.encoder_active	(sdc_init_done),	
		
		.ee_clk			(ee_clk),
		.rstn_ee		(rstn),	
		
		.cam_clk		(cam_clk),
		.rstn_cam		(rstn),
		
		.cam_vsync_i	(cam_vsync_0),
		.cam_href_i		(cam_href_0),
		.cam_data_i		(cam_data_0),	
		//.cam_data_i		({8'h80, 8'h80}),	
		.PicWidth_i		(frame_width_0),	
		.PicHeight_i	(frame_height_0),
		.data_valid		(data_valid),
		.data_out		(data_out),
		.pic_ready		(pic_ready)
	);
	

`ifdef WITH_ETHER_RTP_TX
	`define	ETHER_CLK_PERIOD_DIV2			(4*`TIME_COEFF)  // 125
	reg		ether_clk;
	initial begin
		ether_clk = 1;
		forever begin
			ether_clk = ~ether_clk;
			#(`ETHER_CLK_PERIOD_DIV2);
		end
	end
	// jpeg_feeder jpeg_feeder(
		// .clk			(ee_clk),
		// .rstn			(rstn),
		// .cam_vsync_i	(cam_vsync_0),
		// .MBs_in8		(frame_width_0*frame_height_0/1024),
		// //.MBs_in8		(2025),
		// .data_valid		(data_valid),
		// .data_out		(data_out),
		// .pic_ready		(pic_ready)
	// );
	
	gether_mac_tx gether_mac_tx(
		.clk				(ether_clk),
		.rstn				(rstn),
		.PicWidth_i			(frame_width_0),
		.PicHeight_i		(frame_height_0),
		.data_clk			(ee_clk),
		.data_valid			(data_valid),
		.data_out			(data_out),
		.data_frame_ready	(pic_ready)
		);
`endif	
	reg				pic_ready_d1, pic_ready_d2, pic_ready_d3;	
	reg		[15:0]	pic_encoded;	
	reg				frame_en;
	always @(posedge ee_clk)
		if (!rstn_ee)	{pic_ready_d1, pic_ready_d2, pic_ready_d3} <= 0;
		else			{pic_ready_d1, pic_ready_d2, pic_ready_d3} <= {pic_ready, pic_ready_d1, pic_ready_d2};
	always @(posedge ee_clk)
		if (!rstn_ee)	pic_encoded <= 0;
		else if (pic_ready)	begin
			pic_encoded <= pic_encoded + 1;
			$display("T%d============encoded a frame %d=============", $time, pic_encoded);
		end
		
	reg		simulation_done;	
	always @(posedge ee_clk)
		if (!rstn_ee)						simulation_done <= 0;
		else if (pic_encoded==pic_to_sim)	simulation_done <= 1;
	
	integer					fds;
	reg			[ 1:0]		num_bytes;
	reg			[31:0]		d_o_fifo;

	wire			[31:0]	dw = d_o_fifo << (32 - num_bytes * 8);
	wire			[31:0]	last_word = {dw[7:0], dw[15:8], dw[23:16], dw[31:24]};

	always @(posedge ee_clk)
		if (!rstn_ee)				num_bytes <= 0;
		else if (pic_start_f)	 	num_bytes <= 0;
		else if (pic_ready_d1)	 	num_bytes <= 0;
		else if (data_valid)  		num_bytes <= num_bytes + 1;
	always @(posedge ee_clk)
		if (data_valid) d_o_fifo <= #1 {d_o_fifo[23: 0], data_out};
	wire [31:0]	 fds_word = {data_out, d_o_fifo[7-:8], d_o_fifo[15-:8], d_o_fifo[23-:8] };
	
	always @(posedge ee_clk)
		if (data_valid && num_bytes == 3) begin
			$fwrite(fds, "%u", fds_word);
			$fflush(fds);
		end	
	wire	[15:0]				pic_encoded_decimal	= 	(pic_encoded/10)*256 + pic_encoded%10;
	reg		[`MAX_PATH*8-1:0]	jpeg = "out00.jpeg";
	wire	[`MAX_PATH*8-1:0]	pic_encoded_ASCII = jpeg + {pic_encoded_decimal,40'h0};
	
	always @(posedge ee_clk)
		if (pic_ready_d1) begin
			if (num_bytes > 0)
			$fwrite(fds, "%u", last_word);
			$fflush(fds);
			$fclose(fds);
			fds = $fopen(pic_encoded_ASCII, "wb");
		end		
	initial  begin
		simulation_done = 0;
		fds = $fopen(jpeg, "wb");
		wait (simulation_done == 1);
		$display("\n##################################################################");
		$display("##################### simulation end #############################");
		$display("##################################################################");
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		$fclose(fds);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		$finish;	
	end	

`ifdef DUMP_FSDB 
	initial begin
	$fsdbDumpfile("fsdb/xx.fsdb");
	$fsdbDumpvars();
	end
`endif
	
endmodule


