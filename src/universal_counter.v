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

    
    // 1. starting point (efficient version)
    
    localparam [3:0] PRESET_D3 = LOAD_SECONDS / 10;
    localparam [3:0] PRESET_D2 = LOAD_SECONDS % 10;
    localparam [3:0] PRESET_D1 = LOAD_CENTS / 10;
    localparam [3:0] PRESET_D0 = LOAD_CENTS % 10;


    
    // 2. stop signals (at_zero ve at_maximum)
    
    // at_zero: 
    assign at_zero = (digit3 == 0) && (digit2 == 0) && (digit1 == 0) && (digit0 == 0);
    
    // at_maximum: 
    wire [6:0] current_seconds = (digit3 * 10) + digit2;
    assign at_maximum = (current_seconds == MAX_UP_SECONDS) && (digit1 == 0) && (digit0 == 0);

    // 3. wire betwween seconds and cents 
    // for down counting, cent must 00 to decrease 1 seconds
    wire cents_at_zero = (digit1 == 0 && digit0 == 0); 
    
    // for up counting, cent must 99 to inccrease 1 seconds
    wire cents_at_max  = (digit1 == 9 && digit0 == 9); 


    
    //  (CENTS) 
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // reset --> go back 
            digit1 <= PRESET_D1;
            digit0 <= PRESET_D0;
        end else if (load) begin
            // lload ---> go back 
            digit1 <= PRESET_D1;
            digit0 <= PRESET_D0;
        end else if (tick) begin
            
            //  Cents count down
            if (count_down && !at_zero) begin
                if (digit0 == 0) begin
                    digit0 <= 9;
                    if (digit1 == 0) digit1 <= 9;
                    else             digit1 <= digit1 - 1;
                end else begin
                    digit0 <= digit0 - 1;
                end
            end 
            
            //  Cents forward 
            else if (count_up && !at_maximum) begin
                if (digit0 == 9) begin
                    digit0 <= 0;
                    if (digit1 == 9) digit1 <= 0;
                    else             digit1 <= digit1 + 1;
                end else begin
                    digit0 <= digit0 + 1;
                end
            end
            
        end
    end

    // (SECONDS) 
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            digit3 <= PRESET_D3;
            digit2 <= PRESET_D2;
        end else if (load) begin
            digit3 <= PRESET_D3;
            digit2 <= PRESET_D2;
        end else if (tick) begin
            
            // count down
            // only work when cents are at zero
            if (count_down && !at_zero && cents_at_zero) begin
                if (digit2 == 0) begin
                    digit2 <= 9;
                    if (digit3 != 0) digit3 <= digit3 - 1; 
                end else begin
                    digit2 <= digit2 - 1;
                end
            end 
            
            // forward
            // only work when cents at max
            else if (count_up && !at_maximum && cents_at_max) begin
                if (digit2 == 9) begin
                    digit2 <= 0;
                    digit3 <= digit3 + 1;
                end else begin
                    digit2 <= digit2 + 1;
                end
            end
            
        end
    end

endmodule
