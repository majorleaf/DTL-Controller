# Task 1 – Independent Research: FSMs, Clocks and Counters

## 1. What is a Finite State Machine (FSM)?
An FSM is a mathematical model of a system that can be in **exactly one of a finite number of states
at any time**. It changes state in response to inputs (or, in a timer-driven design, to events such as
"the counter has finished"). It is "finite" because the number of states is fixed.

Digital FSMs are built from:
1. a **state register** (flip-flops) that stores the current state,
2. **next-state logic** (combinational) that decides what the next state is,
3. **output logic** (combinational) that produces the outputs.

FSMs are ideal for controllers that follow a defined sequence, such as traffic lights, vending machines and protocol handlers.

## 2. States and state transitions
- A **state** is a distinct condition of the system. Here: *Road A green*, *Road A yellow*,
  *Road B green*, *Road B yellow*.
- A **transition** is a move from one state to another, triggered by a condition (here: "the
  state's time has elapsed") and synchronised to a clock edge.
- A **state diagram** draws states as circles and transitions as arrows. A **state transition
  table** lists *current state → condition → next state → outputs*.
- A **reset** forces the FSM into a known initial state when the circuit powers up.

## 3. Moore vs Mealy machines
| Feature | Moore | Mealy |
|---|---|---|
| Outputs depend on | Current **state only** | Current state **and inputs** |
| Output timing | Change only at clock edges (glitch-free) | Can change as soon as an input changes |
| Number of states | Usually more | Usually fewer |
| Typical use | Controllers needing stable outputs | Fast reaction to inputs |

**Our choice: Moore.** The lights depend only on which state we are in, and a traffic signal must never
glitch (a brief spurious green would be unsafe). The design has no external inputs other than clock and reset, so Moore is the natural fit.

## 4. Implementing an FSM in Verilog
A common, safe style is the **three-block (three-process) FSM**:
1. `always @(posedge clk)` – state register (with reset). Uses non-blocking `<=`.
2. `always @(*)` – next-state logic (`case (state)`). Uses blocking `=`.
3. `always @(*)` – output logic (Moore: `case (state)`).

States are given names with `localparam` so the code is readable. A `default` branch makes the machine recover to a safe
state if it ever lands in an unused encoding. See `src/traffic_light_controller.v`.

## 5. What is a digital clock and why do sequential circuits need it?
A clock is a periodic square wave. Sequential circuits contain memory elements (flip-flops) that
update **only on a clock edge** (e.g. rising edge). The clock:
- **synchronises** all state changes so they happen together,
- gives the circuit a **time reference** (period = 1 / frequency),
- prevents the circuit from reacting to unstable intermediate values of combinational logic.

Without a clock there would be no defined moment at which the FSM samples its inputs and updates its state.

## 6. Using a counter to measure time
Each clock period lasts a known time, so counting clock cycles measures time:

```
cycles_needed = time_in_seconds × clock_frequency_in_Hz
```

Example with a 50 MHz clock: 10 s → 10 × 50,000,000 = 500,000,000 cycles; 3 s → 150,000,000 cycles.
The counter increments every rising edge; when it reaches `cycles_needed − 1` the FSM moves to the
next state and the counter is cleared. A 32-bit counter (max ≈ 4.29 × 10⁹) is large enough.
For simulation we use a tiny clock frequency parameter (`CLK_FREQ = 10`) so that "10 seconds" is only 100 clock cycles.

## 7. References (verify and keep only what you used)
1. HDLBits – Verilog practice, FSM section: https://hdlbits.01xz.net/wiki/Main_Page
2. Nandland – Verilog/FPGA tutorials (state machines, counters): https://nandland.com/
3. EDA Playground – online simulator: https://www.edaplayground.com/
4. S. Harris & D. Harris, *Digital Design and Computer Architecture*, Morgan Kaufmann – chapter on Finite State Machines.
5. C. E. Cummings, "Coding and Scripting Techniques for FSM Designs with Synthesis-Optimized, Glitch-Free Outputs", SNUG Boston 2000 – FSM coding styles (Moore outputs).
6. IEEE Std 1364-2005, *IEEE Standard for Verilog Hardware Description Language*.
7. G. H. Mealy (1955) and E. F. Moore (1956) – original papers defining the two machine types.