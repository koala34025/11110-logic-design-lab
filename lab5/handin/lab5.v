module lab5 ( 
    input wire clk,
    input wire rst, 
    input wire BTNR,
    input wire BTNU,
    input wire BTND,
    input wire BTNL,
    output reg [15:0] LED,
    output reg [3:0] DIGIT,
    output reg [6:0] DISPLAY
 ); 

wire myclk1000hz;
my_clock_divider #(28'd100000) clk1 (clk, myclk1000hz);

wire rst_debounced;
debounce db1 (.pb_debounced(rst_debounced), .pb(rst), .clk(myclk1000hz));
wire BTNR_debounced;
debounce db2 (.pb_debounced(BTNR_debounced), .pb(BTNR), .clk(myclk1000hz));
wire BTNU_debounced;
debounce db3 (.pb_debounced(BTNU_debounced), .pb(BTNU), .clk(myclk1000hz));
wire BTND_debounced;
debounce db4 (.pb_debounced(BTND_debounced), .pb(BTND), .clk(myclk1000hz));
wire BTNL_debounced;
debounce db5 (.pb_debounced(BTNL_debounced), .pb(BTNL), .clk(myclk1000hz));

wire rst_1pulse;
one_pulse op1 (.pb_in(rst_debounced), .clk(myclk1000hz), .pb_out(rst_1pulse));
wire BTNR_1pulse;
one_pulse op2 (.pb_in(BTNR_debounced), .clk(myclk1000hz), .pb_out(BTNR_1pulse));
wire BTNU_1pulse;
one_pulse op3 (.pb_in(BTNU_debounced), .clk(myclk1000hz), .pb_out(BTNU_1pulse));
wire BTND_1pulse;
one_pulse op4 (.pb_in(BTND_debounced), .clk(myclk1000hz), .pb_out(BTND_1pulse));
wire BTNL_1pulse;
one_pulse op5 (.pb_in(BTNL_debounced), .clk(myclk1000hz), .pb_out(BTNL_1pulse));

parameter IDLE = 4'd0;
parameter SET_ANSWER_3 = 4'd1;
parameter SET_ANSWER_2 = 4'd2;
parameter SET_ANSWER_1 = 4'd3;
parameter SET_ANSWER_0 = 4'd4;
parameter GUESS_3 = 4'd5;
parameter GUESS_2 = 4'd6;
parameter GUESS_1 = 4'd7;
parameter GUESS_0 = 4'd8;
parameter WRONG = 4'd9;
parameter CORRECT = 4'd10;
reg [3:0] state;
reg [3:0] next_state;

reg [3:0] value;

reg [15:0] counter; // count for 5 sec
reg [15:0] next_counter;

reg [15:0] BCD;
reg [15:0] next_BCD;

reg [15:0] answer;
reg [15:0] next_answer;
reg [15:0] guess;
reg [15:0] next_guess;

reg [15:0] next_LED;

wire [3:0] A = {3'b000, answer[15:12] == guess[15:12]} 
             + {3'b000, answer[11:8] == guess[11:8]}
             + {3'b000, answer[7:4] == guess[7:4]}
             + {3'b000, answer[3:0] == guess[3:0]};
wire [3:0] B = {3'b000, answer[15:12] == guess[11:8]}
             + {3'b000, answer[15:12] == guess[7:4]}
             + {3'b000, answer[15:12] == guess[3:0]}
             + {3'b000, answer[11:8] == guess[15:12]}
             + {3'b000, answer[11:8] == guess[7:4]}
             + {3'b000, answer[11:8] == guess[3:0]}
             + {3'b000, answer[7:4] == guess[15:12]}
             + {3'b000, answer[7:4] == guess[11:8]}
             + {3'b000, answer[7:4] == guess[3:0]}
             + {3'b000, answer[3:0] == guess[15:12]}
             + {3'b000, answer[3:0] == guess[11:8]}
             + {3'b000, answer[3:0] == guess[7:4]};

reg guess_first_time = 1'b0;
reg next_guess_first_time;

// counter for 5 sec
always @(posedge myclk1000hz or posedge rst_1pulse) begin
    if(rst_1pulse) begin
        counter <= 3'b0;
    end
    else begin
        counter <= next_counter;
    end
end
// counter for 5 sec
always @* begin
    next_counter = counter;
    case(state)
        IDLE : begin
            next_counter = 3'b0;
        end
        CORRECT : begin
            next_counter = counter + 1; 
        end
    endcase
end

// state
always @(posedge myclk1000hz or posedge rst_1pulse) begin
    if(rst_1pulse) begin
        state <= IDLE;
    end
    else begin
        state <= next_state;
    end
end
// state
always @* begin
    next_state = state;
    case(state)
        IDLE : begin
            if(BTNR_1pulse) begin
                next_state = SET_ANSWER_3;
            end
        end
        SET_ANSWER_3 : begin
            if(BTNR_1pulse) begin 
                next_state = SET_ANSWER_2;
            end
            else if(BTNL_1pulse) begin
                next_state = IDLE;
            end
        end
        SET_ANSWER_2 : begin
            if(BTNR_1pulse) begin 
                next_state = SET_ANSWER_1;
            end
            else if(BTNL_1pulse) begin
                next_state = IDLE;
            end
        end
        SET_ANSWER_1 : begin
            if(BTNR_1pulse) begin 
                next_state = SET_ANSWER_0;
            end
            else if(BTNL_1pulse) begin
                next_state = IDLE;
            end
        end
        SET_ANSWER_0 : begin
            if(BTNR_1pulse) begin 
                next_state = GUESS_3;
            end
            else if(BTNL_1pulse) begin
                next_state = IDLE;
            end
        end
        GUESS_3 : begin
            if(BTNR_1pulse) begin
                next_state = GUESS_2;
            end
            else if(BTNL_1pulse) begin
                next_state = IDLE;
            end
        end
        GUESS_2 : begin
            if(BTNR_1pulse) begin
                next_state = GUESS_1;
            end
            else if(BTNL_1pulse) begin
                next_state = IDLE;
            end
        end
        GUESS_1 : begin
            if(BTNR_1pulse) begin
                next_state = GUESS_0;
            end
            else if(BTNL_1pulse) begin
                next_state = IDLE;
            end
        end
        GUESS_0 : begin
            if(BTNR_1pulse) begin
                if(A == 3'd4) begin // check correctness
                    next_state = CORRECT;
                end
                else begin
                    next_state = WRONG;
                end
            end
            else if(BTNL_1pulse) begin
                next_state = IDLE;
            end
        end
        WRONG : begin
            if(BTNR_1pulse) begin
                next_state = GUESS_3;
            end
            else if(BTNL_1pulse) begin
                next_state = IDLE;
            end
        end
        CORRECT : begin
            if(counter == 16'd5000) begin // after 5 sec
                next_state = IDLE;
            end
        end
    endcase
end

// 7 segment display
always @(posedge myclk1000hz) begin
    case (DIGIT)
        4'b1110 : begin
            value = BCD[7:4];
            DIGIT = 4'b1101;
        end
        4'b1101 : begin
            value = BCD[11:8];
            DIGIT = 4'b1011;
        end
        4'b1011 : begin
            value = BCD[15:12];
            DIGIT = 4'b0111;
        end
        4'b0111 : begin
            value = BCD[3:0];
            DIGIT = 4'b1110;
        end
        default : begin
            value = BCD[3:0];
            DIGIT = 4'b1110;
        end
    endcase
end
// 7 segment display
always @* begin
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
            
            4'd10 : DISPLAY = 7'b000_1000; // A
            4'd11 : DISPLAY = 7'b000_0011; // B
            4'd12 : DISPLAY = 7'b011_1111; // -
            
            default : DISPLAY = 7'b111_1111;
        endcase
end

always @(posedge myclk1000hz or posedge rst_1pulse) begin
    if(rst_1pulse) begin
        BCD <= {4'd12, 4'd12, 4'd12, 4'd12};
    end
    else begin
        BCD <= next_BCD;
    end
end

always @* begin
    next_BCD = BCD;
    case(state)
        IDLE : begin
            next_BCD = {4'd12, 4'd12, 4'd12, 4'd12};
        end
        SET_ANSWER_3, SET_ANSWER_2, SET_ANSWER_1, SET_ANSWER_0 : begin
            next_BCD = answer;
        end
        GUESS_3, GUESS_2, GUESS_1, GUESS_0 : begin
            next_BCD = guess;
        end
        WRONG, CORRECT : begin // ?A?B
            next_BCD = {A, 4'd10, B, 4'd11};
        end
    endcase
end

// answer
always @(posedge myclk1000hz or posedge rst_1pulse) begin
    if(rst_1pulse) begin
        answer <= 16'd0;
    end
    else begin
        answer <= next_answer;
    end
end

always @* begin
    next_answer = answer;
    case(state)
        IDLE : begin
            next_answer = 16'd0;
        end
        SET_ANSWER_3 : begin
            if(BTND_1pulse) begin // -
                if(answer[15:12] != 4'd0) begin
                    next_answer[15:12] = answer[15:12] - 1;
                end
            end
            else if(BTNU_1pulse) begin // +
                if(answer[15:12] != 4'd9) begin
                    next_answer[15:12] = answer[15:12] + 1;
                end
            end
        end
        SET_ANSWER_2 : begin
            if(BTND_1pulse) begin // -
                if(answer[11:8] != 4'd0) begin
                    next_answer[11:8] = answer[11:8] - 1;
                end
            end
            else if(BTNU_1pulse) begin // +
                if(answer[11:8] != 4'd9) begin
                    next_answer[11:8] = answer[11:8] + 1;
                end
            end
        end
        SET_ANSWER_1 : begin
            if(BTND_1pulse) begin // -
                if(answer[7:4] != 4'd0) begin
                    next_answer[7:4] = answer[7:4] - 1;
                end
            end
            else if(BTNU_1pulse) begin // +
                if(answer[7:4] != 4'd9) begin
                    next_answer[7:4] = answer[7:4] + 1;
                end
            end
        end
        SET_ANSWER_0 : begin
            if(BTND_1pulse) begin // -
                if(answer[3:0] != 4'd0) begin
                    next_answer[3:0] = answer[3:0] - 1;
                end
            end
            else if(BTNU_1pulse) begin // +
                if(answer[3:0] != 4'd9) begin
                    next_answer[3:0] = answer[3:0] + 1;
                end
            end
        end
    endcase
end

always @(posedge myclk1000hz or posedge rst_1pulse) begin
    if(rst_1pulse) begin
        guess_first_time <= 0;
    end
    else begin
        guess_first_time <= next_guess_first_time;
    end
end

always @* begin
    next_guess_first_time = guess_first_time;
    case(state)
        IDLE : begin
            next_guess_first_time = 1;
        end
        GUESS_3 : begin
            next_guess_first_time = 1;
        end
        WRONG : begin
            next_guess_first_time = 0;
        end
    endcase
end

always @(posedge myclk1000hz or posedge rst_1pulse) begin
    if(rst_1pulse) begin
        guess <= 16'd0;
    end
    else begin
        guess <= next_guess;
    end
end

always @* begin
    next_guess = guess;
    case(state)
        IDLE : begin
            next_guess = 16'd0;
        end
        GUESS_3 : begin
            if(guess_first_time == 0) begin
                next_guess = 16'd0;
            end
            if(BTND_1pulse) begin // -
                if(guess[15:12] != 4'd0) begin
                    next_guess[15:12] = guess[15:12] - 1;
                end
            end
            else if(BTNU_1pulse) begin // +
                if(guess[15:12] != 4'd9) begin
                    next_guess[15:12] = guess[15:12] + 1;
                end
            end
        end
        GUESS_2 : begin
            if(BTND_1pulse) begin // -
                if(guess[11:8] != 4'd0) begin
                    next_guess[11:8] = guess[11:8] - 1;
                end
            end
            else if(BTNU_1pulse) begin // +
                if(guess[11:8] != 4'd9) begin
                    next_guess[11:8] = guess[11:8] + 1;
                end
            end
        end
        GUESS_1 : begin
            if(BTND_1pulse) begin // -
                if(guess[7:4] != 4'd0) begin
                    next_guess[7:4] = guess[7:4] - 1;
                end
            end
            else if(BTNU_1pulse) begin // +
                if(guess[7:4] != 4'd9) begin
                    next_guess[7:4] = guess[7:4] + 1;
                end
            end
        end
        GUESS_0 : begin
            if(BTND_1pulse) begin // -
                if(guess[3:0] != 4'd0) begin
                    next_guess[3:0] = guess[3:0] - 1;
                end
            end
            else if(BTNU_1pulse) begin // +
                if(guess[3:0] != 4'd9) begin
                    next_guess[3:0] = guess[3:0] + 1;
                end
            end
        end
    endcase
end

always @(posedge myclk1000hz or posedge rst_1pulse) begin
    if(rst_1pulse) begin
        LED <= 16'b1111_0000_0000_0000;
    end
    else begin
        LED <= next_LED;
    end
end

always @* begin
    next_LED = LED;
    case(state)
        IDLE : next_LED = 16'b1111_0000_0000_0000;
        SET_ANSWER_3 : next_LED = 16'b0000_1000_0000_0000;
        SET_ANSWER_2 : next_LED = 16'b0000_0100_0000_0000;
        SET_ANSWER_1 : next_LED = 16'b0000_0010_0000_0000;
        SET_ANSWER_0 : next_LED = 16'b0000_0001_0000_0000;
        GUESS_3 : next_LED = 16'b0000_0000_1000_0000;
        GUESS_2 : next_LED = 16'b0000_0000_0100_0000;
        GUESS_1 : next_LED = 16'b0000_0000_0010_0000;
        GUESS_0 : next_LED = 16'b0000_0000_0001_0000;
        WRONG : next_LED = 16'b0000_0000_0000_1111;
        CORRECT : begin
            if((counter / 1000) % 2 == 0) begin
                next_LED = 16'b1111_1111_1111_1111;
            end
            else begin
                next_LED = 16'b0000_0000_0000_0000;
            end
        end
    endcase
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
