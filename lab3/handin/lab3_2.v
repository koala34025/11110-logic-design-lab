module lab3_2
(
    input clk,
    input rst,
    input en,
    input speed,
    input freeze,
    output [15:0] led
);

wire myclk24, myclk27;

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

parameter INIT = 3'd0;
parameter RACING = 3'd1;
parameter M_F = 3'd2;
parameter M_W = 3'd3;
parameter C_F = 3'd4;
parameter C_W = 3'd5;
parameter INIT_WAIT = 3'd6;
reg [2:0] state = 3'd0, next_state;

reg [1:0] m_score;
reg [1:0] m_next_score;

reg [1:0] c_score;
reg [1:0] c_next_score;

reg [15:0] m_pos;
reg [15:0] m_next_pos;

reg [15:0] c_pos;
reg [15:0] c_next_pos;

reg [2:0] speed_left = 3'd6;
reg speeded = 1'd0;

assign led = {c_score, c_pos[13:2] | m_pos[13:2], m_score};

// state
always @(posedge myclk27 or posedge rst) begin
    if(rst) begin
        state <= INIT;
    end
    else begin
        state <= next_state;
    end
end

always @* begin
    if(en == 0) begin
        next_state = state;
    end
    else begin
        case(state)
            INIT : begin
                next_state = RACING;
            end
            RACING : begin
                next_state = RACING;
                if(m_pos[2] == 1'b1) begin
                    if(m_score == 2'd3) begin
                        next_state = M_W;
                    end
                    else begin
                        next_state = M_F;
                    end
                end
                else if(c_pos[2] == 1'b1) begin
                    if(c_score == 2'd3) begin
                        next_state = C_W;
                    end
                    else begin
                        next_state = C_F;
                    end
                end
            end
            M_F, C_F : begin
                next_state = RACING;
            end
            M_W, C_W : begin
                //next_state = INIT;
                next_state = INIT_WAIT;
            end
            INIT_WAIT : begin
                next_state = INIT;
            end
        endcase
    end
end

// motor pos
always @(posedge myclk27 or posedge rst) begin
    if(rst) begin
        m_pos <= 16'b0000010000000000;
    end
    else begin
        m_pos <= m_next_pos;
    end
end

always @* begin
    if(en == 0) begin
        m_next_pos = m_pos;
    end
    else begin 
        case(state)
            INIT, INIT_WAIT : begin
                m_next_pos = 16'b0000010000000000;
            end
            RACING : begin
                if(freeze == 1) begin
                    m_next_pos = m_pos;
                end
                else if(m_pos[2] != 1'b1 && c_pos[2] != 1'b1) begin
                    m_next_pos = m_pos >> 1;
                end
                else begin
                    m_next_pos = m_pos;
                end
            end
            M_F, C_F : begin
                m_next_pos = 16'b0000010000000000;
            end
            M_W, C_W : begin
                m_next_pos = 16'b0011111111111111;
            end
        endcase
    end
end

// motor score
always @(posedge myclk27 or posedge rst) begin
    if(rst) begin
        m_score <= 2'b00;
    end
    else begin
        m_score <= m_next_score;
    end
end

always @* begin
    if(en == 0) begin
        m_next_score = m_score;
    end
    else begin 
        case(state)
            INIT, INIT_WAIT : begin
                m_next_score = 2'b00;
            end
            RACING : begin
                m_next_score = m_score;
            end
            M_F : begin
                m_next_score = m_score + 1;
            end
            C_F : begin
                m_next_score = m_score;
            end
            M_W : begin
                m_next_score = 2'b11;
            end
            C_W : begin
            
                m_next_score = 2'b00;
            end
        endcase
    end
end

assign myclk = ((speed_left < 6)  && (state == RACING) && (speed_left > 0)) ? myclk24 : myclk27;

// speeded
//always @(posedge myclk24 or posedge rst) begin
//    if(rst) begin
//        speeded <= 1'd0;
//    end
//    else if(speed == 1) begin
//        speeded <= 1'd1;
//    end
//end

// speed left
always @(posedge myclk24 or posedge rst) begin
    if(rst) begin
        speed_left <= 3'd6;
    end
    else begin
        case(state)
            INIT, INIT_WAIT : begin
                speed_left <= 3'd6;
            end
            RACING : begin
                if(en == 0) begin
                    speed_left <= speed_left;
                end
                else if(speed == 1 && speed_left > 0) begin
                    speed_left <= speed_left - 1;
                end
                else if(speed_left != 3'd6 && speed_left > 0) begin
                    speed_left <= speed_left - 1;
                end
            end
            M_F, C_F : begin
                speed_left <= 3'd6;
            end
            M_W, C_W : begin
                speed_left <= 3'd6;
            end
        endcase
    end
end

// car pos
always @(posedge myclk or posedge rst) begin
    if(rst) begin
        c_pos <= 16'b0011000000000000;
    end
    else begin
        c_pos <= c_next_pos;
    end
end

always @* begin
    if(en == 0) begin
        c_next_pos = c_pos;
    end
    else begin 
        case(state)
            INIT, INIT_WAIT : begin
                c_next_pos = 16'b0011000000000000;
            end
            RACING : begin
                if(m_pos[2] != 1'b1 && c_pos[2] != 1'b1) begin
                    c_next_pos = c_pos >> 1;
                end
                else begin
                    c_next_pos = c_pos;
                end
            end
            M_F, C_F : begin
                c_next_pos = 16'b0011000000000000;
            end
            M_W, C_W : begin
                c_next_pos = 16'b1111111111111100;
            end
        endcase
    end
end

// car score
always @(posedge myclk27 or posedge rst) begin
    if(rst) begin
        c_score <= 2'b00;
    end
    else begin
        c_score <= c_next_score;
    end
end

always @* begin
    if(en == 0) begin
        c_next_score = c_score;
    end
    else begin 
        case(state)
            INIT, INIT_WAIT : begin
                c_next_score = 2'b00;
            end
            RACING : begin
                c_next_score = c_score;
            end
            M_F : begin
                c_next_score = c_score;
            end
            C_F : begin
                c_next_score = c_score + 1;
            end
            M_W : begin
                c_next_score = 2'b00;
            end
            C_W : begin
                c_next_score = 2'b11;
            end
        endcase
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
