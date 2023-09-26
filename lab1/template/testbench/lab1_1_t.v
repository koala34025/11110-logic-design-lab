module lab1_1_t ();

    parameter DELAY = 5;
    reg [3:0] request;
    wire [3:0] grant;

    //====================================
    // TODO
    // Connect your lab1_1 module here with "request" and "grant"
    // Please connect it by port name but not order


    //====================================

    integer i, error_count;
    initial begin
        $display("===== Simulation ======");
        error_count = 0;

        for(i = 0 ; i < 16 ; i = i + 1) begin
            
            request = i[3:0];
            //====================================
            // TODO
            // Understand why we put #DELAY here but not before "request" assigning or after if-else block
            #DELAY;
            //====================================
            if(grant !== golden_grant(request)) begin

                $display("[ERROR] request = %b, grant = %b, correct grant should be %b",
                    request, grant, golden_grant(request));
                error_count = error_count + 1;
            end
            else begin
                $display("[CORRECT] request = %b, grant = %b",
                    request, grant);
            end

        end

        if(error_count === 0)
            $display("All Correct!!");
        else    
            $display("There are %d errors QQ", error_count);


        $finish;
    end

    //====================================
    // TODO
    // Understand "function" usage, can it be synthsized? 
    function [3:0] golden_grant;
        input [3:0] request;
        begin
            if(request[3] === 1)
                golden_grant = 4'b1000;
            else if(request[2] === 1)
                golden_grant = 4'b0100;
            else if(request[1] === 1)
                golden_grant = 4'b0010;
            else if(request[0] === 1)
                golden_grant = 4'b0001;
            else
                golden_grant = 4'b0000;
        end
    endfunction
    //====================================

endmodule
