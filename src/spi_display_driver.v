module spi_display_driver #(
    parameter integer CLK_HZ = 27_000_000
) (
    input  wire       clk,
    input  wire       reset,
    input  wire [2:0] game_state,
    input  wire [3:0] digit3, digit2, digit1, digit0,
    input  wire [2:0] seq_progress, 
    input  wire       seq_unlocked, 
    output reg        spi_ser, spi_srclk, spi_rclk
);

    // 7-segment encoding: {DP, G, F, E, D, C, B, A}
    function [7:0] get_num_pattern;
        input [3:0] bcd;
        case (bcd)
            4'd0: get_num_pattern = 8'b0011_1111;
            4'd1: get_num_pattern = 8'b0000_0110;
            4'd2: get_num_pattern = 8'b0101_1011;
            4'd3: get_num_pattern = 8'b0100_1111;
            4'd4: get_num_pattern = 8'b0110_0110;
            4'd5: get_num_pattern = 8'b0110_1101;
            4'd6: get_num_pattern = 8'b0111_1101;
            4'd7: get_num_pattern = 8'b0000_0111;
            4'd8: get_num_pattern = 8'b0111_1111;
            4'd9: get_num_pattern = 8'b0110_1111;
            default: get_num_pattern = 8'b0000_0000;
        endcase
    endfunction

    // 1kHz Mux Tick
    localparam integer MUX_PERIOD = CLK_HZ / 4000; 
    reg [12:0] mux_ctr = 0;
    reg [1:0]  active_digit = 0;
    wire mux_tick = (mux_ctr == MUX_PERIOD - 1);

    always @(posedge clk) begin
        if (mux_tick) begin
            mux_ctr <= 0;
            active_digit <= active_digit + 1;
        end else mux_ctr <= mux_ctr + 1;
    end

    // 100kHz SPI Governor
    localparam integer SPI_HALF = CLK_HZ / 200_000;
    reg [7:0] spi_clk_ctr = 0;
    wire spi_tick = (spi_clk_ctr == SPI_HALF - 1);

    always @(posedge clk) begin
        if (spi_tick) spi_clk_ctr <= 0;
        else spi_clk_ctr <= spi_clk_ctr + 1;
    end

    // Display Logic Resolver
    reg [7:0] cathode_mask;
    reg [7:0] base_seg;
    reg [7:0] final_seg;

    always @(*) begin
        // 1. Resolve Cathodes (Which digit is on?)
        case (active_digit)
            2'd0: cathode_mask = 8'b1111_1110; // Leftmost
            2'd1: cathode_mask = 8'b1111_1101; 
            2'd2: cathode_mask = 8'b1111_1011; 
            2'd3: cathode_mask = 8'b1111_0111; // Rightmost
        endcase

        // 2. Resolve Text/Numbers based on Game State
        case (game_state)
            3'd0: base_seg = 8'b0100_0000; // IDLE: Dashes
            3'd1, 3'd2: // ARMED or DEFUSING: Numbers
                case (active_digit)
                    2'd0: base_seg = get_num_pattern(digit3);
                    2'd1: base_seg = get_num_pattern(digit2);
                    2'd2: base_seg = get_num_pattern(digit1);
                    2'd3: base_seg = get_num_pattern(digit0);
                endcase
            3'd3: // EXPLODED: "b E E P"
                case (active_digit)
                    2'd0: base_seg = 8'b0111_1100; // b
                    2'd1: base_seg = 8'b0111_1001; // E
                    2'd2: base_seg = 8'b0111_1001; // E
                    2'd3: base_seg = 8'b0111_0011; // P
                endcase
            3'd4: // DEFUSED: "G oo d"
                case (active_digit)
                    2'd0: base_seg = 8'b0011_1101; // G
                    2'd1: base_seg = 8'b0101_1100; // o
                    2'd2: base_seg = 8'b0101_1100; // o
                    2'd3: base_seg = 8'b0101_1110; // d
                endcase
            default: base_seg = 8'b0000_0000;
        endcase

        // 3. Inject Decimal Points for Sequence Progress
        final_seg = base_seg;
        case (active_digit)
            2'd0: if (seq_progress >= 1 || seq_unlocked) final_seg[7] = 1'b1;
            2'd1: if (seq_progress >= 2 || seq_unlocked) final_seg[7] = 1'b1;
            2'd2: if (seq_progress >= 3 || seq_unlocked) final_seg[7] = 1'b1;
            2'd3: if (seq_unlocked) final_seg[7] = 1'b1;
        endcase
    end

    // Tear-Free, Setup-Time-Safe SPI State Machine
    reg [15:0] shift_reg;
    reg [4:0]  bit_index;
    reg [1:0]  spi_state;
    localparam S_IDLE = 0, S_SHIFT = 1, S_LATCH = 2;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            spi_state <= S_IDLE;
            spi_rclk  <= 0;
            spi_srclk <= 0;
            spi_ser   <= 0;
        end else if (spi_tick) begin
            case (spi_state)
                S_IDLE: begin
                    if (mux_tick) begin
                        // THE FIX: Segments sent FIRST (overflows to Left IC), Cathodes SECOND (stays in Right IC)
                        shift_reg <= {final_seg, cathode_mask};
                        
                        // Pre-load the data pin with the MSB of the segments
                        spi_ser   <= final_seg[7]; 
                        
                        bit_index <= 16;
                        spi_state <= S_SHIFT;
                        spi_rclk  <= 0;
                    end
                end
                S_SHIFT: begin
                    if (spi_srclk == 0) begin
                        // Rising edge: Data has been stable for 5us, IC reads it safely
                        spi_srclk <= 1;
                        bit_index <= bit_index - 1;
                    end else begin
                        // Falling edge: Drop clock and shift the next bit to the data pin
                        spi_srclk <= 0;
                        if (bit_index == 0) begin
                            spi_state <= S_LATCH;
                        end else begin
                            shift_reg <= shift_reg << 1;
                            spi_ser   <= shift_reg[14];
                        end
                    end
                end
                S_LATCH: begin
                    spi_rclk  <= 1;
                    spi_state <= S_IDLE;
                end
            endcase
        end
    end
endmodule