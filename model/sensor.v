// Copyright (c) 2018  Lulinchen, All Rights Reserved
// FILE NAME :	sensor_hd.v
// TYPE :		module
// AUTHOR : 	Lulinchen
// AUTHOR'S EMAIL : lulinchen@aliyun.com 
// Release history
// VERSION Date AUTHOR DESCRIPTION

`ifdef SIMULATING


`timescale 1ns/10ps


`ifdef  RESET_DELAY
`undef  RESET_DELAY
`endif
`define RESET_DELAY		100


`include "jpeg_global.v"

module sensor(   
	input			[2047:0]	sequence_name,
	input			[  15:0]	width,
	input			[  15:0]	height,
	input			[  31:0]	pic_to_sim,
	input						cam_active,
	output reg					cam_clk,		
	output reg					cam_href,		
	output reg					cam_vsync,		
	output 	    [`W_CAMD_I:0]	cam_data											
	);



	parameter	tCLK		= 13.06;
	parameter	tCLKL		= tCLK/2;
	parameter	tCLKH		= tCLK/2;
	
	parameter	HBLANK_0	= 8;
	parameter	VBLANK0_0	= 8;			
	parameter	VBLANK1_0	= 8;
	parameter	VBLANK2_0	= 8;

	initial begin
		forever begin
			cam_clk = 1'b1;
			#(tCLKH); 
			cam_clk = 1'b0;
			#(tCLKL); 
		end
	end

	reg					cam_rst;
	initial begin
		cam_rst = 1'b0;
		#(`RESET_DELAY); 
		cam_rst = 1'b1;
	end
	reg 		[ `W1:0]	cam_data0, cam_data1, cam_data2, cam_data3;		
`ifdef YUV444_ONLY
	assign  cam_data = {cam_data2, cam_data1, cam_data0};  // VUY
`else
	assign  cam_data = {cam_data0, cam_data1};			// UYVY
`endif
												//	720x576	112x80
	integer						t_hblank,		//	  288	   46
								t_hactive,		//	 1440	  224
								t_line,			//   1728     270
								t_vblank0,		//	   22       4
								t_vactive,		//    576      80
								t_vblank1,		//     27       4
								t_frame;		//    625      88

	integer						pixels,
								lines,
								frames;


	always @(posedge cam_clk or negedge cam_rst)
		if (!cam_rst) begin
			t_hblank	= HBLANK_0 * 2;
			t_hactive	= width;
			t_line		= t_hblank + t_hactive;
			t_vblank0	= VBLANK0_0;
			t_vactive	= height;
			t_vblank1	= VBLANK1_0 + VBLANK2_0;
			t_frame		= t_vblank0 + t_vactive + t_vblank1;
		end

	always @(posedge cam_clk or negedge cam_rst) begin: pixel_counter
		if (!cam_rst) begin
			pixels <= 0;
			frames <= 0;
			lines <= 0;
		end else begin
			if (cam_active) begin
				if (pixels + 1 == t_line) begin
					pixels	<= 0;
					if (lines + 1 == t_frame) begin
						frames <= frames + 1;
						lines  <= 0;
					end else begin
						lines <= lines + 1;
					end	
				end else begin
					pixels	<= pixels + 1;
				end
			end
		end
	end

	integer						fd;
	integer						errno;
	reg			[640-1:0]		errinfo;

	initial begin
		#1
		fd = $fopen(sequence_name, "rb");
		if (fd == 0) begin
			errno = $ferror(fd, errinfo);
			$display("sensor Failed to open file %0s for read.", sequence_name);
			$display("errno: %0d", errno);
			$display("reason: %0s", errinfo);
			$finish();
		end
	
	end


	reg							vsync_1st_rising;		
	wire  vsync = (lines < t_vblank0 || t_vblank0 + t_vactive <= lines);
	wire  href  = (pixels >= t_hblank/2 && pixels < width + t_hblank/2) & ~vsync;

	always @(posedge cam_clk or negedge cam_rst)
		if (!cam_rst)                    vsync_1st_rising <= 0;
		else if (lines == t_vblank0 / 2) vsync_1st_rising <= 1;
	always @(posedge cam_clk or negedge cam_rst) begin: pixel_timing
		if (!cam_rst) begin
			cam_vsync <= 0;
			cam_href  <= 0;
			cam_data0 <= 0;
		end else begin
			cam_vsync <= vsync & vsync_1st_rising;
			cam_href  <= href;
			if (href & (frames < pic_to_sim)) begin
				cam_data0 <= #1 $fgetc(fd);
				cam_data1 <= #1 $fgetc(fd);
`ifdef YUV444_ONLY
				cam_data2 <= #1 $fgetc(fd);		
`endif
			end	
		end
	end
endmodule

`endif

