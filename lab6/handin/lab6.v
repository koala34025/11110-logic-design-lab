module lab6 (
    input wire clk,
	input wire rst,
	input wire start,
	inout wire PS2_DATA,
	inout wire PS2_CLK,
	output reg [15:0] LED,
	output wire [3:0] DIGIT,
	output wire [6:0] DISPLAY
);

integer i;

parameter [8:0] KEY_CODES [0:9] = {
    9'b0_0100_0101,	// 0 => 45
    9'b0_0001_0110,	// 1 => 16
    9'b0_0001_1110,	// 2 => 1E
    9'b0_0010_0110,	// 3 => 26
    9'b0_0010_0101,	// 4 => 25
    9'b0_0010_1110,	// 5 => 2E
    9'b0_0011_0110,	// 6 => 36
    9'b0_0011_1101,	// 7 => 3D
    9'b0_0011_1110,	// 8 => 3E
    9'b0_0100_0110	// 9 => 46
};

reg [31:0] counter;
reg [31:0] next_counter;
reg [31:0] counter2;
reg [31:0] next_counter2;

parameter INIT = 2'd0;
parameter GAME = 2'd1;
parameter FINAL = 2'd2;
reg [1:0] state;
reg [1:0] next_state;

wire rst_debounced;
wire rst_1pulse;
wire start_debounced;
wire start_1pulse;

reg [15:0] nums;
reg [15:0] next_nums;

reg [15:0] next_LED;

reg [15:0] random;
reg [15:0] next_random;

reg [3:0] score;
reg [3:0] next_score;

reg [15:0] mask;
reg [15:0] next_mask;

reg valid;
reg next_valid;

reg [3:0] key_num;
reg [8:0] last_key;

wire [70:0] key_down;
wire [8:0] last_change;
wire been_ready;

my_debounce db1 (.pb_debounced(rst_debounced), .pb(rst), .clk(clk));
my_debounce db2 (.pb_debounced(start_debounced), .pb(start), .clk(clk));

OnePulse op1 (.signal_single_pulse(rst_1pulse), .signal(rst_debounced), .clock(clk));
OnePulse op2 (.signal_single_pulse(start_1pulse), .signal(start_debounced), .clock(clk));

my_SevenSegment seven_seg (
    .display(DISPLAY),
    .digit(DIGIT),
    .nums(nums),
    .rst(rst_1pulse),
    .clk(clk)
);
    
KeyboardDecoder key_de (
    .key_down({441'd0, key_down}),
    .last_change(last_change),
    .key_valid(been_ready),
    .PS2_DATA(PS2_DATA),
    .PS2_CLK(PS2_CLK),
    .rst(rst_1pulse),
    .clk(clk)
);
// COUNTER
always @(posedge clk or posedge rst_1pulse) begin
    if(rst_1pulse) begin
        counter <= 32'd0;
        counter2 <= 32'd0;
    end
    else begin
        counter <= next_counter;
        counter2 <= next_counter2;
    end
end
// COUNTER
always @* begin
    next_counter = counter;
    next_counter2 = counter2;
    case(state)
        INIT : begin
            next_counter = 32'd0;
            next_counter2 = 32'd0;
        end
        GAME : begin
            next_counter = counter + 32'd1;
            next_counter2 = counter2 + 32'd1;
            if(counter >= (100000000-1)) begin
                next_counter = 32'd0;
            end
            if(counter2 >= (32'd3000000000-1)) begin
                next_counter2 = 32'd0;
            end
        end
        FINAL : begin
            next_counter = 32'd0;
            next_counter2 = 32'd0;
        end
    endcase
end
// RANDOM
always @(posedge clk or posedge rst_1pulse) begin
    if(rst_1pulse) begin
        random <= 16'b1110_1100_1110_0001;
    end
    else begin
        random <= next_random;
    end
end
// RANDOM
always @* begin
    next_random = random;
    case(state)
        INIT : begin
            next_random = 16'b1110_1100_1110_0001;
        end
        GAME : begin
            if(counter >= (100000000-1)) begin
                next_random[12:0] = random[13:1];
                next_random[13] = random[5] ^ random[3] ^ random[2] ^ random[0];
                next_random[15] = 1'b1;
                next_random[14] = 1'b1;
            end
        end
        FINAL : begin
            next_random = 16'b1110_1100_1110_0001;
        end
    endcase
end
// STATE
always @(posedge clk or posedge rst_1pulse) begin
    if(rst_1pulse) begin
        state <= INIT;
    end
    else begin
        state <= next_state;
    end
end
// STATE
always @* begin
    next_state = state;
    case(state)
        INIT : begin
            if(start_1pulse) begin
                next_state = GAME;
            end
        end
        GAME : begin
            if(counter2 >= (32'd3000000000-1)) begin
                next_state = FINAL;
            end
            if(score == 4'd10) begin
                next_state = FINAL;
            end
        end
        FINAL : begin
            if(start_1pulse) begin
                next_state = INIT;
            end
        end
    endcase
end
// LED
always @ (posedge clk, posedge rst_1pulse) begin
    if (rst_1pulse) begin
        LED <= 16'b0000_0000_0000_0000;
    end else begin
        LED <= next_LED;
    end
end
// LED
always @* begin
    next_LED = LED;
    case(state)
        INIT : begin
            next_LED = 16'b0000_0000_0000_0000;
        end
        GAME : begin
            next_LED = random & mask;
        end
        FINAL : begin
            next_LED = 16'b1111_1111_1111_1111;
        end
    endcase
end
// MASK
always @(posedge clk or posedge rst_1pulse) begin
    if(rst_1pulse) begin
        mask <= 16'b1111_1111_1000_0000;
    end
    else begin
        mask <= next_mask;
    end
end
// MASK
always @* begin
    next_mask = mask;
    case(state)
        INIT : begin
            next_mask = 16'b1111_1111_1000_0000;
        end
        GAME : begin
            if (been_ready && key_down[last_change] == 1'b1) begin
                if(key_num <= 9 && key_num >= 1) begin
                    if (random[16 - key_num] && mask[16 - key_num])begin
                        if(valid) begin
                            next_mask[16 - key_num] = 1'b0;
                        end
                    end
                end
            end
            if(counter >= (100000000)-1) begin
                next_mask = 16'b1111_1111_1000_0000;
            end
        end
        FINAL : begin
            next_mask = 16'b1111_1111_1000_0000;
        end
    endcase
end
// SCORE
always @(posedge clk or posedge rst_1pulse) begin
    if(rst_1pulse) begin
        score <= 4'd0;
    end
    else begin
        score <= next_score;
    end
end
// SCORE
always @* begin
    next_score = score;
    case(state)
        INIT : begin
            next_score = 4'd0;
        end
        GAME : begin
            if (been_ready && key_down[last_change] == 1'b1) begin
                if(key_num <= 9 && key_num >= 1) begin
                    if (random[16 - key_num] && mask[16 - key_num])begin
                        if(valid) begin
                            next_score = score + 1;
                        end
                    end
                end
            end
        end
    endcase
end
// VALID
always @(posedge clk or posedge rst_1pulse) begin
    if(rst_1pulse) begin
        valid <= 1'b1;
    end
    else begin
        valid <= next_valid;
    end
end
// VALID
always @* begin
    next_valid = valid;
    case(state)
        INIT : begin
            next_valid = 1'b1;
        end
        GAME : begin
            next_valid = 1'b1;
            for(i=0; i<10; i=i+1) begin
                if(key_down[KEY_CODES[i]] == 1'b1) begin
                    next_valid = 1'b0;
                end
            end
        end
        FINAL : begin
            next_valid = 1'b1;
        end
    endcase
end
// NUMS
always @ (posedge clk, posedge rst_1pulse) begin
    if (rst_1pulse) begin
        nums <= {4'd10, 4'd10, 4'd10, 4'd10};
    end else begin
        nums <= next_nums;
    end
end
// NUMS
always @* begin
    next_nums = nums;
    case(state)
        INIT : begin
            next_nums = {4'd10, 4'd10, 4'd10, 4'd10};
        end
        GAME : begin
            next_nums[15:12] = (((32'd3000000000 - counter2) / 32'd100000000 + 4'd1) / 4'd10) % 4'd10;
            next_nums[11:8] = ((32'd3000000000 - counter2) / 32'd100000000 + 4'd1) % 4'd10;
            next_nums[7:4] = score / 10;
            next_nums[3:0] = score % 10;
        end
        FINAL : begin
            if(score == 4'd10) begin
                next_nums = {4'd10, 4'd11, 4'd12, 4'd13};
            end
            else begin
                next_nums = {4'd0, 4'd0, score / 4'd10, score % 4'd10};
            end
        end
    endcase
end
    
always @ (*) begin
    case (last_change)
        KEY_CODES[0] : key_num = 4'b0000;
        KEY_CODES[1] : key_num = 4'b0001;
        KEY_CODES[2] : key_num = 4'b0010;
        KEY_CODES[3] : key_num = 4'b0011;
        KEY_CODES[4] : key_num = 4'b0100;
        KEY_CODES[5] : key_num = 4'b0101;
        KEY_CODES[6] : key_num = 4'b0110;
        KEY_CODES[7] : key_num = 4'b0111;
        KEY_CODES[8] : key_num = 4'b1000;
        KEY_CODES[9] : key_num = 4'b1001;
        default		  : key_num = 4'b1111;
    endcase
end
	
endmodule

module my_SevenSegment(
	output reg [6:0] display,
	output reg [3:0] digit,
	input wire [15:0] nums,
	input wire rst,
	input wire clk
    );
    
    reg [15:0] clk_divider;
    reg [3:0] display_num;
    
    always @ (posedge clk, posedge rst) begin
    	if (rst) begin
    		clk_divider <= 15'b0;
    	end else begin
    		clk_divider <= clk_divider + 15'b1;
    	end
    end
    
    always @ (posedge clk_divider[15], posedge rst) begin
    	if (rst) begin
    		display_num <= 4'b0000;
    		digit <= 4'b1111;
    	end else begin
    		case (digit)
    			4'b1110 : begin
    					display_num <= nums[7:4];
    					digit <= 4'b1101;
    				end
    			4'b1101 : begin
						display_num <= nums[11:8];
						digit <= 4'b1011;
					end
    			4'b1011 : begin
						display_num <= nums[15:12];
						digit <= 4'b0111;
					end
    			4'b0111 : begin
						display_num <= nums[3:0];
						digit <= 4'b1110;
					end
    			default : begin
						display_num <= nums[3:0];
						digit <= 4'b1110;
					end				
    		endcase
    	end
    end
    
    always @ (*) begin
    	case (display_num)
    		0 : display = 7'b1000000;	//0000
			1 : display = 7'b1111001;   //0001                                                
			2 : display = 7'b0100100;   //0010                                                
			3 : display = 7'b0110000;   //0011                                             
			4 : display = 7'b0011001;   //0100                                               
			5 : display = 7'b0010010;   //0101                                               
			6 : display = 7'b0000010;   //0110
			7 : display = 7'b1111000;   //0111
			8 : display = 7'b0000000;   //1000
			9 : display = 7'b0010000;	//1001
			10 : display = 7'b0111111; // -
			11 : display = 7'b1100010; // W
			12 : display = 7'b1001111; // I
			13 : display = 7'b1001000; // N
			default : display = 7'b1111111;
    	endcase
    end
    
endmodule

module my_debounce (
	input wire clk,
	input wire pb, 
	output wire pb_debounced 
);
	reg [3:0] shift_reg; 

	always @(posedge clk) begin
		shift_reg[3:1] <= shift_reg[2:0];
		shift_reg[0] <= pb;
	end

	assign pb_debounced = ((shift_reg == 4'b1111) ? 1'b1 : 1'b0);

endmodule
