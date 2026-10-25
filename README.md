# Smart Traffic Control System Using Verilog HDL

## Overview

This project implements a **Smart Traffic Control System using Verilog HDL**. The system uses a Finite State Machine (FSM) and a programmable timer to control traffic lights based on vehicle density and pedestrian crossing requests.

Unlike a basic fixed-timing traffic light controller, this design adapts the green-light duration according to the selected vehicle-density level. It also stores pedestrian requests and provides a dedicated pedestrian crossing phase.

The project demonstrates important digital design concepts, including sequential logic, FSM design, clock-based timing, modular RTL design, and simulation using a Verilog testbench.

## Features

- **FSM-based traffic control:** Controls the traffic-light sequence using four states.
- **Adaptive green-light timing:** Selects different green durations for low, medium, and high vehicle density.
- **Programmable timer:** Counts clock cycles and generates a timer-expiration signal.
- **Pedestrian request handling:** Stores pedestrian requests until the controller can serve them.
- **Dedicated pedestrian phase:** Activates the pedestrian crossing output while keeping the vehicle red light active.
- **Modular RTL architecture:** Separates the timer, FSM, top-level module, and testbench.
- **Simulation-based verification:** Uses a testbench to generate clock signals, vary vehicle density, apply pedestrian requests, and test reset behavior.

## System Architecture

The design consists of three primary hardware modules and one simulation testbench.

```text
               Vehicle Density
                      |
                      v
             +------------------+
             |                  |
             |   Traffic FSM    |<---------+
             |                  |          |
             +------------------+          |
                 |          ^              |
        timer_limit         | timer_expired |
                 |          |              |
                 v          |              |
             +------------------+           |
             |                  |-----------+
             |   Traffic Timer  |
             |                  |
             +------------------+

             FSM Output Signals
                      |
                      v
          Red / Yellow / Green /
             Pedestrian Active
```

### Module Description

| File | Description |
|---|---|
| `traffic_timer.v` | Implements a clock-driven counter and timer-expiration signal. |
| `traffic_fsm_final.v` | Implements the traffic-light FSM, state transitions, adaptive timing, and pedestrian-request handling. |
| `traffic_system_top_final.v` | Connects the FSM and timer to form the complete traffic controller. |
| `traffic_system_tb_final.v` | Testbench for simulating and observing the traffic controller. |

## Traffic-Light State Machine

The FSM contains four states:

| State | Vehicle Red | Vehicle Yellow | Vehicle Green | Pedestrian Active |
|---|---:|---:|---:|---:|
| GREEN | 0 | 0 | 1 | 0 |
| YELLOW | 0 | 1 | 0 | 0 |
| RED | 1 | 0 | 0 | 0 |
| PEDESTRIAN | 1 | 0 | 0 | 1 |

### State Transition Sequence

1. **GREEN:** Vehicles are allowed to move. The duration depends on vehicle density.
2. **YELLOW:** The yellow light is activated when the green timer expires.
3. **RED:** Vehicles stop. The controller checks for a pending pedestrian request when the red timer expires.
4. **PEDESTRIAN:** If a request is pending, the pedestrian crossing output is activated while the vehicle red light remains on. After the pedestrian timer expires, the FSM returns to GREEN.

If no pedestrian request is pending when the red timer expires, the FSM returns directly to GREEN.

## Adaptive Vehicle-Density Control

The green-light duration is selected using the `vehicle_density` input.

| Vehicle Density | Input | Green Duration |
|---|---|---:|
| Low | `2'b00` | 5 clock counts |
| Medium | `2'b01` | 10 clock counts |
| High | `2'b10` or `2'b11` | 20 clock counts |

This allows the controller to allocate more green time to higher traffic-density levels.

In the current implementation, `vehicle_density` is an input supplied externally. Automatic density detection using physical vehicle sensors is a potential future enhancement.

## Timer Operation

The timer uses a counter that increments on every rising edge of the clock.

The timer expires when the counter reaches the programmed terminal count:

```verilog
counter >= timer_limit - 1'b1
```

Since counting starts at zero, a timer limit of 5 produces expiration after five counting edges, assuming the timer starts from zero and the limit remains unchanged.

When the timer expires:

- The counter is cleared.
- `timer_expired` is asserted.
- The FSM uses the signal to determine whether to transition to the next state.

**Note:** The configured durations represent clock counts, not seconds. The actual duration depends on the clock frequency.

## Pedestrian Request Handling

The design includes a `ped_request_latched` register that stores pedestrian requests.

When a request is received, the latch is set. The controller checks the stored request at the end of the RED phase and transitions to PEDESTRIAN when appropriate.

This allows the controller to retain a short request rather than requiring the pedestrian button to remain asserted throughout the traffic cycle.

The current design accepts a logical pedestrian-request input. Physical button synchronization and debouncing can be added as future improvements.

## Testbench and Simulation

The testbench, `traffic_system_tb_final.v`, instantiates the top-level design and simulates its behavior.

The testbench performs the following operations:

1. Generates a clock with a 10 ns period.
2. Applies reset to initialize the controller.
3. Starts with low vehicle density.
4. Changes vehicle density to medium and high.
5. Generates a pedestrian request.
6. Applies reset again to test reset behavior.
7. Uses `$monitor` to display simulation time, input values, and traffic-light outputs.
8. Ends the simulation using `$finish`.

### Example Clock Configuration

```verilog
initial clk = 0;
always #5 clk = ~clk;
```

This produces a 10 ns clock period, equivalent to a simulated frequency of 100 MHz.

### Simulation Tools

The Verilog source files can be simulated using tools such as:

- Xilinx Vivado Simulator
- Icarus Verilog
- ModelSim or QuestaSim

For simulation, select `traffic_system_tb_final` as the simulation top module. For FPGA synthesis, select `traffic_system_top_final` as the design top module.

## How to Run the Simulation

### Using Icarus Verilog

Ensure Icarus Verilog and GTKWave are installed if you want waveform visualization.

Compile the project:

```bash
iverilog -g2012 -s traffic_system_tb_final \
  -o traffic_sim \
  traffic_timer.v \
  traffic_fsm_final.v \
  traffic_system_top_final.v \
  traffic_system_tb_final.v
```

Run the simulation:

```bash
vvp traffic_sim
```

To save waveforms, add the following inside the testbench's `initial` block:

```verilog
$dumpfile("traffic_system.vcd");
$dumpvars(0, traffic_system_tb_final);
```

Then open the generated waveform:

```bash
gtkwave traffic_system.vcd
```

The waveform can be used to inspect state-dependent outputs, timer expiration, density changes, pedestrian requests, and reset behavior.

## Future Enhancements

The following features can extend the current design:

- **Automatic vehicle-density detection:** Integrate vehicle sensors and a density-classification module.
- **Pedestrian-button debouncing:** Filter mechanical button bounce before passing requests to the FSM.
- **Input synchronization:** Add synchronizer flip-flops for asynchronous external signals.
- **Safety interlocks:** Add independent protection against conflicting signal outputs and define safe fault responses.
- **Improved verification:** Add assertions and test scenarios for all state transitions, timer values, and pedestrian requests.
- **Real-time timing:** Use a clock divider or programmable timing unit to generate durations measured in seconds.
- **FPGA implementation:** Map the design to an FPGA board and connect appropriate LEDs, switches, sensors, and buttons.

These are proposed extensions and are not assumed to be implemented in the current RTL.

## Learning Outcomes

This project provides practical experience with:

- Verilog HDL and RTL design
- Finite State Machines
- Sequential and combinational logic
- Counters and programmable timers
- Parameterized timing logic
- Modular hardware design
- Testbench development and simulation
- Digital-system debugging and verification

## Limitations

This is an educational traffic-controller prototype. It does not currently provide automatic physical vehicle sensing, button debouncing, or a complete independent safety system for real-world traffic signals.

The design should not be connected to real road traffic infrastructure without appropriate safety engineering, independent interlocks, fault handling, and formal validation.

## License

Add a license file if you intend to distribute or reuse this project publicly. For example, the MIT License can be used if you want to permit broad reuse under its terms.
