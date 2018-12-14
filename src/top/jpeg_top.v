`include "jpeg_global.v"

`define W_HDMITX 23


`ifdef FPGA_0_ALTERA
    `define LED_INIT_VALUE          1'b1
    `define LED_POL                 ~
`else
    `define LED_INIT_VALUE          1'b0
    `define LED_POL         		
`endif

module system_top(
	`ifdef FPGA_0_XILINX
		input							clk_ref_i_p,
		input							clk_ref_i_n,
	`else
		input                           clk_ref_i,       
	`endif    
	`ifdef FPGA_0_XILINX
		input                           rst_i,           
	`else
		input                           rstn_i,          
	`endif
	
	input	                      	vi_clk,
    input	                      	vi_vsync,
    input	                      	vi_hsync,
    input	                      	vi_de,
	input		  [`W_HDMITX:0]     vi_data, 
	
	output                          ether_phy_rst_n,  
`ifdef MAC_SGMII
	input							sgmii_625MHZ_P,
	input							sgmii_625MHZ_N,
    input                           sgmii_rxp,
    input                           sgmii_rxn,
    output                          sgmii_txp,
    output                          sgmii_txn,
`else
	output                          gmii_tx_clk,
	output          [ 7:0]          gmii_txd,
	output                          gmii_tx_en,
	output						  	gmii_tx_er,	
`endif
	output reg                      LED0,
    output reg                      LED1,
    output reg                      LED2,
    output reg                      LED3,
    output reg                      LED4,
    output reg                      LED5,
    output reg                      LED6,
    output reg                      LED7
	);

	
	`ifdef FPGA_0_XILINX
		wire		rstn_i = ~rst_i;
		wire							clk_ref;
		IBUFDS clkin1_ibufgds(	
			.O  (clk_ref),
			.I  (clk_ref_i_p),
			.IB (clk_ref_i_n)
			);
		wire						pll_main_locked;
		wire						p0_c0, p0_c1;
(* DONT_TOUCH = "true" *)		wire  						clk = p0_c1;	
(* DONT_TOUCH = "true" *)		wire  						ee_clk = p0_c0;	
		pll_main pll_main(
			.clk_in1	(clk_ref),
			.clk_out1	(p0_c0),					// 300M
			.clk_out2	(p0_c1),					// 250M
			.locked		(pll_main_locked)
			);
	`else
		wire                            clk_ref = clk_ref_i;
	`endif
(* DONT_TOUCH = "true" *)  wire   rstn;	
	dlyRst # (.W_CNTRST(24)) dlyRst0 (.clk(clk_ref), .rstn_i(rstn_i&pll_main_locked),  .rstn(rstn));

	//wire	clk = vi_clk;
	wire	cam_clk = vi_clk;
	
	reg	[7:0]	vi_vsync_d;
	always @(*)	vi_vsync_d[0] = vi_vsync;
	always @(posedge cam_clk)
		if (`RST)	vi_vsync_d[7:1] <= 0;
		else 		vi_vsync_d[7:1] <= vi_vsync_d;
	reg	[7:0]	vi_hsync_d;
	always @(*)	vi_hsync_d[0] = vi_hsync;
	always @(posedge cam_clk)
		if (`RST)	vi_hsync_d[7:1] <= 0;
		else 		vi_hsync_d[7:1] <= vi_hsync_d;
	reg	[7:0]	vi_de_d;
	always @(*)	vi_de_d[0] = vi_de;
	always @(posedge cam_clk)
		if (`RST)	vi_de_d[7:1] <= 0;
		else 		vi_de_d[7:1] <= vi_de_d;
		
	reg	[7:0][`W_HDMITX:0]	vi_data_d;
	always @(*)	vi_data_d[0] = vi_data;
	always @(posedge cam_clk)
		if (`RST)	vi_data_d[7:1] <= 0;
		else 		vi_data_d[7:1] <= vi_data_d;
	
`ifdef CAM444_TO_422
	reg						cam_href ;
	reg						cam_hsync;
	reg						cam_vsync;
	reg		[`W_CAMD_I:0]	cam_data;
	
	reg						cam_href_b1 ;
	reg						cam_hsync_b1;
	reg						cam_vsync_b1;
	reg		[`W_CAMD_I:0]	cam_data_b1;

	reg						uv422_sel, uv422_sel_d1;
	reg		[`W1:0]			yuv444_data_Y;
	reg		[`W1:0]			yuv444_data_U;
	reg		[`W1:0]			yuv444_data_V;
	
	// data  YUV  
	//		cam_data_b1  
	always @(posedge cam_clk )
		if(!vi_de_d[1])		uv422_sel <= 0;
		else if(vi_de_d[1])	uv422_sel <= ~uv422_sel;	
	always @(posedge cam_clk)
			yuv444_data_Y <= vi_data_d[1][ 7: 0];
	always @(posedge cam_clk)
		if(!uv422_sel)		yuv444_data_U <= vi_data_d[1][15:8];
	always @(posedge cam_clk)
		if(!uv422_sel)		yuv444_data_V <= vi_data_d[1][23:16];
	always @(posedge cam_clk)
							uv422_sel_d1 <= uv422_sel;
	always @(*)
		cam_data_b1 = !uv422_sel_d1? {yuv444_data_U, yuv444_data_Y} : {yuv444_data_V, yuv444_data_Y};	
		
	 always @(posedge cam_clk) begin
            cam_vsync_b1 <= vi_vsync_d[1];
            cam_hsync_b1 <= vi_hsync_d[1];
            cam_href_b1 <= vi_de_d[1];     
        end 	
	always @(posedge cam_clk) begin
		cam_vsync <= cam_vsync_b1;				// vsync_pol ? ~cam_vsync_b1 : cam_vsync_b1;
		cam_hsync <= cam_hsync_b1;
		cam_href <= cam_href_b1;
		cam_data <= cam_data_b1;
	end 
`else	
	wire					cam_href = 	vi_de_d[1];
	wire					cam_vsync = vi_vsync_d[1];
	wire					cam_hsync = vi_hsync_d[1];
	wire	[`W_CAMD_I:0]	cam_data = vi_data_d[1];
`endif	

(* mark_debug = "true" *)	wire  		[7:0]             	data_out;
(* mark_debug = "true" *)   wire                 	  		data_valid;
(* mark_debug = "true" *)	wire							pic_ready;
	wire						err_sensor_too_fast;
	wire						err_eefifo_overflow;
`ifdef WITH_JPEG_FEEDER
	wire     	[`W_PW:0]  			PicWidth = 352;
    wire     	[`W_PH:0]  			PicHeight = 288;	
	jpeg_feeder jpeg_feeder(
		.clk			(ee_clk),
		//.clk			(clk),
		.rstn			(rstn),
		.cam_vsync_i	(cam_vsync),
		//.MBs_in8		(1920*1080/1024),
		//.MBs_in8		(32'd2025),
		//.MBs_in8		(352*288/1024),
		.MBs_in8		(99),
	
		.data_valid		(data_valid),
		.data_out		(data_out),
		.pic_ready		(pic_ready)
	);
`else
	wire     	[`W_PW:0]  			PicWidth = 1920;
    wire     	[`W_PH:0]  			PicHeight = 1080;	

	jpeg_enc jpeg_enc(
		.clk			(clk),
		.rstn			(rstn),
		.encoder_active	(1'b1),	
		
		.ee_clk			(ee_clk),
		.rstn_ee		(rstn),	
		
		.cam_clk		(cam_clk),
		.rstn_cam		(rstn),
		
		.cam_vsync_i	(cam_vsync),
		.cam_href_i		(cam_href),
		.cam_data_i		(cam_data),	
		
		.PicWidth_i		(PicWidth),	
		.PicHeight_i	(PicHeight),	
		.err_sensor_too_fast	(err_sensor_too_fast),
		.err_eefifo_overflow	(err_eefifo_overflow),
		.data_valid		(data_valid),
		.data_out		(data_out),
		.pic_ready		(pic_ready)
	);
`endif
	
`ifdef MAC_SGMII
(* mark_debug = "true" *)	wire		[ 7:0]          gmii_txd;
(* mark_debug = "true" *)	wire						gmii_tx_en;
	wire						gmii_tx_er;
	wire						clk125_out;
	wire			ether_clk = clk125_out;
	Xilinx_SGMII gm2sgm(
		.refclk625_p	(sgmii_625MHZ_P),
		.refclk625_n	(sgmii_625MHZ_N),
		.txp			(sgmii_txp),
		.txn			(sgmii_txn),
		.rxp            (sgmii_rxp),
		.rxn            (sgmii_rxn),
		.reset			(~rstn),
		.signal_detect 	(1'b1),
		.clk125_out		(clk125_out), 
		.speed_is_10_100(1'b0),
		.speed_is_100	(1'b0),
		.configuration_vector(5'b10000),
	//	.configuration_valid	(1'b0),
		.status_vector	(status_vector),
		.an_adv_config_vector	(16'hd801),  //  in PHY mode 
		.an_restart_config	(1'b0),
		.gmii_txd		(gmii_txd),
		.gmii_tx_en		(gmii_tx_en),
		.gmii_tx_er		(1'b0)
	);
`endif
	assign ether_phy_rst_n = rstn;
	gether_mac_tx gether_mac_tx(
		.clk				(ether_clk),
		.rstn				(rstn),
		.PicWidth_i			(PicWidth),
		.PicHeight_i		(PicHeight),
		.data_clk			(ee_clk),
		//.data_clk			(clk),
		.data_valid			(data_valid),
		.data_out			(data_out),
		.data_frame_ready	(pic_ready),
		.eth_fifo_full		(eth_fifo_full),
		.gmii_txd			(gmii_txd),
		.gmii_tx_en			(gmii_tx_en),
		.gmii_tx_er			(gmii_tx_er)
		);
	
	always @(posedge cam_clk or negedge rstn) 
        if (!rstn) LED4 <= `LED_INIT_VALUE;
        else       LED4 <= `LED_POL vi_vsync_d[1];
	always @(posedge ee_clk or negedge rstn) 
        if (!rstn) LED0 <= `LED_INIT_VALUE;
        else       LED0 <= `LED_POL data_valid;
	always @(posedge ee_clk or negedge rstn) 
        if (!rstn) 					LED1 <= `LED_INIT_VALUE;
        else if (pic_ready)         LED1 <= ~LED1;	
	always @(posedge ee_clk or negedge rstn) 
        if (!rstn) 					LED2 <= `LED_INIT_VALUE;
        else						LED2 <= `LED_POL eth_fifo_full;
	always @(posedge ee_clk or negedge rstn) 
        if (!rstn) 					LED5 <= `LED_INIT_VALUE;
        else 						LED5 <= `LED_POL err_eefifo_overflow;	
	always @(posedge clk or negedge rstn) 
        if (!rstn) 					LED6 <= `LED_INIT_VALUE;
        else 						LED6 <= `LED_POL err_sensor_too_fast;	

endmodule


	
module dlyRst  #  
	(
	parameter  W_CNTRST    =  16
	)
	(
	input			clk,
	input			rstn_i,
	output reg		rstn
	);
	reg		rstn_b2, rstn_b1; 
	`ifdef SIMULATING	
    	reg                 [ 3:0]  reset_cnt;				
		wire						reset_cnt_end = ( 4'hF            == reset_cnt);
	`else
    	reg         [W_CNTRST-1:0]  reset_cnt;				
		wire						reset_cnt_end = ({W_CNTRST{1'b1}} == reset_cnt);
	`endif
    always @(posedge clk or negedge rstn_i) 
        if (!rstn_i)           		reset_cnt <= 0;
        else if (!reset_cnt_end)	reset_cnt <= reset_cnt + 1;
    always @(posedge clk or negedge rstn_i)
    	if (!rstn_i)	{rstn_b2, rstn_b1, rstn} <= 0;
		else 			{rstn_b2, rstn_b1, rstn} <= {reset_cnt_end, rstn_b2, rstn_b1};
endmodule

