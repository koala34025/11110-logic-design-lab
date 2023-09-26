`timescale 1ns/100ps
module lab1_2_t ();

    parameter DELAY = 1;
    parameter testcase_num = 2**8;
    reg [5:0] source_0, source_1, source_2, source_3;
    wire [3:0] result;

    //====================================
    // TODO
    // Connect your lab1_2 module here with "source_0", "source_1", "source_2", "source_3", and "result"
    // Please connect it by port name but not order

    //====================================
    integer i, error_count, file;
    integer rand_num;
    reg [3:0] golden;
    initial begin

        file = $fopen("public.dat", "r");
        if(!file) begin
            $display("[ERROR] File open error, please follow Appendix to add correct pattern file");
            $finish;
        end
        
        $display("===== Simulation ======");
        error_count = 0;
        for(i = 0 ; i < testcase_num ; i = i + 1) begin

            $fscanf(file,"%b %b %b %b %b" ,source_0, source_1, source_2, source_3, golden);

            #DELAY;
            if(result === golden) begin
                $display("[CORRECT] s0 = %b, s1 = %b, s2 = %b, s3 = %b, result = %b",
                    source_0, source_1, source_2, source_3, result);
            end
            else begin
                $display("[ERROR] s0 = %b, s1 = %b, s2 = %b, s3 = %b, result = %b, correct result should be %b",
                    source_0, source_1, source_2, source_3, result,golden);
                error_count = error_count + 1;
            end

        end

        if(error_count === 0)
            $display("All Correct!!");
        else    
            $display("There are %d errors QQ", error_count);


        $fclose(file);
        $finish;
    end

endmodule
