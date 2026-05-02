# TP20-C4: Programmable Counter and Sequence Detector

This project provides a hardware implementation of a C4 Timer on a Tang Primer 20K FPGA, developed for my Computer Architecture and Organization course. The design integrates multiple requirements into a single System-on-Chip (SoC) architecture.

## Syllabus Objectives Fulfilled

1. **Programmable Counter:** Implements synchronous LOAD, DOWN counting, and UP counting.
2. **Sequence Detector:** Utilizes a Mealy FSM to detect a specific binary input sequence (1-0-1-1).

## Hardware Target & Requirements

- **Board:** Sipeed Tang Primer 20K Dock FPGA
- **Toolchain:** Gowin IDE
- **Custom Shield:** The project requires building a custom circuit. The circuit interfaces a 4-Digit 7-Segment display via dual daisy-chained 74HC595 shift registers and includes a direct-drive passive audio buzzer. 

![Wiring Diagram Placeholder](docs/wiring_diagram.png) 
*(Note: Replace with actual path to wiring diagram once drawn)*

## Repository Structure

- `C4.gprj`: Gowin project file. Do not commit local `.gprj` changes unless adding source files.
- `src/`
  - `c4_top.v`: Top-level integration.
  - `game_fsm.v`: Game state machine.
  - `sequence_detector.v`: Mealy FSM logic.
  - `universal_counter.v`: BCD up/down counter.
  - `debouncer.v`: Mechanical input debouncing.
  - `audio_pwm.v`: PWM audio generation.
  - `spi_display_driver.v`: SPI display interface.
  - `pin.cst`: Physical IO constraints.

## Build Instructions (Gowin IDE)

1. Open `TP20-C4.gprj` in the Gowin IDE.
2. Set the project target to `GW2A-LV18PG256C8/I7`.
3. Run Synthesis, followed by Place & Route.
4. Open the Programmer tool.
5. Select "SRAM Program" for testing or "Flash" for deployment.
6. Program the board to verify hardware behavior.
