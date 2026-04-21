// universal_counter.v
// Programmable BCD counter satisfying the "Programmable Counter" rubric requirement.
// Supports three operations:
//   LOAD      : synchronously load a preset value into the counter
//   COUNT_DOWN: decrement one centisecond tick per enable pulse, wrap-aware
//   COUNT_UP  : increment one centisecond tick per enable pulse, wrap-aware
//
// The counter tracks time as two independent fields:
//   seconds      (0–MAX_SECONDS, displayed on left two digits)
//   centiseconds (0–99,         displayed on right two digits)
//
// Each BCD field is stored as two 4-bit nibbles (tens, ones).
//
// Parameters:
//   MAX_SECONDS     - upper bound for seconds field (e.g. 40 for a 40s timer)
//   LOAD_SECONDS    - preset value for seconds on LOAD (e.g. 40)
//   LOAD_CENTS      - preset value for centiseconds on LOAD (e.g. 0)
//   MAX_UP_SECONDS  - maximum seconds for up-counting defuse timer (e.g. 5)
//
// Outputs:
//   digit3 - leftmost  (seconds tens)
//   digit2 - second    (seconds ones)
//   digit1 - third     (centiseconds tens)
//   digit0 - rightmost (centiseconds ones)
//   at_zero    - HIGH when both seconds and centiseconds are 00:00
//   at_maximum - HIGH when up-counter has reached MAX_UP_SECONDS

module universal_counter #(
    parameter integer MAX_SECONDS    = 40,
    parameter integer LOAD_SECONDS   = 40,
    parameter integer LOAD_CENTS     = 0,
    parameter integer MAX_UP_SECONDS = 5
) (
    input  wire       clk,
    input  wire       reset,       // asynchronous active-HIGH reset
    input  wire       tick,        // 100Hz enable pulse (one per centisecond)
    input  wire       load,        // synchronous parallel load
    input  wire       count_down,  // enable down-counting (when tick fires)
    input  wire       count_up,    // enable up-counting   (when tick fires)

    output reg  [3:0] digit3,      // seconds tens
    output reg  [3:0] digit2,      // seconds ones
    output reg  [3:0] digit1,      // centiseconds tens
    output reg  [3:0] digit0,      // centiseconds ones

    output wire       at_zero,     // asserted when counter == 00:00
    output wire       at_maximum   // asserted when up-counter == MAX_UP_SECONDS:00
);

    // Decode at_zero and at_maximum from the BCD digit registers.
    assign at_zero   = (digit3 == 0) && (digit2 == 0) &&
                       (digit1 == 0) && (digit0 == 0);

    // at_maximum: seconds == MAX_UP_SECONDS and centiseconds == 00
    // We compare the full seconds value reconstructed from BCD.
    wire [6:0] current_seconds = digit3 * 10 + digit2;
    assign at_maximum = (current_seconds == MAX_UP_SECONDS[6:0]) &&
                        (digit1 == 0) && (digit0 == 0);

    // Helper: reconstruct full centisecond count for bounds checking.
    wire [6:0] current_cents = digit1 * 10 + digit0;

always @(posedge clk or posedge reset) begin
        if (reset) begin
            // FIX: Default to the preset time so the bomb doesn't instantly explode!
            digit3 <= LOAD_SECONDS / 10;
            digit2 <= LOAD_SECONDS % 10;
            digit1 <= LOAD_CENTS   / 10;
            digit0 <= LOAD_CENTS   % 10;
        end else if (load) begin
            // Parallel load: split LOAD_SECONDS and LOAD_CENTS into BCD nibbles.
            digit3 <= LOAD_SECONDS / 10;
            digit2 <= LOAD_SECONDS % 10;
            digit1 <= LOAD_CENTS   / 10;
            digit0 <= LOAD_CENTS   % 10;
        end else if (tick) begin
            if (count_down && !at_zero) begin
                // -- Decrement centiseconds, borrow into seconds --
                if (digit1 == 0 && digit0 == 0) begin
                    // Centiseconds at 00: borrow one second.
                    // Seconds cannot be 00 here because !at_zero guarantees
                    // at least one second is non-zero.
                    digit1 <= 4'd9;
                    digit0 <= 4'd9;
                    // Decrement seconds BCD.
                    if (digit2 == 0) begin
                        digit2 <= 4'd9;
                        digit3 <= digit3 - 1;
                    end else begin
                        digit2 <= digit2 - 1;
                    end
                end else begin
                    // Decrement centiseconds only.
                    if (digit0 == 0) begin
                        digit0 <= 4'd9;
                        digit1 <= digit1 - 1;
                    end else begin
                        digit0 <= digit0 - 1;
                    end
                end

            end else if (count_up && !at_maximum) begin
                // -- Increment centiseconds, carry into seconds --
                if (digit0 == 4'd9) begin
                    digit0 <= 4'd0;
                    if (digit1 == 4'd9) begin
                        digit1 <= 4'd0;
                        // Carry into seconds.
                        if (digit2 == 4'd9) begin
                            digit2 <= 4'd0;
                            digit3 <= digit3 + 1;
                        end else begin
                            digit2 <= digit2 + 1;
                        end
                    end else begin
                        digit1 <= digit1 + 1;
                    end
                end else begin
                    digit0 <= digit0 + 1;
                end
            end
            // If neither count_down nor count_up, or boundary reached: hold.
        end
    end

endmodule
