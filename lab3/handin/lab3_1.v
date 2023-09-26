module lab3_1
(
    input clk,
    input rst,
    input en,
    input speed,
    output [15:0] led
);

wire myclk, myclk24, myclk27;
reg [15:0] led;
reg [15:0] next_led;

clock_divider #(
    .n(24)
)   c1 (
    .clk(clk),
    .clk_div(myclk24)
);

clock_divider #(
    .n(27)
)   c2 (
    .clk(clk),
    .clk_div(myclk27)
);

assign myclk = speed ? myclk27 : myclk24;

always @(posedge myclk or posedge rst) begin
    if(rst) begin
        led <= 16'b1000000000000000;
    end
    else begin
        led <= next_led;
    end
end

always @* begin
    if(en == 0) begin
        next_led = led;
    end
    else begin
        if(led == 16'b000000000000001) begin
            next_led = 16'b1000000000000000;
        end
        else begin
            next_led = led >> 1;
        end
    end
end

endmodule

module clock_divider #(parameter n = 25)
(
    input clk,
    output clk_div
);

reg [n-1:0] num = 0;
wire [n-1:0] next_num;

always @(posedge clk) begin
    num <= next_num;
end

assign next_num = num + 1;
assign clk_div = num[n-1];

endmodule
