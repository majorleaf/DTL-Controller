
module traffic_light #(
parameter CLK_FREQ = 50_000_000, // clock cycles per second
parameter GREEN_TIME = 10, // seconds
parameter YELLOW_TIME = 3 // seconds
)(
input wire clk, // system clock
input wire reset, // synchronous, active-high reset
output reg a_red, a_yellow, a_green, // Road A lights
output reg b_red, b_yellow, b_green // Road B lights
);
// ---------------- State encoding ----------------
localparam [1:0] S1_A_GREEN = 2'b00,
S2_A_YELLOW = 2'b01,
S3_B_GREEN = 2'b10,
S4_B_YELLOW = 2'b11;
reg [1:0] state, next_state;
// ---------------- Timing counter ----------------
reg [31:0] timer; // clock cycles spent in current state
reg [31:0] limit; // clock cycles this state must last
wire time_up = (timer == limit - 1);
// How long (in clock cycles) does the current state last?
Appendix B: testbench.sv
always @(*) begin
case (state)
S1_A_GREEN,
S3_B_GREEN: limit = GREEN_TIME * CLK_FREQ;
default: limit = YELLOW_TIME * CLK_FREQ; // S2, S4
endcase
end
// ---------------- Process 1: state + counter registers ----------------
always @(posedge clk) begin
if (reset) begin
state <= S1_A_GREEN; // known starting state
timer <= 32'd0;
end else begin
state <= next_state;
if (time_up)
timer <= 32'd0; // new state starts counting from 0
else
timer <= timer + 1'b1;
end
end
// ---------------- Process 2: next-state logic ----------------
always @(*) begin
next_state = state; // default: stay
if (time_up) begin
case (state)
S1_A_GREEN: next_state = S2_A_YELLOW;
S2_A_YELLOW: next_state = S3_B_GREEN;
S3_B_GREEN: next_state = S4_B_YELLOW;
S4_B_YELLOW: next_state = S1_A_GREEN;
default: next_state = S1_A_GREEN;
endcase
end
end
// ---------------- Process 3: output logic (Moore) ----------------
// Outputs depend only on the current state.
always @(*) begin
{a_red, a_yellow, a_green} = 3'b100; // safe defaults: all Red
{b_red, b_yellow, b_green} = 3'b100;
case (state)
S1_A_GREEN: begin {a_red,a_yellow,a_green} = 3'b001;
{b_red,b_yellow,b_green} = 3'b100; end
S2_A_YELLOW: begin {a_red,a_yellow,a_green} = 3'b010;
{b_red,b_yellow,b_green} = 3'b100; end
S3_B_GREEN: begin {a_red,a_yellow,a_green} = 3'b100;
{b_red,b_yellow,b_green} = 3'b001; end
S4_B_YELLOW: begin {a_red,a_yellow,a_green} = 3'b100;
{b_red,b_yellow,b_green} = 3'b010; end
endcase
end
endmodule
