//==============================================================================
// Module      : traffic_light_controller
// Description : FSM-based traffic light controller for a two-road intersection
//               (Road A and Road B). Moore machine + clock-cycle counter.
//
// Sequence (repeats forever):
//   S_A_GREEN  : A=Green , B=Red    -> 10 s
//   S_A_YELLOW : A=Yellow, B=Red    ->  3 s
//   S_B_GREEN  : A=Red   , B=Green  -> 10 s
//   S_B_YELLOW : A=Red   , B=Yellow ->  3 s
//
// Parameters:
//   CLK_FREQ : input clock frequency in Hz (clock cycles per second)
//   G_TIME   : green duration in seconds  (default 10)
//   Y_TIME   : yellow duration in seconds (default 3)
//
// Reset : synchronous, active-high. Forces S_A_GREEN and clears the counter.
//==============================================================================
`timescale 1ns/1ps

module traffic_light_controller #(
    parameter CLK_FREQ = 50_000_000,   // 50 MHz board clock (change as needed)
    parameter G_TIME   = 10,           // green time  [s]
    parameter Y_TIME   = 3             // yellow time [s]
)(
    input  wire       clk,       // system clock
    input  wire       rst,       // synchronous active-high reset
    output reg        a_red,     // Road A lights
    output reg        a_yellow,
    output reg        a_green,
    output reg        b_red,     // Road B lights
    output reg        b_yellow,
    output reg        b_green
);

    // ---------------- Timing constants (in clock cycles) ----------------------
    localparam [31:0] G_CYCLES = G_TIME * CLK_FREQ;
    localparam [31:0] Y_CYCLES = Y_TIME * CLK_FREQ;

    // ---------------- State encoding -----------------------------------------
    localparam [1:0] S_A_GREEN  = 2'b00,   // State 1
                     S_A_YELLOW = 2'b01,   // State 2
                     S_B_GREEN  = 2'b10,   // State 3
                     S_B_YELLOW = 2'b11;   // State 4

    reg [1:0]  state, next_state;
    reg [31:0] count;                      // clock-cycle counter
    reg [31:0] state_cycles;               // duration of the current state

    // ---------------- Duration of the current state --------------------------
    always @(*) begin
        case (state)
            S_A_GREEN,
            S_B_GREEN : state_cycles = G_CYCLES;
            default   : state_cycles = Y_CYCLES;
        endcase
    end

    // The current state has finished when the counter reaches its last cycle
    wire time_up = (count == state_cycles - 32'd1);

    // ---------------- Sequential block: state register + counter -------------
    always @(posedge clk) begin
        if (rst) begin
            state <= S_A_GREEN;
            count <= 32'd0;
        end else if (time_up) begin
            state <= next_state;
            count <= 32'd0;
        end else begin
            count <= count + 32'd1;
        end
    end

    // ---------------- Next-state logic (combinational) -----------------------
    always @(*) begin
        case (state)
            S_A_GREEN  : next_state = S_A_YELLOW;
            S_A_YELLOW : next_state = S_B_GREEN;
            S_B_GREEN  : next_state = S_B_YELLOW;
            S_B_YELLOW : next_state = S_A_GREEN;
            default    : next_state = S_A_GREEN;   // safe recovery
        endcase
    end

    // ---------------- Output logic (Moore: depends on state only) ------------
    always @(*) begin
        // safe defaults: both roads RED
        a_red = 1'b1; a_yellow = 1'b0; a_green = 1'b0;
        b_red = 1'b1; b_yellow = 1'b0; b_green = 1'b0;
        case (state)
            S_A_GREEN  : begin a_red = 1'b0; a_green  = 1'b1; end
            S_A_YELLOW : begin a_red = 1'b0; a_yellow = 1'b1; end
            S_B_GREEN  : begin b_red = 1'b0; b_green  = 1'b1; end
            S_B_YELLOW : begin b_red = 1'b0; b_yellow = 1'b1; end
            default    : ;   // both red
        endcase
    end

endmodule
