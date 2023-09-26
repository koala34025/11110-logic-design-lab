module lab4_2 ( 
    input wire clk,
    input wire rst, 
    input wire start,
    input wire direction,
    input wire increase,
    input wire decrease,
    input wire select,
    output reg [3:0] DIGIT,
    output reg [6:0] DISPLAY,
    output wire max,
    output wire min,
    output reg d2,
    output reg d1,
    output reg d0
 ); 

wire [15:0] led;

assign max = counter == MAX ? 1 : 0;
assign min = counter == MIN ? 1 : 0;
// max = increase_1pulse;
//assign min = decrease_1pulse;

wire start_debounced;
debounce db1 (.pb_debounced(start_debounced), .pb(start), .clk(myclk16));
wire direction_debounced;
debounce db2 (.pb_debounced(direction_debounced), .pb(direction), .clk(myclk16));
wire increase_debounced;
debounce db3 (.pb_debounced(increase_debounced), .pb(increase), .clk(myclk16));
wire decrease_debounced;
debounce db4 (.pb_debounced(decrease_debounced), .pb(decrease), .clk(myclk16));
wire select_debounced;
debounce db5 (.pb_debounced(select_debounced), .pb(select), .clk(myclk16));

wire start_1pulse;
one_pulse op1 (.pb_in(start_debounced), .clk(myclk16), .pb_out(start_1pulse));
wire direction_1pulse;
one_pulse op2 (.pb_in(direction_debounced), .clk(myclk16), .pb_out(direction_1pulse));
wire increase_1pulse;
one_pulse op3 (.pb_in(increase_debounced), .clk(myclk16), .pb_out(increase_1pulse));
wire decrease_1pulse;
one_pulse op4 (.pb_in(decrease_debounced), .clk(myclk16), .pb_out(decrease_1pulse));
wire select_1pulse;
one_pulse op5 (.pb_in(select_debounced), .clk(myclk16), .pb_out(select_1pulse));

reg dir = 0; // 0 for UP, 1 for DOWN
reg next_dir;

reg [2:0] next_dlight;

bin2bcd convert1 (counter, led);

wire myclk10hz, myclk16, clkmux;
my_clock_divider #(28'd10000000) clk1 (clk, myclk10hz);
my_clock_divider #(28'd65536) clk2 (clk, myclk16);
assign clkmux = state == STOP ? myclk16 : myclk10hz;

parameter START = 50;
parameter MAX = 999;
parameter MIN = 0;

parameter INIT = 2'd0;
parameter CNT = 2'd1;
parameter STOP = 2'd2;
reg [1:0] state = INIT;
reg [1:0] next_state;

reg [9:0] counter; // up to 1023, down to 0
reg [9:0] next_counter;

reg [3:0] value;

wire [3:0] BCD0 = led[3:0];
wire [3:0] BCD1 = led[7:4];
wire [3:0] BCD2 = led[11:8];
wire [3:0] BCD3 = state == CNT ? dir == 0 ? 4'd10 : 4'd11 :
                                direction_debounced == 1'b1 ? dir == 0 ? 4'd10 : 4'd11 : 4'd12;

// state
always @(posedge myclk16 or posedge rst) begin
    if(rst) begin
        state <= INIT;
    end
    else begin
        state <= next_state;
    end
end
// state
always @* begin
    case(state)
        INIT : begin
            if(start_1pulse) begin
                next_state = STOP;
            end
            else begin
                next_state = INIT;
            end
        end
        STOP : begin
            if(start_1pulse) begin
                next_state = CNT;
            end
            else begin
                next_state = STOP;
            end
        end
        CNT : begin
            if(start_1pulse) begin
                next_state = STOP;
            end
            else begin
                next_state = CNT;
            end
        end
    endcase
end
// binary counter
always @(posedge clkmux or posedge rst) begin
    if(rst) begin
        counter <= START;
    end
    else begin
        counter <= next_counter;
    end
end
// binary counter
always @* begin
    case(state)
        INIT : begin
            next_counter = START;
        end
        CNT : begin
            if(dir == 1'b0) begin
                if(counter == MAX) begin
                    next_counter = counter;
                end
                else begin
                    next_counter = counter + 1;
                end
            end
            else begin
                if(counter == MIN) begin
                    next_counter = counter;
                end
                else begin
                    next_counter = counter - 1;
                end
            end
        end
        STOP : begin
            next_counter = counter;
            if(increase_1pulse == 1'b1) begin
                case({d2, d1, d0})
                    3'b001 : begin
                        if(counter % 10 != 9) begin
                            next_counter = counter + 1;
                        end
                        else begin
                            next_counter = counter - 9;
                        end
                    end
                    3'b010 : begin
                        if((counter / 10) % 10 != 9) begin
                            next_counter = counter + 10;
                        end
                        else begin
                            next_counter = counter - 90;
                        end
                    end
                    3'b100 : begin
                        if((counter / 100) % 10 != 9) begin
                            next_counter = counter + 100;
                        end
                        else begin
                            next_counter = counter - 900;
                        end
                    end
                    default : begin
                        next_counter = counter;
                    end
                endcase
            end
            if(decrease_1pulse == 1'b1) begin
                case({d2, d1, d0})
                    3'b001 : begin
                        if(counter % 10 != 0) begin
                            next_counter = counter - 1;
                        end
                        else begin
                            next_counter = counter + 9;
                        end
                    end
                    3'b010 : begin
                        if((counter / 10) % 10 != 0) begin
                            next_counter = counter - 10;
                        end
                        else begin
                            next_counter = counter + 90;
                        end
                    end
                    3'b100 : begin
                        if((counter / 100) % 10 != 0) begin
                            next_counter = counter - 100;
                        end
                        else begin
                            next_counter = counter + 900;
                        end
                    end
                    default : begin
                        next_counter = counter;
                    end
                endcase
            end
        end
    endcase
end

// 7 segment display
always @(posedge myclk16) begin
    case (DIGIT)
        4'b1110 : begin
            value = BCD1;
            DIGIT = 4'b1101;
        end
        4'b1101 : begin
            value = BCD2;
            DIGIT = 4'b1011;
        end
        4'b1011 : begin
            value = BCD3;
            DIGIT = 4'b0111;
        end
        4'b0111 : begin
            value = BCD0;
            DIGIT = 4'b1110;
        end
        default : begin
            value = BCD0;
            DIGIT = 4'b1110;
        end
    endcase
end
// 7 segment display
always @* begin
    if(state == INIT) begin
        DISPLAY = 7'b011_1111;
    end
    else if(state == CNT || state == STOP) begin
        case(value)
            4'd0 : DISPLAY = 7'b100_0000;
            4'd1 : DISPLAY = 7'b111_1001;
            4'd2 : DISPLAY = 7'b010_0100;
            4'd3 : DISPLAY = 7'b011_0000;
            4'd4 : DISPLAY = 7'b001_1001;
            4'd5 : DISPLAY = 7'b001_0010;
            4'd6 : DISPLAY = 7'b000_0010;
            4'd7 : DISPLAY = 7'b111_1000;
            4'd8 : DISPLAY = 7'b000_0000;
            4'd9 : DISPLAY = 7'b001_0000;
            
            4'd10 : DISPLAY = 7'b101_1100; // UP
            4'd11 : DISPLAY = 7'b110_0011; // DOWN
            4'd12 : DISPLAY = 7'b011_1111; // PAUSE
            
            default : DISPLAY = 7'b111_1111;
        endcase
    end
end
//  dir
always @(posedge myclk16 or posedge rst) begin
    if(rst) begin
        dir <= 1'b0;
    end
    else begin
        dir <= next_dir;
    end
end
// dir
always @* begin
    case(state)
        INIT : begin
            next_dir = 1'b0;
        end
        CNT : begin
            next_dir = dir;
            if(direction_1pulse == 1'b1) begin
                next_dir = !dir;
            end
        end
        STOP : begin
            next_dir = dir;
        end
    endcase
end
//  d light
always @(posedge myclk16 or posedge rst) begin
    if(rst) begin
        {d2, d1, d0} <= 3'b000;
    end
    else begin
        {d2, d1, d0} <= next_dlight;
    end
end
// d light
always @* begin
    case(state)
        INIT : begin
            next_dlight = 3'b000;
        end
        CNT : begin
            next_dlight = 3'b000;
        end
        STOP : begin
            next_dlight = {d2, d1, d0};
            if({d2, d1, d0} == 3'b000) begin
                next_dlight = 3'b001;
            end
            if(select_1pulse == 1'b1) begin
                if({d2, d1, d0} == 3'b000) begin
                    next_dlight = 3'b001;
                end
                else if({d2, d1, d0} == 3'b001) begin
                    next_dlight = 3'b010;
                end
                else if({d2, d1, d0} == 3'b010) begin
                    next_dlight = 3'b100;
                end
                else if({d2, d1, d0} == 3'b100) begin
                    next_dlight = 3'b001;
                end
            end
        end
    endcase
end

endmodule 

module bin2bcd (
    input [9:0] bin,
    output reg [15:0] bcd
);
   
integer i;
	
always @(bin) begin
    bcd = 0;		 	
    for(i=0; i<10; i=i+1) begin
        if(bcd[3:0] >= 5) begin
            bcd[3:0] = bcd[3:0] + 3;
        end
        if(bcd[7:4] >= 5) begin
            bcd[7:4] = bcd[7:4] + 3;
        end
        if(bcd[11:8] >= 5) begin
            bcd[11:8] = bcd[11:8] + 3;
        end
        if(bcd[15:12] >= 5) begin
            bcd[15:12] = bcd[15:12] + 3;
        end
        bcd = {bcd[14:0], bin[9-i]};
    end
end

endmodule

module my_clock_divider #(
    parameter DIVISOR = 28'd2
)(
    input clock_in,
    output reg clock_out
);

reg [27:0] counter = 28'd0;

always @(posedge clock_in) begin
    counter <= counter + 28'd1;
    if(counter >= (DIVISOR-1)) begin
        counter <= 28'd0;
    end
    clock_out <= (counter < DIVISOR/2) ? 1'b1 : 1'b0;
end

endmodule
