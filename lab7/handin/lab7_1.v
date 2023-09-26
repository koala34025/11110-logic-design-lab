module lab7_1(
    input clk,
    input rst,
    input en,
    input dir,
    input vmir,
    input hmir,
    output [3:0] vgaRed,
    output [3:0] vgaGreen,
    output [3:0] vgaBlue,
    output hsync,
    output vsync
);

wire [11:0] data;
wire clk_25MHz;
wire clk_22;
wire [16:0] pixel_addr;
wire [11:0] pixel;
wire valid;
wire [9:0] h_cnt; //640
wire [9:0] v_cnt;  //480

assign {vgaRed, vgaGreen, vgaBlue} = (valid==1'b1) ? pixel:12'h0;

clock_divider clk_wiz_0_inst(
    .clk(clk),
    .clk1(clk_25MHz),
    .clk22(clk_22)
);

my_mem_addr_gen mem_addr_gen_inst(
    .clk(clk_22),
    .rst(rst),
    .h_cnt(h_cnt),
    .v_cnt(v_cnt),
    .pixel_addr(pixel_addr),
    .dir(dir),
    .en(en),
    .vmir(vmir),
    .hmir(hmir)
);
     
 
blk_mem_gen_0 blk_mem_gen_0_inst(
    .clka(clk_25MHz),
    .wea(0),
    .addra(pixel_addr),
    .dina(data[11:0]),
    .douta(pixel)
); 

my_vga_controller   vga_inst(
    .pclk(clk_25MHz),
    .reset(rst),
    .hsync(hsync),
    .vsync(vsync),
    .valid(valid),
    .h_cnt(h_cnt),
    .v_cnt(v_cnt)
);
      
endmodule

module my_mem_addr_gen(
   input clk,
   input rst,
   input [9:0] h_cnt,
   input [9:0] v_cnt,
   output [16:0] pixel_addr,
   input dir,
   input en,
   input vmir,
   input hmir
   );
    
reg [7:0] position;
reg [7:0] next_position;
wire [16:0] pixel_addr_normal;
wire [16:0] pixel_addr_hmir;
wire [16:0] pixel_addr_vmir;
wire [16:0] pixel_addr_h_vmir;

assign pixel_addr = hmir == 1'b1 && vmir == 1'b1 ? pixel_addr_h_vmir : 
                    hmir == 1'b1 ? pixel_addr_hmir :
                    vmir == 1'b1 ? pixel_addr_vmir :
                    pixel_addr_normal;                    

assign pixel_addr_normal = ((h_cnt>>1)+320*(v_cnt>>1)+ position*320 )% 76800;  //640*480 --> 320*240 
assign pixel_addr_h_vmir = 76799 - pixel_addr_normal;
assign pixel_addr_hmir = (319-(h_cnt>>1)+320*(v_cnt>>1)+ position*320 )% 76800;
assign pixel_addr_vmir = ((h_cnt>>1)+320*(239-(v_cnt>>1))- position*320 )% 76800;

   always @ (posedge clk or posedge rst) begin
      if(rst) begin
          position <= 0;
      end
      else begin
            position <= next_position;
        end
   end
    
always @* begin
    next_position = position;
    if(en == 1'b1) begin
        if(dir == 1'b0) begin
            if(position < 239) begin
                next_position = position + 1;
            end
            else begin
                next_position = 0;
            end
        end
        else begin
            if(position > 0) begin
                next_position = position - 1;
            end
            else begin
                next_position = 239;
            end
        end
    end
end
   
endmodule

`timescale 1ns/1ps
/////////////////////////////////////////////////////////////////
// Module Name: vga
/////////////////////////////////////////////////////////////////

module my_vga_controller (
    input wire pclk, reset,
    output wire hsync, vsync, valid,
    output wire [9:0]h_cnt,
    output wire [9:0]v_cnt
    );

    reg [9:0]pixel_cnt;
    reg [9:0]line_cnt;
    reg hsync_i,vsync_i;

    parameter HD = 640;
    parameter HF = 16;
    parameter HS = 96;
    parameter HB = 48;
    parameter HT = 800; 
    parameter VD = 480;
    parameter VF = 10;
    parameter VS = 2;
    parameter VB = 33;
    parameter VT = 525;
    parameter hsync_default = 1'b1;
    parameter vsync_default = 1'b1;

    always @(posedge pclk)
        if (reset)
            pixel_cnt <= 0;
        else
            if (pixel_cnt < (HT - 1))
                pixel_cnt <= pixel_cnt + 1;
            else
                pixel_cnt <= 0;

    always @(posedge pclk)
        if (reset)
            hsync_i <= hsync_default;
        else
            if ((pixel_cnt >= (HD + HF - 1)) && (pixel_cnt < (HD + HF + HS - 1)))
                hsync_i <= ~hsync_default;
            else
                hsync_i <= hsync_default; 

    always @(posedge pclk)
        if (reset)
            line_cnt <= 0;
        else
            if (pixel_cnt == (HT -1))
                if (line_cnt < (VT - 1))
                    line_cnt <= line_cnt + 1;
                else
                    line_cnt <= 0;

    always @(posedge pclk)
        if (reset)
            vsync_i <= vsync_default; 
        else if ((line_cnt >= (VD + VF - 1)) && (line_cnt < (VD + VF + VS - 1)))
            vsync_i <= ~vsync_default; 
        else
            vsync_i <= vsync_default; 

    assign hsync = hsync_i;
    assign vsync = vsync_i;
    assign valid = ((pixel_cnt < HD) && (line_cnt < VD));

    assign h_cnt = (pixel_cnt < HD) ? pixel_cnt : 10'd0;
    assign v_cnt = (line_cnt < VD) ? line_cnt : 10'd0;

endmodule
