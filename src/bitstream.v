// Copyright (c) 2018  LulinChen, All Rights Reserved
// AUTHOR : 	LulinChen
// AUTHOR'S EMAIL : lulinchen@aliyun.com 
// Release history
// VERSION Date AUTHOR DESCRIPTION
`include "jpeg_global.v"

module bitstream(
	input						clk,
	input						rstn,
	input				        bs_load_i,
    input          [`W_BSDI :0] bs_data_in_i, 
    input          [`W_BSDIL:0] bs_data_len_i,
	
	input						ee_frame_ready_i,
	
	output						bs_frame_ready,
	output  	                data_valid,
    output  	       [ 7:0]   data_out
	);
	parameter  BSL = 59;		
	parameter  WF = 5;		
	parameter  WB8 =  7;
	
	
	reg		[`W_BSDI:0]		src;
	reg		[`W_BSDIL:0]	src_len;
	reg						bs_load;
	reg		[BSL:0]			src_shifted_r;
	
	reg     [BSL:0]    	 	bs_fifo;
    wire    [WF :0]     	_bs_fifo_len;           // 0~64
    reg     [WF :0]    	 	bs_fifo_len;     
	
	
	reg				ee_frame_ready;
	always @(`CLK_RST_EDGE)
		if (`RST)	ee_frame_ready <= 0;
		else 		ee_frame_ready <= ee_frame_ready_i;
	reg		[7:0]	ee_frame_ready_d;
	always @(*)	ee_frame_ready_d[0] = ee_frame_ready;
	always @(`CLK_RST_EDGE)
		if (`RST)	ee_frame_ready_d[7:1] <= 0;
		else 		ee_frame_ready_d[7:1] <= ee_frame_ready_d;
	
	reg					[1:0]	wSlcBSF_bytes_void;
	always @(`CLK_RST_EDGE)
        if (`RST) 	wSlcBSF_bytes_void <= 0;
        else      	wSlcBSF_bytes_void <= ~bs_fifo_len[4:3] + 1;
		
	always @(`CLK_RST_EDGE)
		if (`RST)	src_len <= 0;
		else if (ee_frame_ready)
				case(bs_fifo_len[2:0])  
				3'd0: src_len <= 8;
				3'd1: src_len <= 7;
				3'd2: src_len <= 6;
				3'd3: src_len <= 5;
				3'd4: src_len <= 4;
				3'd5: src_len <= 3;
				3'd6: src_len <= 2;
				3'd7: src_len <= 1;
				endcase    
	//	else if (ee_frame_ready_d[2])
	//			src_len <= 16;
		else if (ee_frame_ready_d[3])	// one more clk to wait for wSlcBSF_bytes_void
				src_len <= {wSlcBSF_bytes_void, 3'b000};
		else 	src_len <= bs_load_i? bs_data_len_i : 0;
		
	always @(`CLK_RST_EDGE)
		if (`RST)	src <= 0;
		else if (ee_frame_ready & bs_fifo_len[2:0]!=0)
					//src <= {1'b1, {`W_BSDI{1'b0}}}; 
				case(bs_fifo_len[2:0])  
				3'd0: src <= 0; 
				3'd1: src <= {{7{1'b1}}, {`W_BSDI-6{1'b0}}}; 
				3'd2: src <= {{6{1'b1}}, {`W_BSDI-5{1'b0}}}; 
				3'd3: src <= {{5{1'b1}}, {`W_BSDI-4{1'b0}}}; 
				3'd4: src <= {{4{1'b1}}, {`W_BSDI-3{1'b0}}}; 
				3'd5: src <= {{3{1'b1}}, {`W_BSDI-2{1'b0}}}; 
				3'd6: src <= {{2{1'b1}}, {`W_BSDI-1{1'b0}}}; 
				3'd7: src <= {{1{1'b1}}, {`W_BSDI{1'b0}}}; 
				endcase    
	//	else if (ee_frame_ready_d[2])
	//				src <= {16'hFFD9, {`W_BSDI+1-16{1'b0}}}; 
		else 		src <= bs_load_i? bs_data_in_i<<(`W_BSDI+1 - bs_data_len_i) : 0;
	
	//bs_fifo_len   one clk ahead  bs_fifo
	// src
	// src_len
	//      src_ext
	//      bs_fifo_len
	// 			bs_fifo
	// fifo_plus_src_len
	// 			fifo_plus_src_len_GE32_d1
	//
	always @(`CLK_RST_EDGE)
		if (`RST)	bs_load <= 0;
		else 		bs_load <= bs_load_i;
	wire	[BSL:0] 	src_ext = {src, {(BSL-`W_BSDI){1'b0}}};
	always @(`CLK_RST_EDGE)
		if (`RST)	src_shifted_r <= 0;
		else 		src_shifted_r <= src_ext >> bs_fifo_len[4:0]; 	
	
	wire  			[WF:0]  	fifo_plus_src_len = bs_fifo_len + src_len;
	wire						fifo_plus_src_len_GE32 = fifo_plus_src_len[WF:5] != 0;
	wire						bs_fifo_len_GE32 = bs_fifo_len[WF:5] != 0;
	wire			[BSL:0]		_bs_fifo          = (bs_fifo | src_shifted_r);
	
	
	reg							bs_fifo_len_GE32_d1;
	always @(`CLK_RST_EDGE)
		if (`ZST)	bs_fifo_len_GE32_d1 <= 0;
		else 		bs_fifo_len_GE32_d1 <= bs_fifo_len_GE32;
	reg							fifo_plus_src_len_GE32_d1;
	always @(`CLK_RST_EDGE)
		if (`ZST)	fifo_plus_src_len_GE32_d1 <= 0;
		else 		fifo_plus_src_len_GE32_d1 <= fifo_plus_src_len_GE32;
		
	
	always @(`CLK_RST_EDGE)
        if (`RST) 							bs_fifo_len <= 0;
		else if (fifo_plus_src_len_GE32)	bs_fifo_len <= fifo_plus_src_len - 32;
		else								bs_fifo_len <= fifo_plus_src_len;
	always @(`CLK_RST_EDGE)
        if (`RST) 							bs_fifo <= 0;
    //    else if (bs_fifo_len_GE32_d1)		bs_fifo <= {_bs_fifo[(BSL-32):0], 32'b0};
        else if (fifo_plus_src_len_GE32_d1)	bs_fifo <= {_bs_fifo[(BSL-32):0], 32'b0};
		else 								bs_fifo <= _bs_fifo;
	
	reg				[WB8:0]		bsfBMap;
	reg				[WB8:0]		bsfBMap_d1;
	always @(`CLK_RST_EDGE)
		if (`ZST)	bsfBMap_d1 <= 0;
		else 		bsfBMap_d1 <= bsfBMap;
	
	always @(`CLK_RST_EDGE)
		if (`RST)					bsfBMap <= 0;
		else if(ee_frame_ready_d[1])  
			case(bs_fifo_len[WF :3])
			0:	bsfBMap[0] <= 1;
			1:	bsfBMap[1] <= 1;
			2:  bsfBMap[2] <= 1;
			3:  bsfBMap[3] <= 1;
			4:  bsfBMap[4] <= 1;
			5:  bsfBMap[5] <= 1;
			6:  bsfBMap[6] <= 1;
			7:  bsfBMap[7] <= 1;
			endcase
		else if (ee_frame_ready_d[3])
			case(wSlcBSF_bytes_void)
			//0:	bsfBMap[0] <= 1;
			1:	bsfBMap[3]   <= -1;
			2:  bsfBMap[3:2] <= -1;
			3:  bsfBMap[3:1] <= -1;
			endcase
		else if (fifo_plus_src_len_GE32_d1)
			bsfBMap <= {4'b0000, bsfBMap[WB8:4]};
			
	//ee_frame_ready			
	//	src_len		
	//	src		
	//	fifo_plus_src_len		
	//		bs_fifo_len	
	//		src_shifted_r	
	//		_bs_fifo	
	//			bs_fifo
	//			bs_4bytes
	//   
	
	wire  		[ 31:0]  	_bs_4bytes = _bs_fifo[BSL-:32];
	reg			[31:0]		bs_4bytes;
	reg						bs_4bytes_valid;
	always @(`CLK_RST_EDGE)
		if (`RST)	bs_4bytes <= 0;
		else 		bs_4bytes <= _bs_4bytes;
	always @(`CLK_RST_EDGE)
		if (`RST)	bs_4bytes_valid <= 0;
		else 		bs_4bytes_valid <= fifo_plus_src_len_GE32_d1;
	reg		[0:0]		bs_4bytes_valid_d1;
	always @(`CLK_RST_EDGE)
		if (`ZST)	bs_4bytes_valid_d1 <= 0;
		else 		bs_4bytes_valid_d1 <= bs_4bytes_valid;	
		
	reg		[8:0]	aa_stream_32to8_buf;
	reg				cena_stream_32to8_buf;
	reg		[8:0]	ab_stream_32to8_buf;
	reg		[35:0]	db_stream_32to8_buf;
	reg				cenb_stream_32to8_buf;
	wire	[35:0]	qa_stream_32to8_buf;
	
	rfdp512x36 stream_32to8_buf(
		.CLKA   (clk),
		.CENA   (1'b0),
		.AA     (aa_stream_32to8_buf),
		.QA     (qa_stream_32to8_buf),
		.CLKB   (clk),
		.CENB   (cenb_stream_32to8_buf),
		.AB     (ab_stream_32to8_buf),
		.DB     (db_stream_32to8_buf)
		);
	
	always @(`CLK_RST_EDGE)
		if (`RST)	cenb_stream_32to8_buf <= 0;
		else 		cenb_stream_32to8_buf <= ~bs_4bytes_valid;
	always @(`CLK_RST_EDGE)
		if (`RST)	db_stream_32to8_buf <= 0;
		else 		db_stream_32to8_buf <= {bsfBMap_d1[3:0], bs_4bytes};
	always @(`CLK_RST_EDGE)
		if (`RST)						ab_stream_32to8_buf <= 0;
		else if (bs_4bytes_valid_d1) 	ab_stream_32to8_buf <= ab_stream_32to8_buf + 1;

	reg		[35:0]		qa_stream_32to8_buf_d1;
	always @(`CLK_RST_EDGE)
		if (`ZST)	qa_stream_32to8_buf_d1 <= 0;
		else 		qa_stream_32to8_buf_d1 <= qa_stream_32to8_buf;
		
	reg		[1:0]		cnt_32to8;
	reg		[8+3:0]  	bufbytes; 
	wire				rd_buf = (bufbytes != 0); 
	always @(`CLK_RST_EDGE)
		if (`RST) 	cnt_32to8 <= 0;
		else      	cnt_32to8 <= cnt_32to8 + rd_buf;
	always @(`CLK_RST_EDGE)
		if (`RST) 	bufbytes <= 0;
		else      	bufbytes <= bufbytes + {bs_4bytes_valid_d1, 2'b00} - rd_buf;
	
	reg		[7:0]	rd_buf_d;
	always @(*)	rd_buf_d[0] = rd_buf;
	always @(`CLK_RST_EDGE)
		if (`RST)	rd_buf_d[7:1] <= 0;
		else 		rd_buf_d[7:1] <= rd_buf_d;	
	
	reg		[7:0][1:0]	cnt_32to8_d;
	always @(*)	cnt_32to8_d[0] = cnt_32to8;
	always @(`CLK_RST_EDGE)
		if (`RST)	cnt_32to8_d[7:1] <= 0;
		else 		cnt_32to8_d[7:1] <= cnt_32to8_d;	
	
	//  			rd_buf 
	// cnt_32to8	0   1	2	3 
	// 				aa	
	//					qa             
	// 						qa_d1
	always @(`CLK_RST_EDGE)
        if (`RST)                   aa_stream_32to8_buf <= 0;
        else if (3 == cnt_32to8) 	aa_stream_32to8_buf <= aa_stream_32to8_buf + 1;
	reg		[7:0]	tmpData;
	reg				tmpData_stuff_f;
	always @(`CLK_RST_EDGE)
        if (`ZST) tmpData <= 0;
        else if (rd_buf_d[2])
        	case(cnt_32to8_d[2])
        	2'd0: tmpData <= qa_stream_32to8_buf_d1[31-:8];
        	2'd1: tmpData <= qa_stream_32to8_buf_d1[23-:8];
        	2'd2: tmpData <= qa_stream_32to8_buf_d1[15-:8];
        	2'd3: tmpData <= qa_stream_32to8_buf_d1[ 7-:8];
			endcase        
		else
			tmpData <= 0;
	
	always @(`CLK_RST_EDGE)
        if (`ZST) tmpData_stuff_f <= 0;
        else if (rd_buf_d[2])
        	case(cnt_32to8_d[2])
        	2'd0: tmpData_stuff_f <= qa_stream_32to8_buf_d1[32];
        	2'd1: tmpData_stuff_f <= qa_stream_32to8_buf_d1[33];
        	2'd2: tmpData_stuff_f <= qa_stream_32to8_buf_d1[34];
        	2'd3: tmpData_stuff_f <= qa_stream_32to8_buf_d1[35];
			endcase        
		else
			tmpData_stuff_f <= 0;
	reg		[0:0]		tmpData_stuff_f_d1;
	always @(`CLK_RST_EDGE)
		if (`ZST)	tmpData_stuff_f_d1 <= 0;
		else 		tmpData_stuff_f_d1 <= tmpData_stuff_f;
	
	reg				_bs_frame_ready;
	always @(`CLK_RST_EDGE)
		if (`RST)	_bs_frame_ready <= 0;
		else		_bs_frame_ready <= tmpData_stuff_f & !tmpData_stuff_f_d1;
	
	reg				_data_valid;
	reg	[ 7:0]      _data_out;
	always @(`CLK_RST_EDGE)
		if (`RST)	_data_valid <= 0;
		else 		_data_valid <= rd_buf_d[3] && !(tmpData_stuff_f && tmpData==8'h00);
	always @(`CLK_RST_EDGE)
		if (`RST)	_data_out <= 0;
		else 		_data_out <= tmpData;	
`ifdef SIMULATING
	reg	[31:0]	bytes_cnt;
	always @(`CLK_RST_EDGE)
		if (`RST)					bytes_cnt <= 0;
		else if (_bs_frame_ready)	bytes_cnt <= 0;
		else if (_data_valid) 		bytes_cnt <= bytes_cnt + 1;
	
`endif
	byte_stuffer byte_stuffer(
		.clk				(clk), 
		.rstn				(rstn),
		.data_i_frame_ready	(_bs_frame_ready),
		.data_valid_i		(_data_valid),
		// .data_i				({_data_out, 4'hf}),
		.data_i				(_data_out),
		.data_o_frame_ready	(bs_frame_ready),
		.data_valid_o		(data_valid),
		.data_o				(data_out)
		);
		
endmodule


module byte_stuffer(
	input				clk,
	input				rstn,
	input				data_i_frame_ready,
	input		[ 7:0]	data_i,
	input				data_valid_i,
	
	output reg			data_o_frame_ready,
	output reg	[ 7:0]	data_o,
	output reg			data_valid_o
	
	);
	
	reg		[0:7][7:0] 	fifo_r;
	reg		[3:0]		fifo_cnt;
	reg		[2:0]		fifo_rpt;
	reg		[2:0]		fifo_wpt;
	wire				fifo_inc = data_valid_i;
	wire				fifo_dec;
`ifdef SIMULATING
	always @(`CLK_RST_EDGE)
		if(fifo_cnt>8)
			$display("T %d==========byte_stuffer fifo over or down flow", $time);
`endif
	always @(`CLK_RST_EDGE)
		if (`RST)	fifo_cnt <= 0;
		else case({fifo_inc , fifo_dec})
			2'b10:	fifo_cnt <= fifo_cnt + 1;	
			2'b01:	fifo_cnt <= fifo_cnt - 1;	
			endcase
	
	always @(`CLK_RST_EDGE)
		if (`RST)				fifo_wpt <= 0;
		else if (fifo_inc) 		fifo_wpt <= fifo_wpt + 1;
	always @(`CLK_RST_EDGE)
		if (`RST)				fifo_rpt <= 0;
		else if (fifo_dec) 		fifo_rpt <= fifo_rpt + 1;
	always @(`CLK_RST_EDGE)
		if (`RST)				fifo_r <= 0;
		else if (fifo_inc)		fifo_r[fifo_wpt] <= data_i;
		
	//assign	fifo_dec = 	(fifo_cnt!=0)&(fifo_r[fifo_rpt] != 8'hff);
	assign	fifo_dec = 	(fifo_cnt!=0)&(data_o != 8'hff);
	
	always @(`CLK_RST_EDGE)
		if (`RST)	data_valid_o <= 0;
		else 		data_valid_o <= (fifo_cnt!=0) | (data_o == 8'hff);
	always @(`CLK_RST_EDGE)
		if (`RST)				data_o <= 0;
		else if (fifo_dec)		data_o <= fifo_r[fifo_rpt];
		else					data_o <= 0;
	reg		fifo_empty;
	
	always @(`CLK_RST_EDGE)
		if (`RST)	fifo_empty <= 1;
		else 		fifo_empty <= fifo_cnt==0;
	reg		bs_frame_done;
	
	always @(`CLK_RST_EDGE)
		if (`RST)							bs_frame_done <= 0;
		else if (data_i_frame_ready) 		bs_frame_done <= 1;
		else if (fifo_empty)				bs_frame_done <= 0;
	always @(`CLK_RST_EDGE)
		if (`RST)	data_o_frame_ready <= 0;
		else 		data_o_frame_ready <= bs_frame_done & fifo_empty;

endmodule
