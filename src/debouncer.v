// debouncer.v
// 20ms glitch filter for active-low mechanical buttons.
// Produces a single-clock-cycle HIGH pulse on the rising edge of the
// debounced signal (i.e. the moment the button press is confirmed clean).
//
// Parameters:
//   CLK_HZ     - system clock frequency in Hz (default 27 MHz)
//   DEBOUNCE_MS- settling window in milliseconds (default 20 ms)
//
// The counter resets any time the raw input changes. Only when the input
// holds stable for DEBOUNCE_MS do we commit the new level and emit a pulse.

module debouncer #(
    parameter integer CLK_HZ      = 27_000_000,
    parameter integer DEBOUNCE_MS = 20
) (
    input  wire clk,
    input  wire reset,       // asynchronous active-HIGH reset
    input  wire btn_raw,     // raw active-LOW button from pin
    output reg  btn_pulse    // single-cycle HIGH pulse on clean press
);

    // Threshold: number of clock cycles that constitute one debounce window.
    localparam integer THRESHOLD = (CLK_HZ / 1000) * DEBOUNCE_MS;

    // Counter width: ceil(log2(THRESHOLD + 1))
    localparam integer CTR_BITS = $clog2(THRESHOLD + 1);

    // Two-stage synchroniser to prevent metastability on the async button pin.
    reg sync_0, sync_1;

    // Debounce counter and stable-state tracking.
    reg [CTR_BITS-1:0] counter;
    reg                stable;   // last committed (debounced) level
    reg                stable_d; // one-cycle delay for edge detection

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sync_0   <= 1'b1; // buttons idle HIGH (active-low)
            sync_1   <= 1'b1;
            counter  <= 0;
            stable   <= 1'b1;
            stable_d <= 1'b1;
            btn_pulse <= 1'b0;
        end else begin
            // -- Synchroniser --
            sync_0 <= btn_raw;
            sync_1 <= sync_0;

            // -- Debounce counter --
            // Any change in the synchronised input resets the counter.
            if (sync_1 != stable) begin
                counter <= counter + 1;
                if (counter == THRESHOLD - 1) begin
                    // Input held stable long enough; commit new level.
                    stable  <= sync_1;
                    counter <= 0;
                end
            end else begin
                counter <= 0;
            end

            // -- Edge detection: rising edge of debounced signal = button released cleanly.
            // A button PRESS in active-low land is a falling edge on btn_raw but a
            // rising edge on the inverted (logical) signal. We detect the moment
            // 'stable' transitions from 1 -> 0 (button physically pressed) by
            // comparing stable with its one-cycle-delayed version.
            // Pulse fires on falling edge of stable (button pressed).
            stable_d  <= stable;
            btn_pulse <= stable_d & ~stable; // was HIGH, now LOW → pressed
        end
    end

endmodule
