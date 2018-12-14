// Copyright (c) 2018  LulinChen, All Rights Reserved
// AUTHOR : 	LulinChen
// AUTHOR'S EMAIL : lulinchen@aliyun.com 
// Release history
// VERSION Date AUTHOR DESCRIPTION

`include "jpeg_global.v"
// preampble: 8bytes
typedef struct packed {
    logic [63:0] 	pre;
} Preamble;

// 6*2 + 2 = 14bytes
typedef struct packed {
    logic [47:0] 	dstMac;
    logic [47:0] 	srcMac;
    logic [15:0] 	etherType;
} MacHeader;

// 20bytes
typedef struct packed {
    logic [ 3:0] 	ipVersion;
    logic [ 3:0] 	ipHdrLen;
    logic [ 7:0] 	ipDiffServ;
    logic [15:0] 	ipLen;
    logic [15:0] 	ipId;
    logic [ 2:0] 	ipFlags;
    logic [12:0] 	ipFragOffset;
    logic [ 7:0] 	ipTTL;
    logic [ 7:0] 	ipProtocol;
    logic [15:0] 	ipChecksum;
    logic [31:0] 	ipSrcAddr;
    logic [31:0] 	ipDstAddr;
} IpHeader;

//8bytes
typedef struct packed {
    logic [15:0] 	udpSrcPort;
    logic [15:0] 	udpDstPort;
    logic [15:0] 	udpLen;
    logic [15:0] 	udpChecksum;
} UdpHeader;

// 12btytes
typedef struct packed {
    logic [ 1:0] 	V;
    logic [ 0:0] 	P;
    logic [ 0:0]	X;
    logic [ 3:0] 	CC;
	
    logic [ 0:0] 	M;			// for last packet in a frame set 1
    logic [ 6:0] 	PT;
	
    logic [15:0] 	sequenceNumber;
    logic [31:0] 	timeStamp;
    logic [31:0] 	SSRC;
} RtpHeader;

// 8btytes
typedef struct packed {
    logic [ 7:0] 	typeSpecific;
    logic [23:0] 	fragmentOffset;
    logic [ 7:0] 	typeJpeg;
    logic [ 7:0] 	Q;
    logic [ 7:0] 	width;
    logic [ 7:0] 	height;
} JpegHeader;

`define  MAC_ADDR_BROADCAST		48'hFFFFFFFFFFFF	// dst
`define  MAC_ADDR_NOBROADCAST	48'hEEEEEEEEEEEE	// src

`define  IP_DST_ADDR		32'hFF_FF_FF_FF   
`define  IP_SRC_ADDR		32'hC0_A8_05_91    // 192.168.5.145

`define  ETHER_FRAME_TYPE		16'h0800	
`define	 UDP_SRC_PORT			16'd39630
`define	 UDP_DST_PORT			16'd39630
	
	
`define PREAMBLE_LENGTH    8	
`define MAC_HEADER_LENGTH  14	
`define IP_HEADER_LENGTH   20	
`define UDP_HEADER_LENGTH  8	
`define RTP_HEADER_LENGTH  12	
`define JPEG_HEADER_LENGTH 8	

	
module gether_mac_tx(
	input							clk, 
	input							rstn,

	input     	[`W_PW:0]  			PicWidth_i,	
    input     	[`W_PH:0]  			PicHeight_i,	
	
	input 							data_clk,
	input 	 						data_valid,
	input 		[ 7:0] 				data_out,
	input 							data_frame_ready,
				
	output reg						eth_fifo_full,
	output							gmii_tx_clk,	
	output reg	[ 7:0]				gmii_txd,
	output reg 						gmii_tx_en,
	output							gmii_tx_er	
	);
	
	parameter	S0=0,S1=1,S2=2,S3=3,S4=4,S5=5,S6=6,S7=7,S8=8,S9=9,S10=10,S11=11,S12=12,S13=13,S14=14,S15=15,S16=16,S17=17,S18=18,S19=19,S20=20,S21=21,S22=22,S23=23,S24=24,S25=25,S26=26,S27=27,S28=28,S29=29,S30=30,S31=31,S32=32,S33=33,S63=63;

	parameter  	PAYLOAD_LEN = 1024;
	parameter  	PAYLOAD_LEN_MAX = 1024 + 256;
	parameter 	MAX_CNT_HEADER = `PREAMBLE_LENGTH + `MAC_HEADER_LENGTH + `IP_HEADER_LENGTH + `UDP_HEADER_LENGTH + `RTP_HEADER_LENGTH + `JPEG_HEADER_LENGTH;	//preamble 8B, MAC 14B,  IP 20B, UDP 8B, RTP 12B, Jpeg 8B
	parameter	FPS = 60;
	parameter	FRAME_INTERVAL = 90000/FPS;

	assign	gmii_tx_er = 1'b0;
	assign	gmii_tx_clk = clk;
	
	`define TXFIFO fifo_4096x8
	parameter  W_FIFO_ADDR = 11;
	
	reg				fifo_wid;
	reg				fifo_rid;
	
	reg				data_valid_d1, data_valid_0, data_valid_1;
	reg		[ 7:0]	data_out_d1, data_out_d2;	
	always @ (posedge data_clk `RST_EDGE)
		if (`RST) 	{data_valid_d1, data_out_d1} <= 0;
		else		{data_valid_d1, data_out_d1} <= {data_valid, data_out};
	always @ (posedge data_clk `RST_EDGE)
		if (`RST) 	data_out_d2	<= 0;
		else		data_out_d2	<= data_out_d1;
	always @ (posedge data_clk `RST_EDGE)
		if (`RST)	{data_valid_0, data_valid_1} <= 0;
		else begin
			data_valid_0 <= data_valid_d1 & !fifo_wid;
			data_valid_1 <= data_valid_d1 &  fifo_wid;
		end
	reg		[15:0]	data_frame_ready_d;
	always @(*)	data_frame_ready_d[0] = data_frame_ready;
	always @ (posedge data_clk `RST_EDGE)
		if (`RST)	data_frame_ready_d[15:1] <= 0;
		else 		data_frame_ready_d[15:1] <= data_frame_ready_d;	
	
	always @ (posedge data_clk `RST_EDGE)
		if (`RST)								fifo_wid <= 0;
		else if (data_frame_ready_d[12])		fifo_wid <= fifo_wid + 1;
	wire			fifo0_frame_done_set, fifo1_frame_done_set;
	reg				fifo0_frame_done, fifo1_frame_done;
	wire			fifo_frame_done = fifo_rid == 0? fifo0_frame_done : fifo1_frame_done;
	 //  for more clks for txFIFO_words to update
	go_CDC_go go_CDC_go0(data_clk, rstn, data_frame_ready_d[12]&!fifo_wid, clk, rstn, fifo0_frame_done_set);  
	go_CDC_go go_CDC_go1(data_clk, rstn, data_frame_ready_d[12]& fifo_wid, clk, rstn, fifo1_frame_done_set);
	
	
	wire		[ 7:0]			txFIFO_data0;
	wire		[ 7:0]			txFIFO_data1;
	wire		[ 7:0]			txFIFO_data = fifo_rid == 0? txFIFO_data0 : txFIFO_data1;
	wire		[W_FIFO_ADDR:0]	txFIFO_words0;
	wire		[W_FIFO_ADDR:0]	txFIFO_words1;
	wire		[W_FIFO_ADDR:0]	txFIFO_words = 	fifo_rid == 0? txFIFO_words0 : txFIFO_words1;
	reg							payload_req;
	wire						payload_req0 = payload_req & !fifo_rid;
	wire						payload_req1 = payload_req &  fifo_rid;
	wire						txFIFO_full0, txFIFO_full1;
	wire						txFIFO_empty0, txFIFO_empty1;
	always @ (posedge data_clk `RST_EDGE)
		if (`RST)								eth_fifo_full <= 0;
		else if ((txFIFO_full0 &!txFIFO_empty0)|(txFIFO_full1&!txFIFO_empty1))		eth_fifo_full <= 1;
		
`ifdef FPGA_0_XILINX	
	`TXFIFO txFIFO0 (
		.rst			(~rstn),
		.wr_clk			(data_clk),
		.rd_clk			(clk),
		.din			(data_out_d2),
		.wr_en			(data_valid_0),
		.rd_en			(payload_req0),	
		.dout			(txFIFO_data0),
		.rd_data_count	(txFIFO_words0),
		.empty			(txFIFO_empty0),
		.full			(txFIFO_full0));
	`TXFIFO txFIFO1 (
		.rst			(~rstn),
		.wr_clk			(data_clk),
		.rd_clk			(clk),
		.din			(data_out_d2),
		.wr_en			(data_valid_1),
		.rd_en			(payload_req1),
		.dout			(txFIFO_data1),
		.rd_data_count	(txFIFO_words1),
		.empty			(txFIFO_empty1),
		.full			(txFIFO_full1));
`else
	`TXFIFO txFIFO0 (					
		.aclr			(~rstn),		
		.data			(data_out_d2),
		.rdclk			(clk),
		.rdreq			(payload_req0),	
		.wrclk			(data_clk),
		.wrreq			(data_valid_0),
		.q				(txFIFO_data0),
		.rdusedw		(txFIFO_words0),
		.rdempty		(),
		.wrfull			(txFIFO_full0));
	`TXFIFO txFIFO1 (					
		.aclr			(~rstn),		
		.data			(data_out_d2),
		.rdclk			(clk),
		.rdreq			(payload_req1),	
		.wrclk			(data_clk),
		.wrreq			(data_valid_1),
		.q				(txFIFO_data1),
		.rdusedw		(txFIFO_words1),
		.rdempty		(),
		.wrfull			(txFIFO_full1));
`endif		
	

	reg				txFIFO_rdy;
	
	always @(`CLK_RST_EDGE)
		if (`RST)	txFIFO_rdy <= 0;
		else		txFIFO_rdy <= txFIFO_words > PAYLOAD_LEN_MAX  || fifo_frame_done;

	reg				last_packet_in_frame;
	reg		[10:0]	payload_length;
	reg 	[10:0] 	payload_req_cnt;
	wire  			payload_req_last = (payload_req_cnt == payload_length - 1);
	
	always @ (`CLK_RST_EDGE)
		if (`RST)             					payload_req_cnt <= 0;
		else if (payload_req) 					payload_req_cnt <= payload_req_cnt + 1;
		else									payload_req_cnt <= 0;	
	
	
	//go	+|
	//max_f  					 +|
	//en	 |++++++++++++++++++++|
	//cnt	 |0..............MAX-1| MAX		
	reg					cnt_interval_e;
	reg		[ 10 :0]	cnt_interval;
	wire				cnt_interval_max_f = cnt_interval == (1024+512)-1;
	
	reg		[ 2:0] 		st_ether_tx;
	wire				st_ether_tx_go = !cnt_interval_e & txFIFO_rdy;

	always @(`CLK_RST_EDGE)
		if (`RST)						cnt_interval_e <= 0;
		else if (st_ether_tx_go)		cnt_interval_e <= 1;
		else if (cnt_interval_max_f)	cnt_interval_e <= 0;
	always @(`CLK_RST_EDGE)
		if (`RST)	cnt_interval <= 0;
		else 		cnt_interval <= cnt_interval_e? cnt_interval + 1 : 0;
	
	always @(`CLK_RST_EDGE)
		if (`RST)								payload_length <= 0;
		else if (st_ether_tx_go) begin		
			if (txFIFO_words > PAYLOAD_LEN_MAX)	payload_length <= PAYLOAD_LEN;
			else 								payload_length <= txFIFO_words;
		end
	always @(`CLK_RST_EDGE)
		if (`RST)								last_packet_in_frame <= 0;
		else if (st_ether_tx_go) begin		
			if (txFIFO_words > PAYLOAD_LEN_MAX)	last_packet_in_frame <= 0;
			else 								last_packet_in_frame <= 1;
		end

	reg					frame_send_ready;				
	reg					packet_ready;				
	reg		[ 6:0] 		cnt_header;
	reg		[ 7:0]		_txd;
	reg		[ 7:0]		txd;
	reg					reset_crc;
	reg		[ 1:0]		cnt_crc;
	reg					calc_crc_f;
	
	always @ (`CLK_RST_EDGE)
		if (`ZST) 	reset_crc <= 0;
		else      	reset_crc <= (S0 == st_ether_tx);
	always @ (`CLK_RST_EDGE)
		if (`RST)                  		cnt_crc <= 0;
		else if (S5 == st_ether_tx)		cnt_crc <= cnt_crc + 1;
	always @ (`CLK_RST_EDGE)
		if (`RST)                  		calc_crc_f <= 0;
		else if (8 == cnt_header) 		calc_crc_f <= 1;
		else if (S4 == st_ether_tx)		calc_crc_f <= 0;
		
	always @ (`CLK_RST_EDGE)
		if (`RST) st_ether_tx <= S0;
		else
			case (st_ether_tx)
			S0: if (st_ether_tx_go) 				st_ether_tx <= S1;
			S1: if (MAX_CNT_HEADER-1 == cnt_header) st_ether_tx <= S2;	// header
			S2: if (payload_req_last) 				st_ether_tx <= S3;	// payload data
			S3:                                   	st_ether_tx <= S4;
			S4:                                   	st_ether_tx <= S5;
			S5: if (3 == cnt_crc) 					st_ether_tx <= S7;	// CRC
			S7:                                   	st_ether_tx <= S0;
			endcase
	
	always @ (`CLK_RST_EDGE)
		if (`RST) 	cnt_header <= 0;
		else      	cnt_header <= (S1 == st_ether_tx) ? cnt_header + 1 : 0;
	always @ (`CLK_RST_EDGE)
		if (`RST)                                  	payload_req <= 0;
		else if (MAX_CNT_HEADER - 2 == cnt_header)	payload_req <= 1;
		else if (payload_req_last)					payload_req <= 0;
	always @(`CLK_RST_EDGE)
		if (`RST)						fifo_rid <= 0;
		else if (frame_send_ready)		fifo_rid <= fifo_rid + 1;
		
	always @(`CLK_RST_EDGE)
		if (`RST)	packet_ready <= 0;
		else 		packet_ready <= st_ether_tx==S7;
	
	always @(`CLK_RST_EDGE)
		if (`RST)	frame_send_ready <= 0;
		else 		frame_send_ready <= packet_ready && fifo_frame_done && txFIFO_words==0;
	always @(`CLK_RST_EDGE)
		if (`RST)							fifo0_frame_done <= 0;
		else if (fifo0_frame_done_set)		fifo0_frame_done <= 1;
		else if (frame_send_ready&!fifo_rid)fifo0_frame_done <= 0;
	always @(`CLK_RST_EDGE)
		if (`RST)							fifo1_frame_done <= 0;
		else if(fifo1_frame_done_set)		fifo1_frame_done <= 1;	
		else if (frame_send_ready&fifo_rid)	fifo1_frame_done <= 0;
		
	Preamble  	pre_amble;
	MacHeader 	mac_header;
    IpHeader 	ip_header;
    UdpHeader 	udp_header;
	RtpHeader	rtp_header;
	JpegHeader	jpeg_header;
	
	wire		[0:MAX_CNT_HEADER-1][7:0]	headers = {pre_amble, mac_header, ip_header, udp_header, rtp_header, jpeg_header};
	assign pre_amble = 64'h55_55_55_55_55_55_55_d5;
	assign mac_header = '{`MAC_ADDR_BROADCAST, `MAC_ADDR_NOBROADCAST, `ETHER_FRAME_TYPE};
	assign ip_header.ipVersion			= 4'd4;
	assign ip_header.ipHdrLen 			= 4'd5;
	assign ip_header.ipDiffServ	 	  	= 8'h0;
	// assign ip_header.ipLen			  	= 16'h0;			//  include ip_header udp_header rtp_header jpeg_header playload
	// assign ip_header.ipId			  	= 16'h0;           // increase one very packet
	assign ip_header.ipFlags		 	= 3'b010;
	assign ip_header.ipFragOffset	 	= 13'h0;
	assign ip_header.ipTTL			 	= 8'h80;
	assign ip_header.ipProtocol	 	  	= 8'd17;
	// assign ip_header.ipChecksum	 	= 8'd17;			  // include 	ipSrcAddr and 	ipDstAddr		
	assign ip_header.ipSrcAddr		 	= `IP_SRC_ADDR;
	assign ip_header.ipDstAddr		 	= `IP_DST_ADDR;
	//==========================================================
	assign udp_header.udpSrcPort	 	= `UDP_SRC_PORT;
	assign udp_header.udpDstPort	 	= `UDP_DST_PORT;
	//assign udp_header.udpLen		 	= `UDP_DST_PORT;    // udp length include udp_header rtp_header jpeg_header playload
	assign udp_header.udpChecksum	 	= 16'h0000;
	//==========================================================
	assign rtp_header.V		 	  		= 2'h2;
	assign rtp_header.P		 	  		= 0;
	assign rtp_header.X		 	  		= 0;
	assign rtp_header.CC		 	  	= 0;
	//assign rtp_header.M		 	  		= 0;		// last packet in a frame 1
	assign rtp_header.PT		 	  	= 26;
	//assign rtp_header.sequenceNumber  	= 16'h00;   // increase one for very packet
	//assign rtp_header.timeStamp	  	= 32'h0;		// increase  90000/FPS very frame
	assign rtp_header.SSRC			  	= 32'h00_00_00_00;
	//==========================================================
	assign jpeg_header.typeSpecific  	= 0;
	//assign jpeg_header.fragmentOffset  = 0;    // + 1024 for a packet in frame, reset for a new frame
`ifdef YUV444_ONLY
	################ ERROR RTP dont support yuv444################
`elsif YUV422_ONLY
	assign jpeg_header.typeJpeg  		= 0;	// 0: YUV422, 1: YUV420
`endif
	assign jpeg_header.Q		  		= 50;	
	assign jpeg_header.width	  		= PicWidth_i>>3;
	assign jpeg_header.height	  		= PicHeight_i>>3;

	//=========================================
	always @ (`CLK_RST_EDGE)
		if (`RST)         		ip_header.ipLen <= 0;
		else 					ip_header.ipLen <= udp_header.udpLen + `IP_HEADER_LENGTH;
	always @ (`CLK_RST_EDGE)
		if (`RST)         		ip_header.ipId <= 0;
		else if (packet_ready) 	ip_header.ipId <= ip_header.ipId + 1;
	
	reg							ipChecksum_e;
	reg							init_ipChecksum;
	reg					[19:0]	ipChecksum_s1;
	always @ (`CLK_RST_EDGE)
		if (`ZST) 	init_ipChecksum <= 0;
		else      	init_ipChecksum <= (1 == cnt_header);
	always @ (`CLK_RST_EDGE)
		if (`ZST) 	ipChecksum_e <= 0;
		else      	ipChecksum_e <= (22 == cnt_header|| 24 == cnt_header|| 26 == cnt_header|| 28 == cnt_header|| 30 == cnt_header);
	wire	[19:0]	ipChecksum_s0 = ip_header.ipSrcAddr[31-:16] + ip_header.ipSrcAddr[15-:16] +
	                                ip_header.ipDstAddr[31-:16] + ip_header.ipDstAddr[15-:16];
	always @ (`CLK_RST_EDGE)
		if (`ZST)                 	ipChecksum_s1 <= 0;
		else if (init_ipChecksum)	ipChecksum_s1 <= ipChecksum_s0;
		else if (ipChecksum_e)		ipChecksum_s1 <= ipChecksum_s1 + {txd, _txd};
	always @(*) ip_header.ipChecksum = ~(ipChecksum_s1[19:16] + ipChecksum_s1[15:0]);
	
	always @ (`CLK_RST_EDGE)
		if (`RST)         		udp_header.udpLen <= 0;
		else 					udp_header.udpLen <= `UDP_HEADER_LENGTH + `RTP_HEADER_LENGTH + `JPEG_HEADER_LENGTH + payload_length;
	
	always @ (`CLK_RST_EDGE)
		if (`RST)  	rtp_header.M <= 0;
		else 		rtp_header.M <= last_packet_in_frame;
	always @(*)
		rtp_header.sequenceNumber = ip_header.ipId;
	// always @ (`CLK_RST_EDGE)
		// if (`RST)         			rtp_header.sequenceNumber <= 0;
		// else if (packet_ready) 		rtp_header.sequenceNumber <= rtp_header.sequenceNumber + 1;
	always @ (`CLK_RST_EDGE)
		if (`RST)         			rtp_header.timeStamp <= 0;
		else if (frame_send_ready) 	rtp_header.timeStamp <= rtp_header.timeStamp + FRAME_INTERVAL;
	always @ (`CLK_RST_EDGE)
		if (`RST)         			jpeg_header.fragmentOffset <= 0;
		else if (frame_send_ready) 	jpeg_header.fragmentOffset <= 0;
		else if (packet_ready)		jpeg_header.fragmentOffset <= jpeg_header.fragmentOffset + PAYLOAD_LEN;
	
	//================================================================================
	
	always @(*)
		_txd = headers[cnt_header];
		
	always @ (`CLK_RST_EDGE)
		if (`ZST) 	txd <= 0;
		else      	txd <= (S1 == st_ether_tx) ?  _txd : txFIFO_data;
	wire				[31:0]	crc;
	reg		[7:0]		txd_crc;
	always @ (`CLK_RST_EDGE)
		if (`ZST) 	txd_crc <= 0;
		else
			case(cnt_crc[1:0])
			0: txd_crc <= {~crc[24], ~crc[25], ~crc[26], ~crc[27], ~crc[28], ~crc[29], ~crc[30], ~crc[31]};
			1: txd_crc <= {~crc[16], ~crc[17], ~crc[18], ~crc[19], ~crc[20], ~crc[21], ~crc[22], ~crc[23]};
			2: txd_crc <= {~crc[ 8], ~crc[ 9], ~crc[10], ~crc[11], ~crc[12], ~crc[13], ~crc[14], ~crc[15]};
			3: txd_crc <= {~crc[ 0], ~crc[ 1], ~crc[ 2], ~crc[ 3], ~crc[ 4], ~crc[ 5], ~crc[ 6], ~crc[ 7]};
			endcase
	reg		[7:0]		txd_d1;
	always @(`CLK_RST_EDGE)
		if (`ZST)	txd_d1 <= 0;
		else 		txd_d1 <= txd;
	reg		[0:0]		st_ether_tx_go_d1, st_ether_tx_go_d2;
	always @(`CLK_RST_EDGE)
		if (`ZST)	{st_ether_tx_go_d1, st_ether_tx_go_d2} <= 0;
		else 		{st_ether_tx_go_d1, st_ether_tx_go_d2} <= {st_ether_tx_go, st_ether_tx_go_d1};
	reg		tx_en;
	reg		trans_crc;
	reg		crc_rdy;
	always @ (`CLK_RST_EDGE)
		if (`ZST) 	crc_rdy <= 0;
		else      	crc_rdy <= (3 == cnt_crc);
		
	always @ (`CLK_RST_EDGE)
		if (`RST)                  	tx_en <= 0;
		else if (st_ether_tx_go_d2)	tx_en <= 1;
		else if (crc_rdy)			tx_en <= 0;		
	always @ (`CLK_RST_EDGE)
		if (`ZST) 	trans_crc <= 0;
		else      	trans_crc <= (S5 == st_ether_tx);
		
	wire						_gmii_tx_en = tx_en;
	wire				[ 7:0]  _gmii_txd   = trans_crc ? txd_crc : txd_d1;
	
	
	reg					[ 7:0]	gmii_txd_b1;
	reg							gmii_tx_en_b1;
	always @ (`CLK_RST_EDGE)
		if (`ZST) 	{gmii_txd_b1, gmii_tx_en_b1} <= 0;
		else      	{gmii_txd_b1, gmii_tx_en_b1} <= {_gmii_txd, _gmii_tx_en};
	always @ (`CLK_RST_EDGE)
		if (`ZST) 	{gmii_txd, gmii_tx_en} <= 0;
		else      	{gmii_txd, gmii_tx_en} <= {gmii_txd_b1, gmii_tx_en_b1};
		
		
	ether_crc32 ethcrc (
		.clk			(clk),
		.rstn			(rstn),
		.reset_crc		(reset_crc),
		.calc_crc_f		(calc_crc_f),
		.txd			(txd),
		.crc			(crc));
endmodule

module ether_crc32 (
	input					clk,
	input					rstn,
	input					reset_crc,
	input					calc_crc_f,
	input			[ 7:0]	txd,
	output reg		[31:0]	crc
	);
	
	reg				[31:0]	tmp_crc;
	wire			[31:0]	C = crc;
	wire			[ 7:0]	D = txd;

	always @ (`CLK_RST_EDGE)
		if (`RST)            	crc <= 32'hFFFFFFFF;
		else if (reset_crc) 	crc <= 32'hFFFFFFFF;
		else if (calc_crc_f)	crc <= tmp_crc;
	always @(*) begin
	    tmp_crc[ 0] = C[24]^C[30]^D[ 1]^D[ 7];
	    tmp_crc[ 1] = C[25]^C[31]^D[ 0]^D[ 6]^C[24]^C[30]^D[ 1]^D[ 7];
	    tmp_crc[ 2] = C[26]^D[ 5]^C[25]^C[31]^D[ 0]^D[ 6]^C[24]^C[30]^D[ 1]^D[ 7];
	    tmp_crc[ 3] = C[27]^D[ 4]^C[26]^D[ 5]^C[25]^C[31]^D[ 0]^D[ 6];
	    tmp_crc[ 4] = C[28]^D[ 3]^C[27]^D[ 4]^C[26]^D[ 5]^C[24]^C[30]^D[ 1]^D[ 7];
	    tmp_crc[ 5] = C[29]^D[ 2]^C[28]^D[ 3]^C[27]^D[ 4]^C[25]^C[31]^D[ 0]^D[ 6]^C[24]^C[30]^D[ 1]^D[ 7];
	    tmp_crc[ 6] = C[30]^D[ 1]^C[29]^D[ 2]^C[28]^D[ 3]^C[26]^D[ 5]^C[25]^C[31]^D[ 0]^D[ 6];
	    tmp_crc[ 7] = C[31]^D[ 0]^C[29]^D[ 2]^C[27]^D[ 4]^C[26]^D[ 5]^C[24]^D[ 7];
	    tmp_crc[ 8] = C[ 0]^C[28]^D[ 3]^C[27]^D[ 4]^C[25]^D[ 6]^C[24]^D[ 7];
	    tmp_crc[ 9] = C[ 1]^C[29]^D[ 2]^C[28]^D[ 3]^C[26]^D[ 5]^C[25]^D[ 6];
	    tmp_crc[10] = C[ 2]^C[29]^D[ 2]^C[27]^D[ 4]^C[26]^D[ 5]^C[24]^D[ 7];
	    tmp_crc[11] = C[ 3]^C[28]^D[ 3]^C[27]^D[ 4]^C[25]^D[ 6]^C[24]^D[ 7];
	    tmp_crc[12] = C[ 4]^C[29]^D[ 2]^C[28]^D[ 3]^C[26]^D[ 5]^C[25]^D[ 6]^C[24]^C[30]^D[ 1]^D[ 7];
	    tmp_crc[13] = C[ 5]^C[30]^D[ 1]^C[29]^D[ 2]^C[27]^D[ 4]^C[26]^D[ 5]^C[25]^C[31]^D[ 0]^D[ 6];
	    tmp_crc[14] = C[ 6]^C[31]^D[ 0]^C[30]^D[ 1]^C[28]^D[ 3]^C[27]^D[ 4]^C[26]^D[ 5];
	    tmp_crc[15] = C[ 7]^C[31]^D[ 0]^C[29]^D[ 2]^C[28]^D[ 3]^C[27]^D[ 4];
	    tmp_crc[16] = C[ 8]^C[29]^D[ 2]^C[28]^D[ 3]^C[24]^D[ 7];
	    tmp_crc[17] = C[ 9]^C[30]^D[ 1]^C[29]^D[ 2]^C[25]^D[ 6];
	    tmp_crc[18] = C[10]^C[31]^D[ 0]^C[30]^D[ 1]^C[26]^D[ 5];
	    tmp_crc[19] = C[11]^C[31]^D[ 0]^C[27]^D[ 4];
	    tmp_crc[20] = C[12]^C[28]^D[ 3];
	    tmp_crc[21] = C[13]^C[29]^D[ 2];
	    tmp_crc[22] = C[14]^C[24]^D[ 7];
	    tmp_crc[23] = C[15]^C[25]^D[ 6]^C[24]^C[30]^D[ 1]^D[ 7];
	    tmp_crc[24] = C[16]^C[26]^D[ 5]^C[25]^C[31]^D[ 0]^D[ 6];
	    tmp_crc[25] = C[17]^C[27]^D[ 4]^C[26]^D[ 5];
	    tmp_crc[26] = C[18]^C[28]^D[ 3]^C[27]^D[ 4]^C[24]^C[30]^D[ 1]^D[ 7];
	    tmp_crc[27] = C[19]^C[29]^D[ 2]^C[28]^D[ 3]^C[25]^C[31]^D[ 0]^D[ 6];
	    tmp_crc[28] = C[20]^C[30]^D[ 1]^C[29]^D[ 2]^C[26]^D[ 5];
	    tmp_crc[29] = C[21]^C[31]^D[ 0]^C[30]^D[ 1]^C[27]^D[ 4];
	    tmp_crc[30] = C[22]^C[31]^D[ 0]^C[28]^D[ 3];
	    tmp_crc[31] = C[23]^C[29]^D[ 2];
	end

endmodule

module jpeg_feeder(
	input 					 		clk,
	input 					 		rstn,
	input							cam_vsync_i,
	input		[31:0]				MBs_in8,
	output reg 	                    data_valid,
    output reg 	       [ 7:0]       data_out, 	
	output reg						pic_ready


	);

	reg		[7:0]	cam_vsync_i_d;
	always @(*)	cam_vsync_i_d[0] = cam_vsync_i;
	always @(`CLK_RST_EDGE)
		if (`RST)	cam_vsync_i_d[7:1] <= 0;
		else 		cam_vsync_i_d[7:1] <= cam_vsync_i_d;
		
	wire 		pic_start_f = !cam_vsync_i_d[2] & cam_vsync_i_d[3];
	
	reg	 	frame_e;
	reg 	frame_ready;
	wire 	go_data;
	
	always @(`CLK_RST_EDGE)
		if (`RST)				frame_e <= 0;
		else if (pic_start_f)	frame_e <= 1;
		else if (frame_ready)	frame_e <= 0;
	reg		[31:0]	cnt_8MBs;
	always @(`CLK_RST_EDGE)
		if (`RST)				cnt_8MBs <= 0;
		else if (pic_start_f)	cnt_8MBs <= 0;
		else if (pic_ready)		cnt_8MBs <= 0;
		else if (go_data)		cnt_8MBs <= cnt_8MBs + 1;
	always @(`CLK_RST_EDGE)
		if (`RST)	frame_ready <= 0;
		else 		frame_ready <= cnt_8MBs == MBs_in8;
	//go	+|
	//max_f  					 +|
	//en	 |++++++++++++++++++++|
	//cnt	 |0..............MAX-1| MAX		
	reg					cnt_interval_e;
	reg		[ 9 :0]		cnt_interval;
	wire				cnt_interval_max_f = cnt_interval == (1024-1);
	always @(`CLK_RST_EDGE)
		if (`RST)						cnt_interval_e <= 0;
		else if (go_data)				cnt_interval_e <= 1;
		else if (cnt_interval_max_f)	cnt_interval_e <= 0;
	
	always @(`CLK_RST_EDGE)
		if (`RST)	cnt_interval <= 0;
		else 		cnt_interval <= cnt_interval_e? cnt_interval + 1 : 0;
		
	assign go_data = !cnt_interval_e & frame_e;
	
	//go	+|
	//max_f  					 +|
	//en	 |++++++++++++++++++++|
	//cnt	 |0..............MAX-1| MAX		
	reg					cnt_data_e;
	reg		[ 7 :0]		cnt_data;
	wire				cnt_data_max_f = cnt_data == 20-1;
	always @(`CLK_RST_EDGE)
		if (`RST)					cnt_data_e <= 0;
		else if (go_data)			cnt_data_e <= 1;
		else if (cnt_data_max_f)	cnt_data_e <= 0;
	
	always @(`CLK_RST_EDGE)
		if (`RST)	cnt_data <= 0;
		else 		cnt_data <= cnt_data_e? cnt_data + 1 : 0;
	
	wire	[0:19][7:0]	bytes_8MB = {8'h28, 8'hA0, 8'h02, 8'h8A, 8'h00,
									8'h28, 8'hA0, 8'h02, 8'h8A, 8'h00,
									8'h28, 8'hA0, 8'h02, 8'h8A, 8'h00,
									8'h28, 8'hA0, 8'h02, 8'h8A, 8'h00 };
									
	always @(`CLK_RST_EDGE)
		if (`RST)	data_valid <= 0;
		else 		data_valid <= cnt_data_e;
	always @(`CLK_RST_EDGE)
		if (`RST)	data_out <= 0;
		else 		data_out <= bytes_8MB[cnt_data];
	
	always @(`CLK_RST_EDGE)
		if (`RST)	pic_ready <= 0;
		else 		pic_ready <= cnt_data_max_f & frame_ready;

endmodule