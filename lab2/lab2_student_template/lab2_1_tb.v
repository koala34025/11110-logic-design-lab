`timescale 1ns/100ps
	  		  	
`define CYCLE_TIME 20.0
module Lab2_1_PATTERN(
    // input
    out_data,
    out_valid,
    // output
    clk,
    rst,
    in_data,
    in_valid
);
//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
output reg clk;
output reg rst;
output reg [7:0] in_data;
output reg in_valid;

input [11:0] out_data;
input out_valid;
//================================================================
// parameters & integer
//================================================================
integer PATNUM = 12;
integer seed;
integer total_latency;
integer patcount;
integer file_in, file_in_enc;
integer i,j;
//================================================================
// wire & registers 
//================================================================
reg [7:0] in_data_save[255:0];
reg [11:0] in_data_save_encryp[255:0];
reg [7:0] in_data_len;
reg [7:0] out_data_len;
reg [7:0] encryption_tmp;
//================================================================
// clock
//================================================================
real	CYCLE = `CYCLE_TIME;
always	#(CYCLE/2.0) clk = ~clk;
initial	clk = 0;
integer  a;
//================================================================
// initial
//================================================================
initial begin

    in_data = 8'dx;
    in_valid = 0;
	rst = 0;
    
	reset_task;

	total_latency = 0;
	seed = 32;
    @(negedge clk);

    file_in = $fopen("message.txt", "r");
    file_in_enc = $fopen("message_enc.txt", "r");

	for(patcount = 0; patcount < PATNUM; patcount = patcount + 1)
	begin		
		gen_lab2_1_data;
		gen_lab2_1_golden;
		check_lab2_1_ans;

        $display ("         lab2_1  Pass Pattern NO. %d          ", patcount);

		repeat(2 + $random(seed) % 8) @(negedge clk);
	end
    
	display_pass;
    
    repeat(3) @(negedge clk);
	$fclose(file_in);
	$fclose(file_in_enc);
    $finish;
end

always @(*) begin
    if (in_valid === 1 && out_valid === 1) begin
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                        FAIL!                                                               ");
		$display ("                                                  output_valid should not be high when in_valid is high                                      ");
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
	    $finish ;
    end
end

always @(posedge clk) begin
    total_latency = total_latency + 1;
    if (total_latency >= 10000) begin
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                        FAIL!                                                               ");
		$display ("                                                             Simulation cycle limit reach                                                  ");
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
	    $finish ;
    end

end

//================================================================
// task
//================================================================
task reset_task ; begin
    @(negedge clk);
    rst = 1;
    @(negedge clk);
    rst = 0;
    repeat(2) @(negedge clk);
	if((out_data !== 0 || out_valid !== 0)) begin
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                        FAIL!                                                               ");
		$display ("                                                  Output signal should be 0 after initial RESET at %8t                                      ",$time);
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
	    $finish ;
	end
end endtask

task gen_lab2_1_data; begin
    a = $fscanf(file_in, "%d\n",in_data_len);
    for (i=0; i<in_data_len; i=i+1) begin
        a = $fscanf(file_in, "%c",in_data);
        in_data_save[i] = in_data;
        in_valid = 1;
        @(negedge clk);
    end
    a = $fscanf(file_in, "\n");
    a = $fscanf(file_in, "\n");
    in_data = 8'dx;
    in_valid = 1'b0;
end endtask


task gen_lab2_1_golden; begin
    a = $fscanf(file_in_enc, "%d\n", out_data_len);
    for (i=0; i<in_data_len; i=i+1) begin
        a = $fscanf(file_in_enc, "%d",in_data_save_encryp[i]);
    end 
    a = $fscanf(file_in_enc, "\n");
    a = $fscanf(file_in_enc, "\n");
end endtask

task check_lab2_1_ans; begin
    
    while(out_valid !== 1) begin
        @(negedge clk);
    end

    for (i=0; i<in_data_len; i=i+1) begin
        if (out_valid === 0) begin
            display_fail;
            $display ("-------------------------------------------------------------------");
            $display("                       PATTERN NO.%4d Word index NO.%8d 	     ",patcount, i);
            $display ("                            out_valid end early           ");
            $display ("-------------------------------------------------------------------");
            #(100);
            $finish ;
        end
        if(out_data !== in_data_save_encryp[i])
        begin
            display_fail;
            $display ("-------------------------------------------------------------------");
            $display("                       PATTERN NO.%4d Word index NO.%8d 	     ",patcount, i);
            $display ("             answer should be : %11d , your answer is : %11d           ", in_data_save_encryp[i], out_data);
            $display ("-------------------------------------------------------------------");
            #(100);
            $finish ;
        end
        @(negedge clk);
    end
    if (out_valid !== 0) begin
        display_fail;
        $display ("-------------------------------------------------------------------");
        $display("                                PATTERN NO.%4d	     ",patcount);
        $display ("                            out_valid didn't end                  ");
        $display ("-------------------------------------------------------------------");
        #(100);
        $finish ;
    end
end
endtask

task display_fail;
begin
    $display("======   lab2_1 Error.    ========");
    $display("\n");
end
endtask

task display_pass;
begin
    $display("=================   lab2_1  Your colleagues used the information defeating the enemy.    ==============================");
    $display("\n");
end
endtask

endmodule


module Lab2_1_TESTBED; 

//Connection wires
wire [7:0] in_data;
wire clk;
wire rst;
wire [11:0] out_data; 
wire in_valid, out_valid;

initial begin
  `ifdef RTL
    $dumpfile("DUT.vcd");
    $dumpvars("+all");
  `endif
end

Encoder My_encoder(
.clk(clk),
.rst(rst),
.in_data(in_data),
.in_valid(in_valid),
.out_data(out_data),
.out_valid(out_valid)
);

Lab2_1_PATTERN My_PATTERN(
.clk(clk),
.rst(rst),
.in_data(in_data),
.in_valid(in_valid),
.out_data(out_data),
.out_valid(out_valid)
);
 
endmodule
