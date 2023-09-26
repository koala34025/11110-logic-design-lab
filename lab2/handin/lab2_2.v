module Decoder (
    input clk,
    input rst,
    input [11:0] one_bit_err_in_data,
    input one_bit_err_in_valid,
    output reg [7:0] out_plaintext,
    output reg out_plaintext_valid
);

// 0-255 counter
reg [7:0] offset_counter, next_offset_counter;

// in_data_len
reg [7:0] in_data_len, next_in_data_len;
parameter MAX_INPUT_LEN = 8'd255;

// state
parameter INIT = 3'd0;
parameter GET_DATA = 3'd1;
parameter FIX = 3'd2;
parameter DECRYPT = 3'd3; // CALC
parameter OUTPUT_DATA = 3'd4;
reg [3:0] state, next_state;

// output_data_save
reg [11:0] output_data_save[255:0], next_output_data_save[255:0];

integer i;

// output
reg [7:0] next_out_data;
reg next_out_valid;

// state change engine
always @(posedge clk) begin
    if (rst) begin
        state <= INIT;
    end
    else begin
        state <= next_state;
    end
end

// state change if-else determine
always @(*) begin
    case(state)
        INIT : begin
            if (one_bit_err_in_valid) begin
                next_state = GET_DATA;
            end
            else begin
                next_state = INIT;
            end
        end
        GET_DATA : begin
            if (!one_bit_err_in_valid && in_data_len != 0) begin
                next_state = FIX;
            end
            else begin
                next_state = GET_DATA;
            end
        end
        FIX : begin
            if (offset_counter == in_data_len) begin
                next_state = DECRYPT;
            end
            else begin
                next_state = FIX;
            end
        end
        DECRYPT : begin
            if (offset_counter == in_data_len) begin
                next_state = OUTPUT_DATA;
            end
            else begin
                next_state = DECRYPT;
            end
        end
        OUTPUT_DATA : begin
            if (offset_counter == in_data_len) begin
                next_state = INIT;
            end
            else begin
                next_state = OUTPUT_DATA;
            end
        end
        default : begin
            next_state = INIT;
        end
    endcase
end

// offset_counter change engine
always @(posedge clk) begin
    if (rst) begin
        offset_counter <= 0;
    end
    else begin
        offset_counter <= next_offset_counter;
    end
end

// offset_counter increase if-else determine
always @(*) begin
    case(state)
        INIT : begin
            if (one_bit_err_in_valid) begin
                next_offset_counter = 1;
            end
            else begin
                next_offset_counter = 0;
            end
        end
        GET_DATA : begin
            if (!one_bit_err_in_valid && in_data_len != 0) begin
                next_offset_counter = 0;
            end
            else begin
                next_offset_counter = offset_counter + 1;
            end
        end
        FIX : begin
            if (offset_counter == in_data_len) begin
                next_offset_counter = 0;
            end
            else begin
                next_offset_counter = offset_counter + 1;
            end
        end
        DECRYPT : begin
            if (offset_counter == in_data_len) begin
                next_offset_counter = 0;
            end
            else begin
                next_offset_counter = offset_counter + 1;
            end
        end
        OUTPUT_DATA : begin
            if (offset_counter == in_data_len) begin
                next_offset_counter = 0;
            end
            else begin
                next_offset_counter = offset_counter + 1;
            end
        end
        default : begin
            next_offset_counter = 0;
        end
    endcase
end

// in_data_len change engine
always @(posedge clk) begin
    if (rst) begin
        in_data_len <= 0;
    end
    else begin
        in_data_len <= next_in_data_len;
    end
end

// in_data_len increase if-else determine
always @(*) begin
    case(state)
        INIT : begin
            if (one_bit_err_in_valid) begin
                next_in_data_len = 1;
            end
            else begin
                next_in_data_len = 0;
            end
        end
        GET_DATA : begin
            if (!one_bit_err_in_valid && in_data_len != 0) begin
                next_in_data_len = in_data_len;
            end
            else begin
                next_in_data_len = in_data_len + 1;
            end
        end
        default : begin
            next_in_data_len = in_data_len;
        end
    endcase
end

// output_data_save[] change engine
always @(posedge clk) begin
    if (rst) begin
        for (i=0; i<=MAX_INPUT_LEN; i=i+1) begin
            output_data_save[i] <= 0;
        end
    end
    else begin
        for (i=0; i<=MAX_INPUT_LEN; i=i+1) begin
            output_data_save[i] <= next_output_data_save[i];
        end
    end
end

// output_data_save[] change - ACCORDINGLY
always @(*) begin
    case(state)
        INIT : begin
            for (i=0; i<=MAX_INPUT_LEN; i=i+1) begin
                next_output_data_save[i] = output_data_save[i];
            end
            if (one_bit_err_in_valid) begin
                next_output_data_save[0] = one_bit_err_in_data;
            end
        end
        GET_DATA : begin
            for (i=0; i<=MAX_INPUT_LEN; i=i+1) begin
                next_output_data_save[i] = output_data_save[i];
            end
            if (one_bit_err_in_valid) begin
                next_output_data_save[offset_counter] = one_bit_err_in_data;
            end
        end
        FIX : begin
            for (i=0; i<=MAX_INPUT_LEN; i=i+1) begin
                next_output_data_save[i] = output_data_save[i];
            end

            if (offset_counter != in_data_len) begin

                case({output_data_save[offset_counter][0] ^ output_data_save[offset_counter][2] ^ output_data_save[offset_counter][4] ^ output_data_save[offset_counter][6] ^ output_data_save[offset_counter][8] ^ output_data_save[offset_counter][10],
                      output_data_save[offset_counter][1] ^ output_data_save[offset_counter][2] ^ output_data_save[offset_counter][5] ^ output_data_save[offset_counter][6] ^ output_data_save[offset_counter][9] ^ output_data_save[offset_counter][10],
                      output_data_save[offset_counter][3] ^ output_data_save[offset_counter][4] ^ output_data_save[offset_counter][5] ^ output_data_save[offset_counter][6] ^ output_data_save[offset_counter][11],
                      output_data_save[offset_counter][7] ^ output_data_save[offset_counter][8] ^ output_data_save[offset_counter][9] ^ output_data_save[offset_counter][10] ^ output_data_save[offset_counter][11]
                      })
                    4'b1100: next_output_data_save[offset_counter][2] = ~output_data_save[offset_counter][2];
                    4'b1010: next_output_data_save[offset_counter][4] = ~output_data_save[offset_counter][4];
                    4'b0110: next_output_data_save[offset_counter][5] = ~output_data_save[offset_counter][5];
                    4'b1110: next_output_data_save[offset_counter][6] = ~output_data_save[offset_counter][6];
                    4'b1001: next_output_data_save[offset_counter][8] = ~output_data_save[offset_counter][8];
                    4'b0101: next_output_data_save[offset_counter][9] = ~output_data_save[offset_counter][9];
                    // not 4'b1100
                    4'b1101: next_output_data_save[offset_counter][10] = ~output_data_save[offset_counter][10];
                    4'b0011: next_output_data_save[offset_counter][11] = ~output_data_save[offset_counter][11];
                    4'b1000: next_output_data_save[offset_counter][0] = ~output_data_save[offset_counter][0];
                    4'b0100: next_output_data_save[offset_counter][1] = ~output_data_save[offset_counter][1];
                    4'b0010: next_output_data_save[offset_counter][3] = ~output_data_save[offset_counter][3];
                    4'b0001: next_output_data_save[offset_counter][7] = ~output_data_save[offset_counter][7];
                    
                    default : begin
                        next_output_data_save[offset_counter] = next_output_data_save[offset_counter];
                    end
                endcase
                
                next_output_data_save[offset_counter] = {{4{1'b0}}, next_output_data_save[offset_counter][11:8], next_output_data_save[offset_counter][6:4], next_output_data_save[offset_counter][2]};
                
            end
            
        end
        DECRYPT : begin
            for (i=0; i<=MAX_INPUT_LEN; i=i+1) begin
                next_output_data_save[i] = output_data_save[i];
            end

            if (offset_counter != in_data_len) begin
            
                // - offset_counter % 128
                next_output_data_save[offset_counter] = output_data_save[offset_counter] - (offset_counter % 128);

            end
            
        end
        default : begin
            for (i=0; i<=MAX_INPUT_LEN; i=i+1) begin
                next_output_data_save[i] = output_data_save[i];
            end
        end
    endcase

end

// out_data change engine
// out_valid change engine
always @(posedge clk) begin
    if (rst) begin
        out_plaintext <= 0;
        out_plaintext_valid <= 0;
    end
    else begin
        out_plaintext <= next_out_data;
        out_plaintext_valid <= next_out_valid;
    end
end

// out_data change - write in
// out_valid change if-else determine
always @(*) begin
    case(state)
        OUTPUT_DATA : begin
            if (offset_counter != in_data_len) begin
                next_out_valid = 1;
                next_out_data = output_data_save[offset_counter][7:0];
            end
            else begin
                next_out_valid = 0;
                next_out_data = 0;
            end
        end
        default : begin
            next_out_data = 0;
            next_out_valid = 0;
        end
    endcase
end


endmodule