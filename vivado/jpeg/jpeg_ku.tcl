

set outputDir ./tcl_output
file mkdir $outputDir
set_part xcku060-ffva1156-2-e
#set_part xcku040-ffva1156-2-e

set_property XPM_LIBRARIES {XPM_CDC XPM_MEMORY} [current_project]

set top_design system_top
# STEP#1: setup design sources and constraints
set INCLUDES { ../../common/src  ../src  ../../src}

set GENERATE_NETLIST 	"0"
set GENERATE_EDN	 	"0"
set WITH_DEBUG_CORE	 	"0"



set CAM_CLK_PORT 			{vi_clk} 
set CLK_PORT 				{clk}
set CLK_REF_PORT 			{clk_ref}
set DDR_UI_CLK				{xddrc_ui_clk}
set EE_CLK_PORT 			{ee_clk}
set ETHER_CLK_PORT 			{ether_clk}


set CLK_REF_PERIOD			3.33
set CLK_PERIOD				5          
set EE_CLK_PERIOD			3.33         
set CAM_CLK_PERIOD	 		6.73
# set CAM_CLK_PERIOD	 		3.33
set DDR_UI_CLK_PERIOD		3.33
set ETHER_CLK_PERIOD		8

set DEFINES	" FPGA_0_XILINX"

append	DEFINES " YUV422_ONLY"
append	DEFINES " WITH_ETHER_RTP_TX"
append	DEFINES " MAC_SGMII"
append	DEFINES " CAM444_TO_422"
#append	DEFINES " WITH_JPEG_FEEDER"


read_verilog -sv ../../src/top/jpeg_top.v
read_verilog -sv ../../src/camera.v
read_verilog -sv ../../src/fdct8.v
read_verilog -sv ../../src/quant.v
read_verilog -sv ../../src/fdct_quant.v
read_verilog -sv ../../src/jpeg.v
read_verilog -sv ../../src/ee_roms.v
read_verilog -sv ../../src/entropy_encoder.v
read_verilog -sv ../../src/bitstream.v
read_verilog -sv ../../src/misc.v
read_verilog -sv ../../src/ethernet.v



read_verilog -sv ../../model/xilinx/xilinx_1p_sram.v
read_verilog -sv ../../model/xilinx/xilinx_1w1r_sram.v
read_verilog -sv ../../model/xilinx/xilinx_1w1r_sram_wp8.v
read_verilog -sv ../../model/xilinx/xilinx_srams.v


read_ip  ../../model/xilinx/fifo/fifo_4096x8/fifo_4096x8.xci
read_ip  ../../model/xilinx/ku/pll/pll_main_250/pll_main.xci

read_ip ../../../../work/ise/ultrascale/xiinx_GEther_PHY_AN/xiinx_GEther.xci
read_ip ../../../../work/ise/ultrascale16.4/Xilinx_SGMII.xcix


read_xdc 	./ku_HPC_TB_FMCH_HDMI2.xdc


set fp [open $outputDir/syndefines.v w]
puts $fp "$DEFINES"
close $fp

if { $GENERATE_NETLIST==1 } {
	synth_design -top $top_design  -verilog_define $DEFINES  -include_dirs $INCLUDES -flatten_hierarchy none 
	#write_verilog -cell jpeg_enc -mode funcsim -force $outputDir/post_synth_netlist.v
	write_verilog -cell gether_mac_tx -mode funcsim -force $outputDir/post_synth_netlist.v
	write_verilog -cell jpeg_feeder -mode funcsim -force $outputDir/jpeg_feeder_netlist.v
#	write_verilog -cell vj -mode funcsim -force $outputDir/vj.v
	quit
} else {
	synth_design -top $top_design  -verilog_define $DEFINES  -include_dirs $INCLUDES -flatten_hierarchy rebuilt
}


create_clock -period $CLK_PERIOD           	-name $CLK_PORT              	[get_nets $CLK_PORT]
create_clock -period $CAM_CLK_PERIOD 		-name $CAM_CLK_PORT          	[get_nets $CAM_CLK_PORT]
create_clock -period $CLK_REF_PERIOD       	-name $CLK_REF_PORT             [get_nets $CLK_REF_PORT]
create_clock -period $EE_CLK_PERIOD         -name $EE_CLK_PORT              [get_nets $EE_CLK_PORT]
create_clock -period $ETHER_CLK_PERIOD 		-name $ETHER_CLK_PORT    		[get_nets $ETHER_CLK_PORT]

create_clock -period 1.6 		-name sgmii_625MHZ    		[get_nets sgmii_625MHZ_P]

set_clock_groups -group [get_clocks -include_generated_clocks $CLK_PORT] \
		-group [get_clocks -include_generated_clocks $CLK_REF_PORT] \
		-group [get_clocks -include_generated_clocks $CAM_CLK_PORT] \
		-group [get_clocks -include_generated_clocks $EE_CLK_PORT] \
		-group [get_clocks -include_generated_clocks $ETHER_CLK_PORT] \
	-asynchronous


set_false_path -through [get_ports rst_i]
set_false_path -through [get_nets rstn]

write_checkpoint -force $outputDir/post_synth
report_utilization -file $outputDir/post_synth_util.rpt


if { $WITH_DEBUG_CORE==1 } {
	create_debug_core u_ila_1 ila

	#set debug core properties
	set_property C_DATA_DEPTH 8192 [get_debug_cores u_ila_1]
	set_property C_TRIGIN_EN false [get_debug_cores u_ila_1]
	set_property C_TRIGOUT_EN false [get_debug_cores u_ila_1]
	set_property C_ADV_TRIGGER false [get_debug_cores u_ila_1]
	set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_1]
	set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_1]
	set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_1]
	set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_1]
	
	set_property port_width 1 [get_debug_ports u_ila_1/clk]
	#connect_debug_port u_ila_1/clk [get_nets vi_clk] 
	connect_debug_port u_ila_1/clk [get_nets ether_clk] 
	
	set_property port_width 1 [get_debug_ports u_ila_1/probe0]
	connect_debug_port u_ila_1/probe0 [get_nets gmii_tx_en]
	
	create_debug_port u_ila_1 probe
	set_property port_width 8 [get_debug_ports u_ila_1/probe1]
	connect_debug_port u_ila_1/probe1 [get_nets [list 	{gmii_txd[0]} \
														{gmii_txd[1]} \
														{gmii_txd[2]} \
														{gmii_txd[3]} \
														{gmii_txd[4]} \
														{gmii_txd[5]} \
														{gmii_txd[6]} \
														{gmii_txd[7]}]]
	# create_debug_port u_ila_1 probe
	# set_property port_width 1 [get_debug_ports u_ila_1/probe1]
	# connect_debug_port u_ila_1/probe1 [get_nets pic_ready]
	
	

}

if { $GENERATE_EDN==1 } {
	
} else {
	opt_design
	place_design
	phys_opt_design
	#power_opt_design
	#write_checkpoint -force $outputDir/post_place
	#report_timing_summary -file $outputDir/post_place_timing_summary.rpt
	#report_timing -max_paths 1000 -path_type summary -slack_lesser_than 0 -file $outputDir/post_route_setup_timing_violations.rpt

	# STEP#4: run router, report actual utilization and timing, write checkpoint design, run drc, write verilog and xdc out
	#
	route_design
	#write_checkpoint -force $outputDir/post_route
	report_timing_summary -file $outputDir/post_route_timing_summary.rpt
	report_timing -max_paths 10000 -path_type summary -slack_lesser_than 0 -file $outputDir/post_route_setup_timing_violations.rpt
	report_clock_utilization -file $outputDir/clock_util.rpt
	report_utilization -file $outputDir/post_route_util.rpt
	#report_power -file $outputDir/post_route_power.rpt
	#report_drc -file $outputDir/post_imp_drc.rpt
	#write_verilog -force $outputDir/ddrtest_impl_netlist.v
	#write_xdc -no_fixed_only -force $outputDir/ddrtest_impl.xdc
	#
	# STEP#5: generate a bitstream
	# 
	
	set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
	set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
	set_property CONFIG_VOLTAGE 1.8 [current_design]
	set_property CFGBVS GND [current_design]
	set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES [current_design]
	set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
	set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
	
	write_bitstream -force $outputDir/impl.bit
	
	if { $WITH_DEBUG_CORE==1 } {
		write_debug_probes -force $outputDir/xx.ltx 
	}

}
 
 
 
 
quit

