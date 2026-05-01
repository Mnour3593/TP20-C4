`timescale 1ns / 1ps

module tb_counter;

    reg clk;
    reg reset;
    reg tick;
    reg load;
    reg count_down;
    reg count_up;

    wire [3:0] digit3, digit2, digit1, digit0;
    wire at_zero, at_maximum;

    universal_counter uut (
        .clk(clk), .reset(reset), .tick(tick), .load(load),
        .count_down(count_down), .count_up(count_up),
        .digit3(digit3), .digit2(digit2), .digit1(digit1), .digit0(digit0),
        .at_zero(at_zero), .at_maximum(at_maximum)
    );
initial begin
$dumpfile("test.vcd"); 
$dumpvars(0, tb_counter);

    clk = 0;
    reset = 1;
    tick = 0;
    load = 0;
    count_down = 0;
    count_up = 0;
    #31 reset = 0;

    $monitor("Time: %0t - Count: %d%d - %d%d - at_Zero: %b - at_Max: %b", $time, digit3, digit2, digit1, digit0, at_zero, at_maximum);
count_up = 1;
repeat (5) begin
send_tick;
end
count_up = 0;
#31;

count_down = 1;
repeat (5) begin
    send_tick;
end
count_down = 0;
#31;

load = 1;
#31 load = 0;

    #100 $finish;
end
initial begin
    forever begin
    #5 clk = ~clk;
end
end
task send_tick;
    begin
        @(negedge clk);
        #31 tick = 1;
        @(negedge clk);
        #31 tick = 0;
    end
endtask


endmodule
