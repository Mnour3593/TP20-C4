module sequence_detector (
    input  wire clk,
    input  wire reset,
    input  wire bit_in,        
    input  wire bit_valid,    
    output reg  sequence_matched,
    output reg  [2:0] progress
);
    localparam [1:0]
        S_IDLE = 2'b00,
        S1     = 2'b01,
        S2     = 2'b10,
        S3     = 2'b11;

    reg [1:0] current_state, next_state;

   
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= S_IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    always @(*) begin
      
        next_state = current_state;

        if (bit_valid) begin
            case (current_state)
                S_IDLE: next_state = bit_in ? S1 : S_IDLE;
                S1:     next_state = bit_in ? S1 : S2;
                S2:     next_state = bit_in ? S3 : S_IDLE;
                S3:     next_state = bit_in ? S1 : S2;
                default: next_state = S_IDLE;
            endcase
        end
    end

    always @(*) begin
       
        sequence_matched = 1'b0;
        progress         = {1'b0, current_state}; 

        if (bit_valid) begin
            if (current_state == S3 && bit_in == 1'b1) begin
                sequence_matched = 1'b1; 
            end
        end
    end

endmodule