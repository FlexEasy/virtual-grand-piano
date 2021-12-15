module KEY_MIXER (input logic clk50,
input logic [16:0] press,
output logic [16:0] press1,
output logic [16:0] press2);
logic [4:0] first_key;
logic [4:0] second_key;
logic [4:0] first_key_last;
logic [4:0] second_key_last;
logic [4:0] pressed_number;
logic [16:0] press1_tmp;
logic [16:0] press2_tmp;
logic [17:0] press_new;
assign press_new = {1'b0, press};
integer i;
integer j;
always_ff @(posedge clk50)
begin
i <= i + 1;
if (i == 17) begin
i <= 0;
pressed_number <= 0;
//first_key_last <= first_key;
//second_key_last <= second_key;
end
else if (press_new == 0) begin
first_key <= 0;
second_key <= 0;
end
else if (press_new[i] == 1)
begin
pressed_number <= pressed_number + 1;
if (pressed_number == 0) begin

first_key <= i;
end else if (pressed_number == 1) begin
second_key <= i;
end
end
for (j = 0; j < 17; j = j + 1)
begin
if (first_key == second_key) begin
press1_tmp <= 0;
press2_tmp <= 0;
end else if (j == first_key) begin
press1_tmp[j] <= 1;
end else if (j == second_key) begin
press2_tmp[j] <= 1;
end else begin
press1_tmp[j] <= 0;
press2_tmp[j] <= 0;
end
end
end
assign press1 = {press1_tmp[16:1], 1'b0};
assign press2 = {press2_tmp[16:1], 1'b0};
endmodule