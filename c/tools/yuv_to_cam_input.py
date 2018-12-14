#!/usr/bin/python

import sys

if __name__ == "__main__":
	if len(sys.argv) != 8:
		print("USAGE: yuv_to_cam_input input-file output-file width height frame_nb interlace(0 or 1) color-space(0,1-420; 2-422; 3-444)\n");
		print("parameter Error\n");
		exit();
	
	fp_in = open(sys.argv[1], "rb")
	fp_out = open(sys.argv[2], "wb")
	width       = int(sys.argv[3])
	height      = int(sys.argv[4])
	frame_nb    = int(sys.argv[5])
	b_interlace = int(sys.argv[6])
	colorspc    = int(sys.argv[7])
	print("width=%d height=%d frame_nb=%d interlace=%d colorspc=%d\n" % ( width, height, frame_nb, b_interlace, colorspc));
	if b_interlace != 0:
		print("interlace not support yet\n")
		exit();
		

	size_Y  = width * height
	if 3 == colorspc:
		ch_div_x = 1
	else:
		ch_div_x = 2
		
	if 3 == colorspc:
		ch_div_y = 1
	elif 2 == colorspc:
		ch_div_y = 1
	else:
		ch_div_y = 2
	ch_div = ch_div_x * ch_div_y
	size_UV  = size_Y/ch_div;
	
	for frame in range(0, frame_nb):
		Y = fp_in.read(size_Y)
		U = fp_in.read(size_UV)
		V = fp_in.read(size_UV)
		if colorspc==3:
			rgb_bytes = bytearray(3)
			for i in range(0, height):
				for j in range(0, width):
					rgb_bytes[0] = Y[i*width + j]
					rgb_bytes[1] = U[i*width + j]
					rgb_bytes[2] = V[i*width + j]
					fp_out.write(rgb_bytes)
		else:
			rgb_bytes = bytearray(4)
			for i in range(0, height):
				for j in range(0, width/ch_div_x):
					rgb_bytes[0] = U[(i/ch_div_y)*width/ch_div_x + j]
					rgb_bytes[1] = Y[i*width + j*2]
					rgb_bytes[2] = V[(i/ch_div_y)*width/ch_div_x + j]
					rgb_bytes[3] = Y[i*width + j*2+1]
					fp_out.write(rgb_bytes)
	fp_in.close()
	fp_out.close()
	
	