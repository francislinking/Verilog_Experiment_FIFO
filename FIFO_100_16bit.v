`define SRAM_SIZE 8
module FIFO_100_16bit(
					in_data,
					out_data,
					fiford,
					fifowr,
					nfull,
					nempty,
					address,
					sram_data,
					rd,
					wr,
					clk,
					rst,
					state
					);

//control signal
input fiford,fifowr,clk,rst;

//data signal
input [15:0] in_data;
output [15:0] out_data;
reg [15:0]	in_data_buf,
			out_data_buf;

//output indication signal
output nfull,nempty;
reg nfull,nempty;

//SRAM control signal			
output rd,wr;
inout [15:0] sram_data;

//SRAM double databus 
output [10:0] address;
reg [10:0] address;

//internal register
reg [10:0] 	fifo_wp,
			fifo_rp;

reg [10:0] 	fifo_wp_next,
			fifo_rp_next;
			
reg near_full,near_empty;

output reg [3:0] state;	//SRAM action state machine

parameter 	idle		=	4'b0000,
			read_ready	=	4'b0100,
			read		=	4'b0101,
			read_over	=	4'b0111,
			write_ready	=	4'b1000,
			write		=	4'b1001,
			write_over	=	4'b1011;
			
always@(posedge clk)
if(!rst)
	state<=idle;
else
	case(state)
idle:
	if(fifowr == 0)
		state<=write_ready;
	else if(fiford == 0)
		state <= read_ready;
	else
		state <= idle;
read_ready:
	state<=read;
read:
	if(fiford == 1)
		state <=read_over;
	else
		state <= read;
read_over:
	state<=idle;

write_ready:
	state<=write;

write:
	if(fifowr==1)
		state<=write_over;
	else
		state<= write;
write_over:
	state <= idle;
	
default:state<=idle;
endcase

//generate SRAM action signal
assign rd = !state[2];
assign wr = (state == write)?fifowr:1'b1;

assign sram_data=(state[3])?in_data_buf:8'hzz;

always@(state or fiford or fifowr or fifo_wp or fifo_rp)
if(state[2] || ~fiford)
	address = fifo_rp;
else if (state[3] || ~fifowr)
	address = fifo_wp;
else
	address = 11'bz;
	
//generate FIFO data
assign out_data = (state[2])?sram_data:8'bz;

always@(posedge clk)
if(state == read)
	out_data_buf <= sram_data;
	
//calc FIFO W/R pointer
always@(posedge clk)
if(~rst)
	fifo_rp<=0;
else if(state == read_over)
	fifo_rp<=fifo_rp_next;
	
always@(fifo_rp)
if(fifo_rp == `SRAM_SIZE - 1)
	fifo_rp_next = 0;
else
	fifo_rp_next = fifo_rp + 1;
	
always@(posedge clk)
if(~rst)
	fifo_wp <= 0;
else if(state == write_over)
	fifo_wp<=fifo_wp_next;

always@(fifo_wp)
if(fifo_wp == `SRAM_SIZE - 1)
	fifo_wp_next = 0;
else
	fifo_wp_next = fifo_wp + 1;
	
always@(posedge clk)
if(~rst)
	near_empty <=1'b0;
else if(fifo_wp == fifo_rp_next)
	near_empty <=1'b1;
else 
	near_empty <=1'b0;
	
always@(posedge clk)
if(~rst)
	nempty <=1'b0;
else if(near_empty && state == read)
	nempty <=1'b0;
else if(state == write)
	nempty <=1'b1;
	
always @(posedge clk)
if(~rst)
	near_full <=1'b0;
else if(fifo_rp == fifo_wp_next)
	near_full <=1'b1;
else 
	near_full <=1'b0;
	
always@(posedge clk)
if(~rst)
	nfull <=1'b1;
else if(near_full && state == write)
	nfull <=1'b0;
else if(state == read)
	nfull <=1'b1;

endmodule 