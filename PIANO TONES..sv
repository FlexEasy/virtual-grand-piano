//ontrol[3] == 0) ? ((control[2] == 0) ? 3'b000 : 3'b010): ((control[2] == 0) ? 3'b011 : 3'b100);
//Karplus-strong algorithm module to synthesis piano notes
//Refer to 5760 DSP example code of guitar string pluck synthesis:
//https://instruct1.cit.cornell.edu/courses/ece576/DE2/fpgaDSP.html
module karplus_note (clock50, audiolrclk, reset, press, audio_output, audio_input, control);
input clock50; //clock as reference
input audiolrclk; //sample frequency
input reset; //reset signal
input [9:0] press; //represent which keys are pressed
output[15:0] audio_output; //output audio signal
input [15:0] audio_input;
input [3:0] control;
wire [9:0] combination;
reg [9:0] combination_last;
assign combination = press;
reg [17:0] Out; //middle string
reg [17:0] OutS,OutH; //lower string and higher string
reg [17:0] OutSum; //the sum of three strings
assign audio_output = OutSum[17:2]; //take the higher 15 bits to output
reg [10:0] note; //define the length of the middle string shiftregister
reg [10:0] noteS; //define the length of the lower string shiftregister
reg [10:0] noteH; //define the length of the higher string shiftregister
reg pluck ; //pluck the string, and counts for three strings
reg last_pluck;
reg [11:0] pluck_count,pluck_countS,pluck_countH;

// state variable 0=reset, 1=readinput,
// 2=readoutput, 3=writeinput, 4=write 5=updatepointers,
// 9=stop
reg [2:0] state ;
reg last_clk ; //oneshot gen
wire [17:0] gain ; // constant for gain
//pointers into the shift register
//4096 at 48kHz imples 12 Hz
reg [11:0] ptr_in, ptr_out,ptr_inS,ptr_outS,ptr_inH,ptr_outH;
//memory control
reg we,weS,weH; //write enable--active high
wire [17:0] sr_data,sr_dataS,sr_dataH;
reg [17:0] write_data,write_dataS,write_dataH;
reg [11:0] addr_reg,addr_regS,addr_regH;
//data registers for arithmetic
reg [17:0] in_data, out_data;
reg [17:0] in_dataS, out_dataS;
reg [17:0] in_dataH, out_dataH;
wire [17:0] new_out, new_outH;
//random number generator and lowpass filter
wire x_low_bit ; // random number gen low-order bit
reg [30:0] x_rand ; // rand number
wire [17:0] new_lopass ;
reg [17:0] lopass ;
wire [2:0] alpha; //alpha that is used in filter
assign alpha = (control[3] == 0) ? 3'b100 : 3'b001;
// pluck control by combination
always @ (posedge clock50)
begin
pluck <= (combination==combination_last)?((combination==9'd0)?1'b0:1'b1):0;
combination_last<=combination;
end
//generate a random number at audio rate
// --AUD_DACLRCK toggles once per left/right pair
// --so it is the start signal for a random number update
// --at audio sample rate
//right-most bit for rand number shift regs
assign x_low_bit = x_rand[27] ^ x_rand[30];

// newsample = (1-alpha)*oldsample + (random+/-1)*alpha
// rearranging:
// newsample = oldsample + ((random+/-1)-oldsample)*alpha
// alpha is set from 1 to 1/128 using switches
// alpha==1 means no lopass at all. 1/128 loses almost all the input bits
assign new_lopass = lopass + ((( (x_low_bit)?18'h1_0000:18'h3_0000) - lopass)>>>alpha);
//your basic XOR random # gen
always @ (posedge audiolrclk)
begin
if (reset)
begin
x_rand <= 31'h55555555;
lopass <= 18'h0 ;
end
else begin
x_rand <= {x_rand[29:0], x_low_bit} ;
lopass <= new_lopass;
end
end
//when user pushes a button transfer rand number to circular buffer
//treat each bit of rand register as +/-1, 18-bit, 2'comp
//when loading to circ buffer
//shift buffer, apply filter, update indexes
//once per audio clock tick
assign gain = 18'h0_7FF8 ;
//Run the state machine FAST so that it completes in one
//audio cycle
always @ (posedge clock50)
begin
if (reset)
begin
ptr_out <= 12'h1 ; //output beginning of shift register
ptr_outS <=12'h1;
ptr_outH <=12'h1;
ptr_in <= 12'h0 ; //input beginning of shift register
ptr_inS<=12'h0;
ptr_inH <= 12'h0 ;
we <= 1'h0 ; //write enable signal
weS<= 1'h0;
weH<= 1'h0;
state <= 3'd7; //turn off the update state machine
last_clk <= 1'h1;
end

else begin
 //frequency(Hz) and the notes they correspond i
 if (combination==17'b10000000000000000)//587-d2,16
 note <= 11'd79;
 else if (combination==17'b01000000000000000)//523-c2,15
 note <= 11'd89;
 else if (combination==17'b00100000000000000)//493-b1,14
 note <= 11'd94;
 else if (combination==17'b00010000000000000)//440-a1,13
 note <= 11'd106;
 else if (combination==17'b00001000000000000)//391-g1,12
 note <= 11'd119;
 else if (combination==17'b00000100000000000)//349-f1,11
 note <= 11'd133;
 else if (combination==17'b00000010000000000)//329-e1,10
 note <= 11'd142;
 else if (combination==17'b00000001000000000)//293-d1,9
 note <= 11'd160;
 else if (combination==17'b00000000100000000)//261-c1,8
 note <= 11'd179;
 else if (combination==17'b00000000010000000)//246-b0,7
 note <= 11'd188;
 else if (combination==17'b00000000001000000)//220-a0,6
 note <= 11'd210;
 else if (combination==17'b00000000000100000)//196-g0,5
 note <= 11'd238;
 else if (combination==17'b00000000000010000)//174-f0,4
 note <= 11'd261;
 else if (combination==17'b00000000000001000)//164-e0,3
 note<= 11'd280;
 else if (combination==17'b00000000000000100)//146-d0,2
 note <= 11'd315;
 else if (combination==17'b00000000000000010)//130.8-c0,1
 note<= 11'd350;
case (state)
1:
begin
// set up read ptr_out data
addr_reg <= ptr_out;
addr_regS<= ptr_outS;
addr_regH <= ptr_outH;
we <= 1'h0;
weS<= 1'h0;

weH<= 1'h0;
state <= 3'd2;
end
2:
begin
//get ptr_out data
out_data <= sr_data;
out_dataS<= sr_dataS;
out_dataH <= sr_dataH;
// set up read ptr_in data
addr_reg <= ptr_in;
addr_regS<= ptr_inS;
addr_regH <= ptr_inH;
we <= 1'h0;
weS<= 1'h0;
weH<= 1'h0;
state <= 3'd3;
end
3:
begin
//get prt_in data
in_data <= sr_data;
in_dataS <= sr_dataS;
in_dataH <= sr_dataH;
noteS<=note+2'd2; //define the length of the lower string shiftregister
noteH<=note-2'd2; //define the length of the higher string shiftregister
state <= 3'd4 ;
end
4:
begin
//write ptr_in data:
// -- can be either computed feedback, or noise from pluck
Out <= new_out;
OutS<= new_outS;
OutH<= new_outH;
OutSum<=Out+OutS+OutH;
addr_reg <= ptr_in;
addr_regS<= ptr_inS;
addr_regH <= ptr_inH;
we <= 1'h1 ;
weS<= 1'h1;
weH<= 1'h1;
// feedback or new pluck
if (pluck )

begin
// is this a new pluck? (part of the debouncer)
//middle string
if (last_pluck==0)
begin
// if so, reset the count
pluck_count <= 12'd0;
ptr_out<=12'd1;
ptr_in<=12'd0;
// and debounce pluck
last_pluck <= 1'd1;
end
// have the correct number of random numbers been loaded?
else if (pluck_count<note)
begin
//if less, load lowpass output into memory
pluck_count <= pluck_count + 12'd1 ;
write_data <= new_lopass;
end
//update feedback if not actually loading random numbers
else
//slow human holds button down, but feedback is still necessary
write_data <= new_out ;
//lower string
if (last_pluck==0)
begin
// if so, reset the count
pluck_countS <= 12'd0;
ptr_inS<=12'd0;
ptr_outS<=12'd1;
// and debounce pluck
last_pluck <= 1'd1;
end
// have the correct number of random numbers been loaded?
else if (pluck_countS<noteS)
begin
//if less, load lowpass output into memory
pluck_countS <= pluck_countS + 12'd1 ;
write_dataS<= new_lopass;
end
//update feedback if not actually loading random numbers
else
//slow human holds button down, but feedback is still necessary
write_dataS <=new_outS;

//higher string
if (last_pluck==0)
begin
// if so, reset the count
ptr_outH<=12'd1;
ptr_inH<=12'd0;
pluck_countH <= 12'd0;
// and debounce pluck
last_pluck <= 1'd1;
end
// have the correct number of random numbers been loaded?
else if (pluck_countH<noteH)
begin
//if less, load lowpass output into memory
pluck_countH <= pluck_countH + 12'd1 ;
write_dataH <= new_lopass;
end
//update feedback if not actually loading random numbers
else
//slow human holds button down, but feedback is still necessary
write_dataH <= new_outH ;
 end
else begin
// update feedback if pluck button is not pushed
// and get ready for next pluck since the button is released
last_pluck = 1'h0;
write_data <= new_out;
write_dataS <= new_outS;
write_dataH <= new_outH;
end
state <= 3'd5;
end
5:
begin
we <= 0;
weS<= 0 ;
weH<= 0;
//update 2 ptrs for middle string
if (ptr_in == note)
ptr_in <= 12'h0;

else
ptr_in <= ptr_in + 12'h1 ;
if (ptr_out == note)
ptr_out <= 12'h0;
else
ptr_out <= ptr_out + 12'h1 ;
//update 2 ptrs for lower string
if (ptr_inS == noteS)
ptr_inS <= 12'h0;
else
ptr_inS <= ptr_inS + 12'h1 ;
if (ptr_outS == noteS)
ptr_outS <= 12'h0;
else
ptr_outS <= ptr_outS + 12'h1 ;
 //update 2 ptrs for higher string
if (ptr_inH == noteH)
ptr_inH <= 12'h0;
else
ptr_inH <= ptr_inH + 12'h1 ;
if (ptr_outH == noteH)
ptr_outH <= 12'h0;
else
ptr_outH <= ptr_outH + 12'h1 ;
state <= 3'd7;
end
7:
begin
//judge if there is another strike
if (audiolrclk && last_clk)
begin
state <= 3'd1 ;
last_clk <= 1'h0 ;
end
else if (~audiolrclk)
begin
last_clk <= 1'h1 ;
state<= 3'd7;
end

end
endcase
end
end
//make the shift register
ram_infer KS(sr_data, addr_reg, write_data, we, clock50);
ram_infer KS2(sr_dataS, addr_regS, write_dataS, weS, clock50);
ram_infer KS3(sr_dataH, addr_regH, write_dataH, weH, clock50);
//make a multiplier and compute gain*(in+out)
signed_mult gainfactor(new_out, gain, (out_data + in_data));
signed_mult gainfactor2(new_outS, gain, (out_dataS + in_dataS));
signed_mult gainfactor3(new_outH, gain, (out_dataH + in_dataH));
endmodule
// M10k ram for circular buffer
// Synchronous RAM with Read-Through-Write Behavior
// and modified for 18 bit access
// of 109 words to tune for 440 Hz
module ram_infer (q, a, d, we, clk);
output [17:0] q;
input [17:0] d;
input [11:0] a;
input we, clk;
reg [11:0] read_add;
// define the length of the shiftregister
// 48000/2000 is 24 Hz. Should be long enough
// for any reasonable note
parameter note = 2047 ;
reg [17:0] mem [note:0];
always @ (posedge clk)
begin
if (we) mem[a] <= d;
read_add <= a;
end
assign q = mem[read_add];
endmodule

//signed mult of 2.16 format 2'comp
module signed_mult (out, a, b);

output [17:0] out;

input signed [17:0] a;

input signed [17:0] b;


wire signed [17:0] out;

wire signed [35:0] mult_out;

assign mult_out = a * b;

assign out = {mult_out[35], mult_out[32:16]};

endmodule



/*
PACKGAE COUNT = 0

XBEE = [00 00] [01 (02] [FE) (02] 32) () () ()
 XNEE REG = [47:0]
 
 source_addr = 0/1
 finger1 = 
 
 
 FINGER1 = XNEE_REG[70:74]
*/