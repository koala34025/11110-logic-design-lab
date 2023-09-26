`timescale 1ns/100ps
module lab1_1 (
    input wire [3:0] request,
    output reg [3:0] grant
); 
    /* Note that grant can be either reg or wire.
    * e.g.,		output reg [3:0] grant
    * or 		output wire [3:0] grant
    * It depends on how you design your module. */
    // add your design here 
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
