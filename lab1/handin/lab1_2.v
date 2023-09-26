`timescale 1ns/100ps
module lab1_2 (
    input wire [5:0] source_0,
    input wire [5:0] source_1,
    input wire [5:0] source_2,
    input wire [5:0] source_3,
    output reg [3:0] result
); 
    /* Note that result can be either reg or wire. 
    * It depends on how you design your module. */
    // add your design here 
    wire [3:0] request;
    wire [3:0] grant;
    
    assign request[3] = source_3[5] | source_3[4];
    assign request[2] = source_2[5] | source_2[4];
    assign request[1] = source_1[5] | source_1[4];
    assign request[0] = source_0[5] | source_0[4];
    
    lab1_1 arb(.request(request), .grant(grant));
    
    always @* begin
        result = 4'b0000;
        #0.5;
        case(grant)
            4'b1000: result = process(source_3);
            4'b0100: result = process(source_2);
            4'b0010: result = process(source_1);
            4'b0001: result = process(source_0);
        endcase
    end
    
    function [3:0] process;
        input [5:0] source;
        begin
            process = 4'b0000;
            case(source[5:4])
                2'b01:  process = source[3:0] & 4'b1010;
                2'b10:  process = source[3:0] + 4'd3;
                2'b11:  process = source[3:0] << 2;
            endcase
        end
    endfunction
endmodule

module lab1_1 (
    input wire [3:0] request,
    output reg [3:0] grant
); 
    always @* begin
        grant = 4'b0000;
        if(request[3])
            grant = 4'b1000;
        else if(request[2])
            grant = 4'b0100;
        else if(request[1])
            grant = 4'b0010;
        else if(request[0])
            grant = 4'b0001;
    end
endmodule