module c4_top (
    input  wire       sys_clk,     
    input  wire [4:0] btn_raw,     
    output wire       buzzer,
    output wire       spi_ser,
    output wire       spi_srclk,
    output wire       spi_rclk
);

    wire sys_reset = ~btn_raw[0];

    localparam integer CLK_HZ     = 27_000_000;
    localparam integer TICK_DIV   = CLK_HZ / 100;
    localparam integer TICK_BITS  = $clog2(TICK_DIV + 1);

    reg [TICK_BITS-1:0] tick_ctr;
    reg                 tick_100hz;

    always @(posedge sys_clk or posedge sys_reset) begin
        if (sys_reset) begin
            tick_ctr   <= 0;
            tick_100hz <= 1'b0;
        end else begin
            if (tick_ctr >= TICK_DIV - 1) begin
                tick_ctr   <= 0;
                tick_100hz <= 1'b1;
            end else begin
                tick_ctr   <= tick_ctr + 1;
                tick_100hz <= 1'b0;
            end
        end
    end

    wire btn_s1_pulse;
    wire btn_s2_pulse; 
    wire btn_s3_pulse;
    wire btn_s4_pulse;

    debouncer #(.CLK_HZ(CLK_HZ), .DEBOUNCE_MS(20)) u_deb_s1 (
        .clk       (sys_clk),
        .reset     (sys_reset),
        .btn_raw   (btn_raw[1]),
        .btn_pulse (btn_s1_pulse)
    );
    debouncer #(.CLK_HZ(CLK_HZ), .DEBOUNCE_MS(20)) u_deb_s2 (
        .clk       (sys_clk),
        .reset     (sys_reset),
        .btn_raw   (btn_raw[2]),
        .btn_pulse (btn_s2_pulse)
    );
    debouncer #(.CLK_HZ(CLK_HZ), .DEBOUNCE_MS(20)) u_deb_s3 (
        .clk       (sys_clk),
        .reset     (sys_reset),
        .btn_raw   (btn_raw[3]),
        .btn_pulse (btn_s3_pulse)
    );
    debouncer #(.CLK_HZ(CLK_HZ), .DEBOUNCE_MS(20)) u_deb_s4 (
        .clk       (sys_clk),
        .reset     (sys_reset),
        .btn_raw   (btn_raw[4]),
        .btn_pulse (btn_s4_pulse)
    );

    reg s2_sync0, s2_sync1;
    always @(posedge sys_clk or posedge sys_reset) begin
        if (sys_reset) begin
            s2_sync0 <= 1'b1;
            s2_sync1 <= 1'b1;
        end else begin
            s2_sync0 <= btn_raw[2];
            s2_sync1 <= s2_sync0;
        end
    end
    wire s2_held = ~s2_sync1;

    wire [2:0] seq_progress;
    wire       seq_unlocked;
    wire       seq_matched;

    sequence_detector u_seq_det (
        .clk             (sys_clk),
        .reset           (sys_reset),
        .bit_in          (btn_s4_pulse ? 1'b1 : 1'b0), 
        .bit_valid       (btn_s3_pulse | btn_s4_pulse),
        .sequence_matched(seq_matched),
        .progress        (seq_progress)
    );

    wire [2:0] game_state;
    wire       load_timer;
    wire       main_count_down;
    wire       defuse_count_up;
    wire       defuse_counter_reset;
    wire       main_at_zero;
    wire       main_at_max;
    wire       defuse_at_max;

    game_fsm u_game_fsm (
        .clk                  (sys_clk),
        .reset                (sys_reset),
        .s1_pulse             (btn_s1_pulse),
        .s2_held              (s2_held),
        .sequence_matched     (seq_matched),
        .main_at_zero         (main_at_zero),
        .defuse_at_max        (defuse_at_max),
        .current_state        (game_state),
        .load_timer           (load_timer),
        .main_count_down      (main_count_down),
        .defuse_count_up      (defuse_count_up),
        .defuse_counter_reset (defuse_counter_reset),
        .seq_unlocked         (seq_unlocked)
    );

    wire [3:0] main_digit3, main_digit2, main_digit1, main_digit0;
    universal_counter #(
        .MAX_SECONDS   (40),
        .LOAD_SECONDS  (40),
        .LOAD_CENTS    (0),
        .MAX_UP_SECONDS(5)  
    ) u_main_counter (
        .clk        (sys_clk),
        .reset      (sys_reset),
        .tick       (tick_100hz),
        .load       (load_timer),
        .count_down (main_count_down),
        .count_up   (1'b0),         
        .digit3     (main_digit3),
        .digit2     (main_digit2),
        .digit1     (main_digit1),
        .digit0     (main_digit0),
        .at_zero    (main_at_zero),
        .at_maximum (main_at_max)              
    );

    wire defuse_reset_combined = sys_reset | defuse_counter_reset;
    universal_counter #(
        .MAX_SECONDS   (5),
        .LOAD_SECONDS  (0),
        .LOAD_CENTS    (0),
        .MAX_UP_SECONDS(5)
    ) u_defuse_counter (
        .clk        (sys_clk),
        .reset      (defuse_reset_combined),
        .tick       (tick_100hz),
        .load       (1'b0),
        .count_down (1'b0),
        .count_up   (defuse_count_up),
        .digit3     (),              
        .digit2     (),             
        .digit1     (),
        .digit0     (),
        .at_zero    (),
        .at_maximum (defuse_at_max)
    );

    audio_pwm #(.CLK_HZ(CLK_HZ)) u_audio (
        .clk          (sys_clk),
        .reset        (sys_reset),
        .game_state   (game_state),
        .seconds_tens (main_digit3),
        .seconds_ones (main_digit2),
        .buzzer       (buzzer)
    );

    spi_display_driver #(.CLK_HZ(CLK_HZ)) u_display (
        .clk          (sys_clk),
        .reset        (sys_reset),
        .game_state   (game_state),
        .digit3       (main_digit3),
        .digit2       (main_digit2),
        .digit1       (main_digit1),
        .digit0       (main_digit0),
        .seq_progress (seq_progress),
        .seq_unlocked (seq_unlocked),
        .spi_ser      (spi_ser),
        .spi_srclk    (spi_srclk),
        .spi_rclk     (spi_rclk)
    );
endmodule