// Copyright (c) 2018  LulinChen, All Rights Reserved
// AUTHOR : 	LulinChen
// AUTHOR'S EMAIL : lulinchen@aliyun.com 
// Release history
// VERSION Date AUTHOR DESCRIPTION

module dc_luma_rom(
    input        		clk,
    input 		[3:0]  	VLI_size,
    output reg	[3:0] 	VLC_DC_size,
    output reg	[8:0] 	VLC_DC
	);
	always @(`CLK_EDGE)
		case (VLI_size)
			4'h0 : begin      VLC_DC_size <= 4'h2;      VLC_DC <= 9'b000000000;				end
			4'h1 : begin      VLC_DC_size <= 4'h3;      VLC_DC <= 9'b000000010;				end
			4'h2 : begin      VLC_DC_size <= 4'h3;      VLC_DC <= 9'b000000011;				end
			4'h3 : begin      VLC_DC_size <= 4'h3;      VLC_DC <= 9'b000000100;				end
			4'h4 : begin      VLC_DC_size <= 4'h3;      VLC_DC <= 9'b000000101;				end
			4'h5 : begin      VLC_DC_size <= 4'h3;      VLC_DC <= 9'b000000110;				end
			4'h6 : begin      VLC_DC_size <= 4'h4;      VLC_DC <= 9'b000001110;				end
			4'h7 : begin      VLC_DC_size <= 4'h5;      VLC_DC <= 9'b000011110;				end
			4'h8 : begin      VLC_DC_size <= 4'h6;      VLC_DC <= 9'b000111110;				end
			4'h9 : begin      VLC_DC_size <= 4'h7;      VLC_DC <= 9'b001111110;				end
			4'hA : begin      VLC_DC_size <= 4'h8;      VLC_DC <= 9'b011111110;				end
			4'hB : begin      VLC_DC_size <= 4'h9;      VLC_DC <= 9'b111111110;				end
			default : begin   VLC_DC_size <= 4'h0;      VLC_DC <= 9'b000000000;				end
		endcase
endmodule

module dc_chroma_rom(
    input        		clk,
    input 		[3:0]  	VLI_size,
    output reg	[3:0] 	VLC_DC_size,
    output reg	[10:0] 	VLC_DC
	);
	always @(`CLK_EDGE)
		case (VLI_size)
		4'h0 : begin           VLC_DC_size <= 4'h2;     VLC_DC <= 11'b00;				end
		4'h1 : begin           VLC_DC_size <= 4'h2;     VLC_DC <= 11'b01;				end
		4'h2 : begin           VLC_DC_size <= 4'h2;     VLC_DC <= 11'b10;				end
		4'h3 : begin           VLC_DC_size <= 4'h3;     VLC_DC <= 11'b110;				end
		4'h4 : begin           VLC_DC_size <= 4'h4;     VLC_DC <= 11'b1110;				end
		4'h5 : begin           VLC_DC_size <= 4'h5;     VLC_DC <= 11'b11110;				end
		4'h6 : begin           VLC_DC_size <= 4'h6;     VLC_DC <= 11'b111110;				end
		4'h7 : begin           VLC_DC_size <= 4'h7;     VLC_DC <= 11'b1111110;				end
		4'h8 : begin           VLC_DC_size <= 4'h8;     VLC_DC <= 11'b11111110;				end
		4'h9 : begin           VLC_DC_size <= 4'h9;     VLC_DC <= 11'b111111110;				end
		4'hA : begin           VLC_DC_size <= 4'hA;		VLC_DC <= 11'b1111111110;				end
		4'hB : begin           VLC_DC_size <= 4'hB;	    VLC_DC <= 11'b11111111110;				end
		default : begin        VLC_DC_size <= 4'h0;     VLC_DC <= {11{1'b0}};						end
		endcase
endmodule

module ac_luma_rom(
    input        		clk,
    input 		[3:0]  	runlength,
    input 		[3:0]  	VLI_size,
    output reg  [4:0] 	VLC_AC_size,
    output reg	[15:0] 	VLC_AC
	);
	
    wire [7:0]   rom_addr;
    assign rom_addr = {runlength, VLI_size};
	always @(`CLK_EDGE)
		case (runlength)
		4'h0 : case (VLI_size)
				4'h0 : begin						VLC_AC_size <= 4;						VLC_AC <= 16'b1010;				end
				4'h1 : begin						VLC_AC_size <= 2;						VLC_AC <= 16'b00;				end
				4'h2 : begin						VLC_AC_size <= 2;						VLC_AC <= 16'b01;				end
				4'h3 : begin						VLC_AC_size <= 3;						VLC_AC <= 16'b100;				end
				4'h4 : begin						VLC_AC_size <= 4;						VLC_AC <= 16'b1011;				end
				4'h5 : begin						VLC_AC_size <= 5;						VLC_AC <= 16'b11010;				end
				4'h6 : begin						VLC_AC_size <= 7;						VLC_AC <= 16'b1111000;				end
				4'h7 : begin						VLC_AC_size <= 8;						VLC_AC <= 16'b11111000;				end
				4'h8 : begin						VLC_AC_size <= 10;						VLC_AC <= 16'b1111110110;				end
				4'h9 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110000010;				end
				4'hA : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110000011;				end
				default : begin			             VLC_AC_size <= 0;						VLC_AC <= 16'b0;				end
			endcase
		4'h1 : case (VLI_size)
				4'h1 : begin						VLC_AC_size <= 4;						VLC_AC <= 16'b1100;				end
				4'h2 : begin						VLC_AC_size <= 5;						VLC_AC <= 16'b11011;				end
				4'h3 : begin						VLC_AC_size <= 7;						VLC_AC <= 16'b1111001;				end
				4'h4 : begin						VLC_AC_size <= 9;						VLC_AC <= 16'b111110110;				end
				4'h5 : begin						VLC_AC_size <= 11;						VLC_AC <= 16'b11111110110;				end
				4'h6 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110000100;				end
				4'h7 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110000101;				end
				4'h8 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110000110;				end
				4'h9 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110000111;				end
				4'hA : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110001000;				end
				default : begin			             VLC_AC_size <= 0;						VLC_AC <= 16'b0;				end
			endcase
		4'h2 : case (VLI_size)
				4'h1 : begin						VLC_AC_size <= 5;						VLC_AC <= 16'b11100;				end
				4'h2 : begin						VLC_AC_size <= 8;						VLC_AC <= 16'b11111001;				end
				4'h3 : begin						VLC_AC_size <= 10;						VLC_AC <= 16'b1111110111;				end
				4'h4 : begin						VLC_AC_size <= 12;						VLC_AC <= 16'b111111110100;				end
				4'h5 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110001001;				end
				4'h6 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110001010;				end
				4'h7 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110001011;				end
				4'h8 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110001100;				end
				4'h9 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110001101;				end
				4'hA : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110001110;				end
				default : begin			             VLC_AC_size <= 0;						VLC_AC <= 16'b0;				end
			endcase
		4'h3 : case (VLI_size)
				4'h1 : begin						VLC_AC_size <= 6;						VLC_AC <= 16'b111010;				end
				4'h2 : begin						VLC_AC_size <= 9;						VLC_AC <= 16'b111110111;				end
				4'h3 : begin						VLC_AC_size <= 12;						VLC_AC <= 16'b111111110101;				end
				4'h4 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110001111;				end
				4'h5 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110010000;				end
				4'h6 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110010001;				end
				4'h7 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110010010;				end
				4'h8 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110010011;				end
				4'h9 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110010100;				end
				4'hA : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110010101;				end
				default : begin			             VLC_AC_size <= 0;						VLC_AC <= 16'b0;				end
			endcase
		4'h4 : case (VLI_size)
				4'h1 : begin						VLC_AC_size <= 6;						VLC_AC <= 16'b111011;				end
				4'h2 : begin						VLC_AC_size <= 10;						VLC_AC <= 16'b1111111000;				end
				4'h3 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110010110;				end
				4'h4 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110010111;				end
				4'h5 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110011000;				end
				4'h6 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110011001;				end
				4'h7 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110011010;				end
				4'h8 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110011011;				end
				4'h9 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110011100;				end
				4'hA : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110011101;				end
				default : begin			             VLC_AC_size <= 0;						VLC_AC <= 16'b0;				end
			endcase
		4'h5 : case (VLI_size)
				4'h1 : begin						VLC_AC_size <= 7;						VLC_AC <= 16'b1111010;				end
				4'h2 : begin						VLC_AC_size <= 11;						VLC_AC <= 16'b11111110111;				end
				4'h3 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110011110;				end
				4'h4 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110011111;				end
				4'h5 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110100000;				end
				4'h6 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110100001;				end
				4'h7 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110100010;				end
				4'h8 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110100011;				end
				4'h9 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110100100;				end
				4'hA : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110100101;				end
				default : begin			             VLC_AC_size <= 0;						VLC_AC <= 16'b0;				end
			endcase
		4'h6 : case (VLI_size)
				4'h1 : begin						VLC_AC_size <= 7;						VLC_AC <= 16'b1111011;				end
				4'h2 : begin						VLC_AC_size <= 12;						VLC_AC <= 16'b111111110110;				end
				4'h3 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110100110;				end
				4'h4 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110100111;				end
				4'h5 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110101000;				end
				4'h6 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110101001;				end
				4'h7 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110101010;				end
				4'h8 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110101011;				end
				4'h9 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110101100;				end
				4'hA : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110101101;				end
				default : begin			             VLC_AC_size <= 0;						VLC_AC <= 16'b0;				end
			endcase
		4'h7 : case (VLI_size)
				4'h1 : begin						VLC_AC_size <= 8;						VLC_AC <= 16'b11111010;				end
				4'h2 : begin						VLC_AC_size <= 12;						VLC_AC <= 16'b111111110111;				end
				4'h3 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110101110;				end
				4'h4 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110101111;				end
				4'h5 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110110000;				end
				4'h6 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110110001;				end
				4'h7 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110110010;				end
				4'h8 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110110011;				end
				4'h9 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110110100;				end
				4'hA : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110110101;				end
				default : begin			             VLC_AC_size <= 0;						VLC_AC <= 16'b0;				end
			endcase
		4'h8 : case (VLI_size)
				4'h1 : begin						VLC_AC_size <= 9;						VLC_AC <= 16'b111111000;				end
				4'h2 : begin						VLC_AC_size <= 15;						VLC_AC <= 16'b111111111000000;				end
				4'h3 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110110110;				end
				4'h4 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110110111;				end
				4'h5 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110111000;				end
				4'h6 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110111001;				end
				4'h7 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110111010;				end
				4'h8 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110111011;				end
				4'h9 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110111100;				end
				4'hA : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110111101;				end
				default : begin			             VLC_AC_size <= 0;						VLC_AC <= 16'b0;				end
			endcase
		4'h9 : case (VLI_size)
				4'h1 : begin						VLC_AC_size <= 9;						VLC_AC <= 16'b111111001;				end
				4'h2 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110111110;				end
				4'h3 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111110111111;				end
				4'h4 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111000000;				end
				4'h5 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111000001;				end
				4'h6 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111000010;				end
				4'h7 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111000011;				end
				4'h8 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111000100;				end
				4'h9 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111000101;				end
				4'hA : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111000110;				end
				default : begin			             VLC_AC_size <= 0;						VLC_AC <= 16'b0;				end
			endcase
		4'hA : case (VLI_size)
				4'h1 : begin						VLC_AC_size <= 9;						VLC_AC <= 16'b111111010;				end
				4'h2 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111000111;				end
				4'h3 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111001000;				end
				4'h4 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111001001;				end
				4'h5 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111001010;				end
				4'h6 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111001011;				end
				4'h7 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111001100;				end
				4'h8 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111001101;				end
				4'h9 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111001110;				end
				4'hA : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111001111;				end
				default : begin			             VLC_AC_size <= 0;						VLC_AC <= 16'b0;				end
			endcase
		4'hB : case (VLI_size)
				4'h1 : begin						VLC_AC_size <= 10;						VLC_AC <= 16'b1111111001;				end
				4'h2 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111010000;				end
				4'h3 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111010001;				end
				4'h4 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111010010;				end
				4'h5 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111010011;				end
				4'h6 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111010100;				end
				4'h7 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111010101;				end
				4'h8 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111010110;				end
				4'h9 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111010111;				end
				4'hA : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111011000;				end
				default : begin			             VLC_AC_size <= 0;						VLC_AC <= 16'b0;				end
			endcase
		4'hC : case (VLI_size)
				4'h1 : begin						VLC_AC_size <= 10;						VLC_AC <= 16'b1111111010;				end
				4'h2 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111011001;				end
				4'h3 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111011010;				end
				4'h4 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111011011;				end
				4'h5 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111011100;				end
				4'h6 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111011101;				end
				4'h7 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111011110;				end
				4'h8 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111011111;				end
				4'h9 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111100000;				end
				4'hA : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111100001;				end
				default : begin			             VLC_AC_size <= 0;						VLC_AC <= 16'b0;				end
			endcase
		4'hD : case (VLI_size)
				4'h1 : begin						VLC_AC_size <= 11;						VLC_AC <= 16'b11111111000;				end
				4'h2 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111100010;				end
				4'h3 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111100011;				end
				4'h4 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111100100;				end
				4'h5 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111100101;				end
				4'h6 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111100110;				end
				4'h7 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111100111;				end
				4'h8 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111101000;				end
				4'h9 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111101001;				end
				4'hA : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111101010;				end
				default : begin			             VLC_AC_size <= 0;						VLC_AC <= 16'b0;				end
			endcase
		4'hE : case (VLI_size)
				4'h1 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111101011;				end
				4'h2 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111101100;				end
				4'h3 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111101101;				end
				4'h4 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111101110;				end
				4'h5 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111101111;				end
				4'h6 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111110000;				end
				4'h7 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111110001;				end
				4'h8 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111110010;				end
				4'h9 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111110011;				end
				4'hA : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111110100;				end
				default : begin			             VLC_AC_size <= 0;						VLC_AC <= 16'b0;				end
			endcase
		4'hF : case (VLI_size)
				4'h0 : begin						VLC_AC_size <= 11;						VLC_AC <= 16'b11111111001;				end
				4'h1 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111110101;				end
				4'h2 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111110110;				end
				4'h3 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111110111;				end
				4'h4 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111111000;				end
				4'h5 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111111001;				end
				4'h6 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111111010;				end
				4'h7 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111111011;				end
				4'h8 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111111100;				end
				4'h9 : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111111101;				end
				4'hA : begin						VLC_AC_size <= 16;						VLC_AC <= 16'b1111111111111110;				end
				default : begin			             VLC_AC_size <= 0;						VLC_AC <= 16'b0;				end
			endcase
		default : begin			     VLC_AC_size <= {5{16'b0}}; 				VLC_AC <= {16{16'b0}};				end
		endcase
endmodule

module ac_chroma_rom(
    input        		clk,
    input 		[3:0]  	runlength,
    input 		[3:0]  	VLI_size,
    output reg	[4:0] 	VLC_AC_size,
    output reg 	[15:0] 	VLC_AC
	);
    wire [7:0]   rom_addr;
    assign rom_addr = {runlength, VLI_size};
	
	always @(`CLK_EDGE)
		case (runlength)
		4'h0 :	case (VLI_size)
					4'h0 : 	begin	VLC_AC_size <= 2;	VLC_AC <= 16'b00; end
					4'h1 :	begin   VLC_AC_size <= 2;	VLC_AC <= 16'b01; end
					4'h2 :	begin	VLC_AC_size <= 3;   VLC_AC <= 16'b100; end
					4'h3 :	begin 	VLC_AC_size <= 4;	VLC_AC <= 16'b1010; end
					4'h4 :	begin 	VLC_AC_size <= 5;	VLC_AC <= 16'b11000; end
					4'h5 :	begin 	VLC_AC_size <= 5;	VLC_AC <= 16'b11001; end
					4'h6 :	begin 	VLC_AC_size <= 6;	VLC_AC <= 16'b111000; end
					4'h7:	begin 	VLC_AC_size <= 7;	VLC_AC <= 16'b1111000; end
					4'h8 :	begin 	VLC_AC_size <= 9;	VLC_AC <= 16'b111110100; end
					4'h9 :	begin 	VLC_AC_size <=10;	VLC_AC <= 16'b1111110110; end
					4'ha :	begin 	VLC_AC_size <=12;	VLC_AC <= 16'b111111110100; end
					default :begin	VLC_AC_size <= 0; 	VLC_AC <= 16'b0;  			end
				endcase
		4'h1 :	case (VLI_size)
					4'h1 :	begin   VLC_AC_size <= 4; 	VLC_AC <= 16'b1011;end
					4'h2 :	begin	VLC_AC_size <= 6;   VLC_AC <= 16'b111001;end
					4'h3 :	begin 	VLC_AC_size <= 8; 	VLC_AC <= 16'b11110110;end
					4'h4 :	begin 	VLC_AC_size <= 9; 	VLC_AC <= 16'b111110101;end
					4'h5 :	begin 	VLC_AC_size <= 11;	VLC_AC <= 16'b11111110110;end
					4'h6 :	begin 	VLC_AC_size <= 12;	VLC_AC <= 16'b111111110101;end
					4'h7:	begin 	VLC_AC_size <= 16;	VLC_AC <= 16'b1111111110001000;end
					4'h8 :	begin 	VLC_AC_size <= 16;	VLC_AC <= 16'b1111111110001001;end
					4'h9 :	begin 	VLC_AC_size <= 16;	VLC_AC <= 16'b1111111110001010;end
					4'ha :	begin 	VLC_AC_size <= 16;	VLC_AC <= 16'b1111111110001011;end
					default :begin	VLC_AC_size <= 0;  	VLC_AC <= 16'b0;end
				endcase
		4'h2 :  case (VLI_size)
				4'h1 :         begin  VLC_AC_size <= 5;  	 VLC_AC <= 16'b11010;				 end
				4'h2 :         begin  VLC_AC_size <= 8;  	 VLC_AC <= 16'b11110111;              end
				4'h3 :         begin  VLC_AC_size <= 10; 	  VLC_AC <= 16'b1111110111;          end
				4'h4 :         begin  VLC_AC_size <= 12; 	  VLC_AC <= 16'b111111110110;        end
				4'h5 :         begin  VLC_AC_size <= 15; 	  VLC_AC <= 16'b111111111000010;     end
				4'h6 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110001100;    end
				4'h7 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110001101;    end
				4'h8 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110001110;    end
				4'h9 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110001111;    end
				4'hA :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110010000;    end
				default :      begin  VLC_AC_size <= 0;  	 VLC_AC <= 16'b0;                     end
				endcase               	                                                                  
		4'h3 : case (VLI_size)        	                                                              
				4'h1 :         begin  VLC_AC_size <= 5;  	 VLC_AC <= 16'b11011;                 end
				4'h2 :         begin  VLC_AC_size <= 8;  	 VLC_AC <= 16'b11111000;              end
				4'h3 :         begin  VLC_AC_size <= 10; 	  VLC_AC <= 16'b1111111000;          end
				4'h4 :         begin  VLC_AC_size <= 12; 	  VLC_AC <= 16'b111111110111;        end
				4'h5 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110010001;    end
				4'h6 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110010010;    end
				4'h7 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110010011;    end
				4'h8 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110010100;    end
				4'h9 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110010101;    end
				4'hA :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110010110;    end
				default :      begin  VLC_AC_size <= 0;  	 VLC_AC <= 16'b0;                     end
				endcase               	                                                                   
		4'h4 : case (VLI_size)        	                                                                     
				4'h1 :         begin  VLC_AC_size <= 6;  	 VLC_AC <= 16'b111010;                end
				4'h2 :         begin  VLC_AC_size <= 9;  	 VLC_AC <= 16'b111110110;             end
				4'h3 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110010111;    end
				4'h4 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110011000;    end
				4'h5 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110011001;    end
				4'h6 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110011010;    end
				4'h7 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110011011;    end
				4'h8 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110011100;    end
				4'h9 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110011101;    end
				4'hA :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110011110;    end
				default :      begin  VLC_AC_size <= 0;  	 VLC_AC <= 16'b0;                     end
				endcase               	                                                                  
		4'h5 : case (VLI_size)        	                                                                  
				4'h1 :         begin  VLC_AC_size <= 6;  	 VLC_AC <= 16'b111011;                end
				4'h2 :         begin  VLC_AC_size <= 10; 	  VLC_AC <= 16'b1111111001;          end
				4'h3 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110011111;    end
				4'h4 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110100000;    end
				4'h5 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110100001;    end
				4'h6 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110100010;    end
				4'h7 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110100011;    end
				4'h8 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110100100;    end
				4'h9 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110100101;    end
				4'hA :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110100110;    end
				default :      begin  VLC_AC_size <= 0;  	 VLC_AC <= 16'b0;                     end
				endcase               	                                                                   
		4'h6 : case (VLI_size)        	                                                                   
				4'h1 :         begin  VLC_AC_size <= 7;  	 VLC_AC <= 16'b1111001;               end
				4'h2 :         begin  VLC_AC_size <= 11; 	  VLC_AC <= 16'b11111110111;         end
				4'h3 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110100111;    end
				4'h4 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110101000;    end
				4'h5 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110101001;    end
				4'h6 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110101010;    end
				4'h7 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110101011;    end
				4'h8 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110101100;    end
				4'h9 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110101101;    end
				4'hA :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110101110;    end
				default :      begin  VLC_AC_size <= 0;  	 VLC_AC <= 16'b0;                     end
				endcase               	                                                                    
		4'h7 : case (VLI_size)        	                                                                   
				4'h1 :         begin  VLC_AC_size <= 7;  	 VLC_AC <= 16'b1111010;               end
				4'h2 :         begin  VLC_AC_size <= 11; 	  VLC_AC <= 16'b11111111000;         end
				4'h3 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110101111;    end
				4'h4 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110110000;    end
				4'h5 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110110001;    end
				4'h6 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110110010;    end
				4'h7 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110110011;    end
				4'h8 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110110100;    end
				4'h9 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110110101;    end
				4'hA :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110110110;    end
				default :      begin  VLC_AC_size <= 0;  	 VLC_AC <= 16'b0;                     end
				endcase               	                                                                    
		4'h8 : case (VLI_size)        	                                                                   
				4'h1 :         begin  VLC_AC_size <= 8;  	 VLC_AC <= 16'b11111001;              end
				4'h2 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110110111;    end
				4'h3 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110111000;    end
				4'h4 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110111001;    end
				4'h5 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110111010;    end
				4'h6 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110111011;    end
				4'h7 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110111100;    end
				4'h8 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110111101;    end
				4'h9 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110111110;    end
				4'hA :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111110111111;    end
				default :      begin  VLC_AC_size <= 0;  	 VLC_AC <= 16'b0;                     end
				endcase               	                                                                     
		4'h9 : case (VLI_size)        	                                                                    
				4'h1 :         begin  VLC_AC_size <= 9;  	 VLC_AC <= 16'b111110111;             end
				4'h2 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111000000;    end
				4'h3 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111000001;    end
				4'h4 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111000010;    end
				4'h5 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111000011;    end
				4'h6 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111000100;    end
				4'h7 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111000101;    end
				4'h8 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111000110;    end
				4'h9 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111000111;    end
				4'hA :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111001000;    end
				default :      begin  VLC_AC_size <= 0;  	 VLC_AC <= 16'b0;                     end
				endcase               	                                                                     
		4'hA : case (VLI_size)        	                                                                  
				4'h1 :         begin  VLC_AC_size <= 9;  	  VLC_AC <= 16'b111111000;            end
				4'h2 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111001001;    end
				4'h3 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111001010;    end
				4'h4 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111001011;    end
				4'h5 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111001100;    end
				4'h6 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111001101;    end
				4'h7 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111001110;    end
				4'h8 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111001111;    end
				4'h9 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111010000;    end
				4'hA :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111010001;    end
				default :      begin  VLC_AC_size <= 0;  	  VLC_AC <= 16'b0;                    end
			endcase                   	                                                                    
		4'hB : case (VLI_size)        	                                                                   
				4'h1 :         begin  VLC_AC_size <= 9;  	  VLC_AC <= 16'b111111001;            end
				4'h2 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111010010;    end
				4'h3 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111010011;    end
				4'h4 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111010100;    end
				4'h5 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111010101;    end
				4'h6 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111010110;    end
				4'h7 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111010111;    end
				4'h8 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111011000;    end
				4'h9 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111011001;    end
				4'hA :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111011010;    end
				default :      begin  VLC_AC_size <= 0;  	  VLC_AC <= 16'b0;                    end
				endcase               	                                                                    
		4'hC : case (VLI_size)        	                                                                  
				4'h1 :         begin  VLC_AC_size <= 9;  	  VLC_AC <= 16'b111111010;            end
				4'h2 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111011011;    end
				4'h3 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111011100;    end
				4'h4 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111011101;    end
				4'h5 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111011110;    end
				4'h6 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111011111;    end
				4'h7 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111100000;    end
				4'h8 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111100001;    end
				4'h9 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111100010;    end
				4'hA :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111100011;    end
				default :      begin  VLC_AC_size <= 0;  	  VLC_AC <= 16'b0;                    end
				endcase               	                                                                   
		4'hD : case (VLI_size)        	                                                                    
				4'h1 :         begin  VLC_AC_size <= 11; 	  VLC_AC <= 16'b11111111001;         end
				4'h2 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111100100;    end
				4'h3 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111100101;    end
				4'h4 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111100110;    end
				4'h5 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111100111;    end
				4'h6 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111101000;    end
				4'h7 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111101001;    end
				4'h8 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111101010;    end
				4'h9 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111101011;    end
				4'hA :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111101100;    end
				default :      begin  VLC_AC_size <= 0;  	  VLC_AC <= 16'b0;                    end
				endcase               	                                                                   
		4'hE : case (VLI_size)        	                                                                     
				4'h1 :         begin  VLC_AC_size <= 14; 	  VLC_AC <= 16'b11111111100000;      end
				4'h2 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111101101;    end
				4'h3 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111101110;    end
				4'h4 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111101111;    end
				4'h5 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111110000;    end
				4'h6 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111110001;    end
				4'h7 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111110010;    end
				4'h8 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111110011;    end
				4'h9 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111110100;    end
				4'hA :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111110101;    end
				default :      begin  VLC_AC_size <= 0;  	  VLC_AC <= 16'b0;                    end
				endcase               	                                                                   
		4'hF : case (VLI_size)        	                                                                   
				4'h0 :         begin  VLC_AC_size <= 10; 	  VLC_AC <= 16'b1111111010;			 end
				4'h1 :         begin  VLC_AC_size <= 15; 	  VLC_AC <= 16'b111111111000011;     end
				4'h2 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111110110;    end
				4'h3 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111110111;    end
				4'h4 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111111000;    end
				4'h5 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111111001;    end
				4'h6 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111111010;    end
				4'h7 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111111011;    end
				4'h8 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111111100;    end
				4'h9 :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111111101;    end
				4'hA :         begin  VLC_AC_size <= 16; 	  VLC_AC <= 16'b1111111111111110;    end
				default :      begin  VLC_AC_size <= 0;  	  VLC_AC <= 16'b0;                    end
				endcase                                                                                     
		default :  			   begin  VLC_AC_size <= 0;		  VLC_AC <= 16'b0; 					 end
		endcase
endmodule