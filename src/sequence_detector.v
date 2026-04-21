module sequence_detector (
    input  wire clk,
    input  wire reset,
    input  wire bit_in,       
    input  wire bit_valid,    
    output reg  sequence_matched,
    output reg  [2:0] progress
);
    localparam [3:0]
        S_IDLE = 4'b0001, 
        S1     = 4'b0010, 
        S2     = 4'b0100, 
        S3     = 4'b1000; 

    reg [3:0] state, next_state;

    always @(posedge clk or posedge reset) begin
        if (reset) state <= S_IDLE;
        else state <= next_state;
    end

    // Translates the FSM state into the dot progress bar
    always @(*) begin
        case (state)
            S_IDLE: progress = 3'd0;
            S1:     progress = 3'd1;
            S2:     progress = 3'd2;
            S3:     progress = 3'd3;
            default: progress = 3'd0;
        endcase
    end

    always @(*) begin
        next_state = state;
        sequence_matched = 1'b0;
        
        if (bit_valid) begin
            case (state)
                S_IDLE: next_state = bit_in ? S1 : S_IDLE;
                S1:     next_state = bit_in ? S1 : S2; 
                S2:     next_state = bit_in ? S3 : S_IDLE; 
                S3: begin
                    if (bit_in) begin
                        sequence_matched = 1'b1; 
                        next_state = S1;         
                    end else begin
                        next_state = S2;         
                    end
                end
                default: next_state = S_IDLE;
            endcase
        end
    end
endmodule