# A hardware MJPEG encoder and RTP transmitter

This project realizes a JPEG baseline encoder and transmitter over ehternet.

The code is written by Verilog/SystemVerilog and Synthesized on Xilinx KintexUltrascale FPGA using Vivado.

With full pipleline implementation, the encoder has the ability to encoder 4k video realtime. 


## Demo
Xilinx KCU105 Board, with an HDMI input daughter board. 

The input 1080P HDMI input is encoded to JPEG and transported over ethernet to PC.

On the PC, play with VLC or ffmpeg.

VLC sdp file:
```
v=0
c=IN IP4 255.255.255.255 
t=0 
m=video 39630 RTP/AVP 26 
a=rtpmap:26 JPEG
```

ffplay:

run ```ffplay -i rtp://225.255.255.255:39630```
## TODO

- Only implemented the YUV44 and YUV422 mode, with hardware select. realize YUV420, and add soft config.
- The entropy encoder's performance will be a limit, when encoding 4k video. Parrallel techniques should be added, use seperate engine for luma and chroma.
- The Quantization Factor is fixed 50, add some logic to accept setting.
- Add rate control module
- Ethernet module only support broadcast.
- Add DHCP ARP to ethnet module, 

## Reference

[ OpenCores jpeg IP cores](https://opencores.org)

[JasonJiangSheng, "JpegEnc"](https://github.com/JasonJiangSheng/JpegEnc)

[RFCxxxx](https://www.rfc-archive.org/)

## Author

LulinChen  
lulinchen@aliyun.com
