module game_fsm (
    input  wire clk,
    input  wire reset,
    input  wire s1_pulse,
    input  wire s2_held,
    input  wire sequence_matched,
    input  wire main_at_zero,
    input  wire defuse_at_max,
    output reg  [2:0] current_state,
    output reg  load_timer,
    output reg  main_count_down,
    output reg  defuse_count_up,
    output reg  defuse_counter_reset,
    output reg  seq_unlocked
);
    localparam [2:0]
        ST_IDLE     = 3'd0,
        ST_ARMED    = 3'd1,
        ST_DEFUSING = 3'd2,
        ST_EXPLODED = 3'd3,
        ST_DEFUSED  = 3'd4;

    reg [2:0] state, next_state;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            seq_unlocked <= 1'b0;
        end else begin
            if (state == ST_IDLE)
                seq_unlocked <= 1'b0;
            else if (sequence_matched)
                seq_unlocked <= 1'b1;
            
            if (state == ST_DEFUSED || state == ST_EXPLODED)
                seq_unlocked <= 1'b0;
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset)
            state <= ST_IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case (state)
            ST_IDLE: begin
                if (s1_pulse) next_state = ST_ARMED;
            end
            ST_ARMED: begin
                if (main_at_zero) next_state = ST_EXPLODED;
                else if (s2_held && seq_unlocked) next_state = ST_DEFUSING;
            end
            ST_DEFUSING: begin
                if (main_at_zero) next_state = ST_EXPLODED;
                else if (defuse_at_max) next_state = ST_DEFUSED;
                else if (!s2_held) next_state = ST_ARMED;
            end
            ST_EXPLODED: ; 
            ST_DEFUSED:  ; 
            default: next_state = ST_IDLE;
        endcase
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state        <= ST_IDLE;
            load_timer           <= 1'b0;
            main_count_down      <= 1'b0;
            defuse_count_up      <= 1'b0;
            defuse_counter_reset <= 1'b1;
        end else begin
            current_state <= next_state;
            load_timer           <= 1'b0;
            main_count_down      <= 1'b0;
            defuse_count_up      <= 1'b0;
            defuse_counter_reset <= 1'b0;

            case (next_state)
                ST_IDLE: defuse_counter_reset <= 1'b1;
                ST_ARMED: begin
                    main_count_down <= 1'b1;
                    if (state == ST_IDLE && s1_pulse)
                        load_timer <= 1'b1;
                end
                ST_DEFUSING: begin
                    main_count_down <= 1'b1;
                    defuse_count_up <= 1'b1;
                end
                ST_EXPLODED: ;
                ST_DEFUSED: ;
                default: ;
            endcase
        end
    end
endmodule