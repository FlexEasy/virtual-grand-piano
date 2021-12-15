module Virtual_Piano_toplevel
(
	input logic [9:0] FSR,
	//control sig
	input logic clk,
	input logic reset,
	input logic [7:0] writedata,
	input logic write,
	input chipselect,
	input logic [10:0] address,
	input logic [3:0] SW,
	//input logic [3:0] KEY,
	//WM8731
	inout AUD_ADCLRCK,
	input AUD_ADCDAT,
	inout AUD_DACLRCK,
	output AUD_DACDAT,
	output AUD_XCK,
	inout AUD_BCLK,
	//I2C
	//output AUD_I2C_SCLK,
	//inout AUD_I2C_SDAT,
	//MUTE
	output AUD_MUTE
);


logic [16:0] press1= 17'b00000000000000010;
logic [16:0] press2= 17'b00000000000000100;
//logic [16:0] press3:
//logic [16:0] press4:
//logic [16:0] press5:


//wire AUD_reset = !KEY[2];
wire main_clk;
wire audio_clk;
wire clk27;
wire [1:0] sample_end;
wire [1:0] sample_req;
wire [15:0] audio_output;
wire [15:0] audio_input;
wire [15:0] audio_output1;
wire [15:0] audio_output2;

KEY_MIXER multikey (.clk50(clk), .press(press), .press1(press1), .press2(press2));

//
//clock_pll pll (
//.refclk (clk),
//.rst (AUD_reset),
//.outclk_0 (main_clk),
//.outclk_1 (audio_clk),
//.outclk_2 (clk27)
//);
//i2c_av_config av_config (
//.clk (main_clk),
//.reset (AUD_reset),
//.i2c_sclk (AUD_I2C_SCLK),
//.i2c_sdat (AUD_I2C_SDAT),
//);

assign AUD_XCK = audio_clk;
assign AUD_MUTE = 1;
assign audio_output = (audio_output1 + audio_output2)/2;

WM8731_CODEC CODEC(
.clk (audio_clk),
.reset (AUD_reset),
.sample_end (sample_end),
.sample_req (sample_req),
.audio_output (audio_output),
.audio_input (audio_input),
.channel_sel (2'b10),
.AUD_ADCLRCK (AUD_ADCLRCK),
.AUD_ADCDAT (AUD_ADCDAT),
.AUD_DACLRCK (AUD_DACLRCK),
.AUD_DACDAT (AUD_DACDAT),
.AUD_BCLK (AUD_BCLK)
);

karplus_note KEY1 (
.clock50 (clk27),
.audiolrclk (AUD_DACLRCK),
.reset (AUD_reset),
.audio_output (audio_output1),
.audio_input (audio_input),
.control (SW),
.press (press1)
);
karplus_note KEY2 (
.clock50 (clk27),
.audiolrclk (AUD_DACLRCK),
.reset (AUD_reset),
.audio_output (audio_output2),
.audio_input (audio_input),
.control (SW),
.press (press2)
);
//karplus_note KEY3 (
//.clock50 (clk27),
//.audiolrclk (AUD_DACLRCK),
//.reset (AUD_reset),
//.audio_output (audio_output3),
//.audio_input (audio_input),
//.control (SW),
//.press (press3)
//);
//karplus_note KEY4 (
//.clock50 (clk27),
//.audiolrclk (AUD_DACLRCK),
//.reset (AUD_reset),
//.audio_output (audio_output4),
//.audio_input (audio_input),
//.control (SW),
//.press (press4)
//);
//karplus_note KEY5 (
//.clock50 (clk27),
//.audiolrclk (AUD_DACLRCK),
//.reset (AUD_reset),
//.audio_output (audio_output5),
//.audio_input (audio_input),
//.control (SW),
//.press (press5)
//);
 //AUD/////////////////////////////////////////////////////////////////////////////////////////

 endmodule
 