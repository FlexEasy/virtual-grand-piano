module RANDOM_PRESS(input logic clk50,
input logic [7:0] audio_demo,
input logic [7:0] mode_select,
input logic [16:0] press_real,
output logic [16:0] press
);
logic [16:0] press_sim;
assign press_sim[0] = 1'b0;
assign press_sim[1] = (audio_demo == 8'd1) ? 1'b1 : 1'b0;
assign press_sim[2] = (audio_demo == 8'd2) ? 1'b1 : 1'b0;
assign press_sim[3] = (audio_demo == 8'd3) ? 1'b1 : 1'b0;
assign press_sim[4] = (audio_demo == 8'd4) ? 1'b1 : 1'b0;
assign press_sim[5] = (audio_demo == 8'd5) ? 1'b1 : 1'b0;
assign press_sim[6] = (audio_demo == 8'd6) ? 1'b1 : 1'b0;
assign press_sim[7] = (audio_demo == 8'd7) ? 1'b1 : 1'b0;
assign press_sim[8] = (audio_demo == 8'd8) ? 1'b1 : 1'b0;
assign press_sim[9] = (audio_demo == 8'd9) ? 1'b1 : 1'b0;
assign press_sim[10] = (audio_demo == 8'd10) ? 1'b1 : 1'b0;
assign press_sim[11] = (audio_demo == 8'd11) ? 1'b1 : 1'b0;
assign press_sim[12] = (audio_demo == 8'd12) ? 1'b1 : 1'b0;
assign press_sim[13] = (audio_demo == 8'd13) ? 1'b1 : 1'b0;
assign press_sim[14] = (audio_demo == 8'd14) ? 1'b1 : 1'b0;
assign press_sim[15] = (audio_demo == 8'd15) ? 1'b1 : 1'b0;
assign press_sim[16] = (audio_demo == 8'd16) ? 1'b1 : 1'b0;
logic [16:0] press_mode;
assign press_mode = ((mode_select == 8'd16) | (mode_select == 8'd18)) ? 17'b11111111111111111 :
17'b0;
assign press = ((press_real & press_mode) | press_sim);
endmodule
