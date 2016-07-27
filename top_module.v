module ov7670_top(
clk50,
rst,
//OV7670 signals
OV7670_SIOC,
OV7670_SIOD,
OV7670_RESET,
OV7670_PWDN,
OV7670_VSYNC,
OV7670_HREF,
OV7670_PCLK,
OV7670_XCLK,
OV7670_D,
//ARM CPU input to freeze/unfreeze the camera
control,
btn,
//Led indicator
select_output,
//Axi read_enable signal 
read_enable,
//The 3 outputs for the 4 24-bit pixels
slv1,slv2,slv3
);

input clk50,rst,control,read_enable;
input OV7670_VSYNC,OV7670_HREF,OV7670_PCLK,btn;
output OV7670_SIOC,OV7670_RESET,OV7670_PWDN,OV7670_XCLK;
inout OV7670_SIOD;
input [7:0]OV7670_D;
output select_output;
output [31:0] slv1,slv2,slv3;
wire [18:0] capture_addr,select_addr;
wire [11:0] capture_data;
wire [47:0] frame_pixel;
wire capture_we,resend,config_finished,clk_feedback,buffered_pclk,ena,write_done;
wire displayH,displayV;
reg [16:0]frame_addr;

assign select_addr = (select_output) ? 0 : capture_addr;

//Convert the 8-bit RGB format to 24-bit for 4 pixels
assign slv1[31:24] = {frame_pixel[47:45],5'b0};	//R
assign slv1[23:16] = {frame_pixel[43:41],5'b0};	//G
assign slv1[15:8]  = {frame_pixel[39:38],6'b0};	//B

assign slv1[7:0]   = {frame_pixel[35:33],5'b0};	//R
assign slv2[31:24] = {frame_pixel[31:29],5'b0};	//G
assign slv2[23:16] = {frame_pixel[27:26],6'b0};	//B

assign slv2[15:8]  = {frame_pixel[23:21],5'b0};	//R
assign slv2[7:0]   = {frame_pixel[19:17],5'b0};	//G
assign slv3[31:24] = {frame_pixel[15:14],6'b0};	//B

assign slv3[23:16] = {frame_pixel[11:9],5'b0};		//R
assign slv3[15:8]  = {frame_pixel[7:5],5'b0};		//G
assign slv3[7:0]   = {frame_pixel[3:2],6'b0};		//B

debounce DB1(clk50,btn,resend);

ov7670_controller CNTRL(clk50,resend,config_finished,OV7670_SIOC,OV7670_SIOD,OV7670_RESET,OV7670_PWDN,OV7670_XCLK);

//Need to create a dual-port BRAM with:
//Port A options width:12 , Depth:307200, Always enabled
//Port B options width:48 , Depth:76800, Always enabled

blk_mem_gen_0 BLK(OV7670_PCLK,capture_we,select_addr,capture_data,clk50,frame_addr,frame_pixel);

ov7670_capture CPTR(OV7670_PCLK,OV7670_VSYNC,OV7670_HREF,OV7670_D,capture_addr,capture_data,capture_we);

address_selector SEL(clk50,capture_addr,control,select_output,write_done);

//Increase the frame_addr only when the slv1_reg is accessed 
//When a full size image is sent, reset the frame_addr
always@(posedge clk50)
begin
    if(rst)
    begin
        frame_addr <= 0;
    end else begin
        if(control)begin  
            if(read_enable)
            begin
                if(frame_addr >= 76799)
                begin
                    frame_addr <= 0;
                end else begin
                    frame_addr <= frame_addr + 1;
                end
            end else begin
                frame_addr <= frame_addr;
            end
        end
        else begin
            frame_addr <= 0;
        end
    end
end

endmodule