//==============================================================================
// Testbench : tb_traffic_light_controller   (self-checking, Verilog-2001)
//
// To keep simulation short, the DUT is run with CLK_FREQ = 10, i.e.
// 1 "second" = 10 clock cycles = 100 ns of simulation time.
// Therefore:  Green = 10 s = 1000 ns,  Yellow = 3 s = 300 ns,  full cycle = 2600 ns.
//
// Checks performed:
//   1. Lights follow the required sequence (S1 -> S2 -> S3 -> S4 -> S1 ...)
//   2. Each state lasts exactly the specified duration
//   3. Both roads are never Green at the same time
//   4. Each road shows exactly one colour at any time
//   5. Controller returns to State 1 after completing the 4-state sequence
//   6. Mid-sequence reset returns the controller to State 1 and it restarts
//==============================================================================
`timescale 1ns/1ps

module tb_traffic_light_controller;

    parameter CLK_FREQ   = 10;                  // simulated clock frequency (Hz)
    parameter G_TIME     = 10;                  // seconds
    parameter Y_TIME     = 3;                   // seconds
    parameter CLK_PERIOD = 10;                  // ns
    parameter SEC        = CLK_FREQ*CLK_PERIOD; // ns per simulated second (=100)

    reg  clk;
    reg  rst;
    wire a_red, a_yellow, a_green, b_red, b_yellow, b_green;

    // Light vector: {A_R, A_Y, A_G, B_R, B_Y, B_G}
    wire [5:0] lights = {a_red, a_yellow, a_green, b_red, b_yellow, b_green};

    // ---------------- Device under test --------------------------------------
    traffic_light_controller #(
        .CLK_FREQ(CLK_FREQ), .G_TIME(G_TIME), .Y_TIME(Y_TIME)
    ) dut (
        .clk(clk), .rst(rst),
        .a_red(a_red), .a_yellow(a_yellow), .a_green(a_green),
        .b_red(b_red), .b_yellow(b_yellow), .b_green(b_green)
    );

    // ---------------- Clock generation ---------------------------------------
    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // ---------------- Expected patterns and durations ------------------------
    reg [5:0] exp_pat [0:3];
    integer   exp_dur [0:3];   // in ns

    initial begin
        exp_pat[0] = 6'b001_100;  // S1: A Green , B Red
        exp_pat[1] = 6'b010_100;  // S2: A Yellow, B Red
        exp_pat[2] = 6'b100_001;  // S3: A Red   , B Green
        exp_pat[3] = 6'b100_010;  // S4: A Red   , B Yellow
        exp_dur[0] = G_TIME*SEC;
        exp_dur[1] = Y_TIME*SEC;
        exp_dur[2] = G_TIME*SEC;
        exp_dur[3] = Y_TIME*SEC;
    end

    // ---------------- Monitor state ------------------------------------------
    integer errors;
    integer idx;          // index of the state we expect to be in now (0..3)
    integer last_change;  // simulation time of last state change (ns)
    integer elapsed;
    integer cycles_done;  // number of complete 4-state cycles observed
    reg     started;
    reg [5:0] prev;

    initial begin
        errors = 0; idx = 0; cycles_done = 0; started = 1'b0;
        last_change = 0; prev = 6'b0;
    end

    // Sample on the falling edge (outputs are stable, no glitches)
    always @(negedge clk) begin
        if (started) begin

            // Check 3: never both green
            if (a_green && b_green) begin
                errors = errors + 1;
                $display("[%0t] ERROR: both roads GREEN", $time);
            end

            // Check 4: exactly one colour per road
            if ((a_red + a_yellow + a_green) != 1 ||
                (b_red + b_yellow + b_green) != 1) begin
                errors = errors + 1;
                $display("[%0t] ERROR: a road does not show exactly one colour", $time);
            end

            // Checks 1, 2, 5: sequence and duration on every change
            if (lights !== prev) begin
                elapsed = $time - last_change;
                if (elapsed != exp_dur[idx]) begin
                    errors = errors + 1;
                    $display("[%0t] ERROR: state %0d lasted %0d ns, expected %0d ns",
                             $time, idx+1, elapsed, exp_dur[idx]);
                end else begin
                    $display("[%0t] OK   : state %0d lasted %0d ns (%0d s)",
                             $time, idx+1, elapsed, elapsed/SEC);
                end
                idx = (idx + 1) % 4;
                if (lights !== exp_pat[idx]) begin
                    errors = errors + 1;
                    $display("[%0t] ERROR: wrong lights entering state %0d: got %b, expected %b",
                             $time, idx+1, lights, exp_pat[idx]);
                end
                if (idx == 0) begin
                    cycles_done = cycles_done + 1;
                    $display("[%0t] ---- full cycle %0d done, back in State 1 ----",
                             $time, cycles_done);
                end
                last_change = $time;
                prev        = lights;
            end
        end
    end

    // ---------------- Stimulus ------------------------------------------------
    integer target;

    initial begin
        $dumpfile("traffic_light.vcd");
        $dumpvars(0, tb_traffic_light_controller);

        // --- Power-up reset ---
        rst = 1'b1;
        repeat (2) @(posedge clk);
        @(negedge clk);
        if (lights !== exp_pat[0]) begin
            errors = errors + 1;
            $display("[%0t] ERROR: reset did not give State 1 (lights=%b)", $time, lights);
        end else
            $display("[%0t] OK   : reset -> State 1 (A Green, B Red)", $time);
        last_change = $time;
        prev        = lights;
        idx         = 0;
        started     = 1'b1;
        rst         = 1'b0;

        // --- Test A: two complete cycles with no intervention ---
        wait (cycles_done == 2);

        // --- Test B: reset in the middle of State 3, then check restart ---
        wait (idx == 2);
        #(3*SEC);                       // mid-way through State 3 (Road B green)
        started = 1'b0;
        @(negedge clk);
        rst = 1'b1;
        repeat (2) @(posedge clk);
        @(negedge clk);
        if (lights !== exp_pat[0]) begin
            errors = errors + 1;
            $display("[%0t] ERROR: mid-sequence reset did not return to State 1", $time);
        end else
            $display("[%0t] OK   : mid-sequence reset -> State 1", $time);
        idx = 0; last_change = $time; prev = lights; started = 1'b1;
        rst = 1'b0;
        target = cycles_done + 1;
        wait (cycles_done == target);   // one more full cycle after reset

        // --- Summary ---
        #(SEC);
        $display("==================================================");
        if (errors == 0) $display(" RESULT: ALL TESTS PASSED");
        else             $display(" RESULT: FAILED with %0d error(s)", errors);
        $display("==================================================");
        $finish;
    end

    // ---------------- Watchdog -----------------------------------------------
    initial begin
        #(300*SEC);
        $display("TIMEOUT: simulation did not finish");
        $finish;
    end

endmodule