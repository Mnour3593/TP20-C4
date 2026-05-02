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

## Simulation Instructions

Testbenches allow you to verify module behavior before deploying to hardware. Pre-configured GTKWave signal layouts are included for easy waveform analysis.

### Prerequisites
- **Icarus Verilog**: `iverilog` compiler
- **VVP**: Verilog simulation runtime
- **GTKWave**: Waveform viewer

### Running Simulations from VS Code

1. Open `scripts/run_testbenches.ps1` in the editor.
2. Click the **▶ Run** button (top-right) or press `Ctrl+Alt+N`.
3. Two GTKWave windows will open automatically with pre-loaded signal layouts:
   - **tb_counter.vcd**: Counter up/down/load functionality
   - **tb_sequence_detector.vcd**: 1011 sequence detection with state tracking

### Testbench Descriptions

#### `tb_counter.v` (Universal Counter)
Tests the 4-digit BCD counter with:
- **Reset**: Returns counter to preset value (40:00)
- **Count Up**: Increments counter by 10 ms per tick
- **Count Down**: Decrements counter by 10 ms per tick
- **Load**: Restores counter to LOAD_SECONDS:LOAD_CENTS

**Signals displayed**: `clk`, `tick`, `load`, `count_down`, `digit2/1/0` (decimal), `at_zero`, `at_maximum`

#### `tb_sequence_detector.v` (Sequence Detector FSM)
Tests the Mealy FSM that detects the bit sequence **1-0-1-1**:
- **Normal Match**: Drives 1011 and verifies `sequence_matched` pulse
- **Mismatch Recovery**: Drives 1010 to verify state rollback
- **Pause Handling**: Disables `bit_valid` to freeze state machine, then resumes
- **Async Reset**: Verifies reset clears all outputs mid-sequence

**Signals displayed**: `clk`, `reset`, `bit_in`, `bit_valid`, `current_state` (binary), `sequence_matched`

