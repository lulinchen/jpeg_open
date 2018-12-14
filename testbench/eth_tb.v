// Copyright (c) 2018  LulinChen, All Rights Reserved
// AUTHOR : 	LulinChen
// AUTHOR'S EMAIL : lulinchen@aliyun.com 
// Release history
// VERSION Date AUTHOR DESCRIPTION

`include "jpeg_global.v"

`define	MAX_PATH			256
`define	ETHER_CLK_PERIOD_DIV2			(4*`TIME_COEFF)  // 125
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
	
	reg		ether_clk;
	initial begin
		ether_clk = 1;
		forever begin
			ether_clk = ~ether_clk;
			#(`ETHER_CLK_PERIOD_DIV2);
		end
	end
	
	itf_data_punch itf(ee_clk);
	wire			data_valid =  itf.data_valid;
	wire	[ 7:0]	data_out =  itf.data_out;
	wire			data_frame_ready =  itf.data_frame_ready;
	initial begin
		#(`RESET_DELAY)
		#(`RESET_DELAY)
		itf.drive_a_frame();
		#(`RESET_DELAY)
		itf.drive_a_frame();
		#(30000* `TIME_COEFF)
		$finish();
	end
	gether_mac_tx gether_mac_tx(
		.clk				(ether_clk),
		.rstn				(rstn),
		.PicWidth_i			(16),
		.PicHeight_i		(16),
		.data_clk			(ee_clk),
		.data_valid			(data_valid),
		.data_out			(data_out),
		.data_frame_ready	(data_frame_ready)
		);

`ifdef DUMP_FSDB 
	initial begin
	$fsdbDumpfile("fsdb/xx.fsdb");
	$fsdbDumpvars();
	end
`endif
	
endmodule

interface itf_data_punch(input clk);
	logic 			data_valid;
	logic [ 7:0]	data_out;
	logic			data_frame_ready;
	
	clocking cb@( `CLK_EDGE);
		output		data_valid;
		output		data_out;
		output		data_frame_ready;
	endclocking	
	
	task drive_a_frame();
		
		logic [9:0]  trailings;
		
		data_valid		 <= 0;
		data_out		 <= 0;
		data_frame_ready <= 0;
		@cb;
		@cb;
		
		for (int i = 0; i<3; i++) begin
			for(int j = 0; j<1024; j++) begin
				data_valid		 <= 1;
				data_out		 <= $random;
				@cb;
			end
			data_valid		 <= 0;
			@cb;
			@cb;
			@cb;
			@cb;
			@cb;
			@cb;
		end
		trailings = $random%1024;
		$display("=========trailings %d ===========", trailings);
		for (int i = 0; i<trailings; i++) begin
			data_valid		 <= 1;
			data_out		 <= 8'HFF;
			@cb;
		end
		data_valid		 <= 0;
		data_frame_ready <= 1;
		@cb;
		data_frame_ready <= 0;
		@cb;
		
	endtask
	
	
endinterface

