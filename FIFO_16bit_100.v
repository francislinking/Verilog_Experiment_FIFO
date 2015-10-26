module FIFO_16bit_100(clk,rst,fifo_wr,fifo_rd,state,error,head_p,end_p,fifo_in,fifo_out,nempty,nfull,wr,rd,clk_op);
input clk,rst;
input fifo_wr,fifo_rd;
input [15:0] fifo_in;

output state;
output head_p,end_p;
output fifo_out;
output error,wr,rd;
output nempty,nfull;
output clk_op;

reg [1:0] state;

reg wr,rd,error;
reg [6:0] head_p,end_p;

wire nempty,nfull,clk_op;
wire [15:0] fifo_out;

//initial begin nempty=0;nfull=1;end

parameter 	idle=2'b00,
			read=2'b01,
			write=2'b10;

assign clk_op=~clk;			
assign nempty=(end_p!=head_p)?1:0;
assign nfull=(end_p+1!=head_p)?1:0;			
			
//state control
always@(posedge clk)
begin
if(~rst)
begin
	state<=idle;
end
else
case(state)
idle:
begin
	case({fifo_wr,fifo_rd})//combine two signals
	2'b10:	
		begin
			if(nfull)
			begin
				state<=write;
				rd<=0;
				wr<=1;
			end
		end
		
	2'b01:	
		begin
			if(nempty)
			begin
				state<=read;
				rd<=1;
				wr<=0;
			end
		end
		
	default:
		begin
			state<=idle;
		end
	endcase
end

write:
begin
end_p<=end_p+1;

if(fifo_wr==0)
begin
	end_p<=end_p+1;
	wr<=0;
	rd<=0;
	state<=idle;
end	
else
begin
	if(nfull)
	begin
		wr<=1;
		rd<=0;
		state<=write;
	end
	else
	begin
		wr<=0;
		rd<=0;
		state<=idle;
	end
end
end

read:
begin
head_p<=head_p+1;

if(fifo_rd==0)
begin
	head_p<=head_p+1;
	wr<=0;
	rd<=0;
	state<=idle;
end	
else
begin
	if(nempty)
	begin
		wr<=0;
		rd<=1;
		state<=read;
	end
	else
	begin
		wr<=0;
		rd<=0;
		state<=idle;
	end
end
end
endcase
end

FIFO_RAM U1(
	.clock(clk_op),
	.data(fifo_in),
	.rdaddress(head_p),
	.rden(rd),
	.wraddress(end_p),
	.wren(wr),
	.q(fifo_out));


endmodule 