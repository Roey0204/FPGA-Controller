module top
(
	input clk,
	input rst_n,
	input rxd,
	input btn,
	output step,
	output step1,
	output dir,
	output enable,
	output txd,
	output led,
	output buzzer,
	output reg [2:0] light
);
parameter S_RD_IDLE   = 2'd0;
parameter S_RD_FIFO   = 2'd1;
parameter S_RD_SEND   = 2'd2;

parameter S_WR_IDLE   = 2'd0;
parameter S_WR_SEND   = 2'd1;



wire[7:0] uart_tx_data;
wire uart_tx_ready;
wire uart_tx_data_en;
reg[7:0] buf_data;
reg buf_rdreq;
reg buf_wrreq;
wire buf_empty;


reg[24:0] m=0;
reg[24:0] n=0;
reg direction =0;
reg direction1=0;
reg switch =0;
reg switch1 =0;
reg[24:0] motor =0;
reg[24:0] motor1 =0;
reg control=0;
wire stop=0;


reg cnt =0;
reg voice=0;
reg signal=0;

reg[31:0] timer_cnt;

reg[1:0] rd_state;
reg[1:0] wr_state;


reg[7:0] byte_cnt;
wire timer1;
wire timer2;
assign uart_tx_data_en = (rd_state == S_RD_SEND);

Clock_1_Hz Clock_1_Hz (
 .clk_in(clk),
 .clk_out(timer1)
 );

 timer timer(
 .clk_in(clk),
 .clk_out(timer2)
 );
 
 Clock_2_Hz Clock_2_Hz (
 .clk_in(clk),
 .clk_out(timer3)
 ); 

always@(posedge timer3)
begin
if(rx_data=="v")
begin
voice<=voice+1;
if(~btn)
begin
voice<=0;
end
end



end
 
 
 
always@(posedge clk)
begin
if(rx_data=="N")
begin
direction<=1;
end
else if(rx_data=="R") 
begin
direction<=0;
end

else if(rx_data=="v") 
begin
direction<=1;
end

end


always@(posedge timer1)
begin
if(rx_data=="A")
begin
m<=512;            //45

end

else if(rx_data=="B")
begin
m<=1024;            //90

end
else if(rx_data=="C")
begin
m<=1536;            //135

end

else if(rx_data=="D")
begin
m<=2048;            //180

end

else if(rx_data=="E")
begin
m<=2560;            //225

end
else if(rx_data=="F")
begin
m<=3072;          //270 

end

else if(rx_data=="G")
begin
m<=3584;          //270 

end
else if(rx_data=="H")
begin
m<=4096;            //360
  
end
end


always@(posedge timer2)
begin
if(rx_data=="8")
begin
motor1<=motor1+1;
switch1<=1;
if(motor1>m)
begin
switch1<=0;

end
end

else if(rx_data=="4")
begin
motor1<=0;
switch1<=0;
if(~btn)
begin
motor1<=0;
switch1<=0;
end
end

end



always@(posedge timer1)
begin
if(rx_data=="3") 
begin
control<=1;
motor<=motor+1;
switch<=1;
if(motor>m)
begin
switch<=0;

end

end
else if(rx_data=="4") 
begin
control<=0;
motor<=0;
if(~btn)
begin
control<=0;
motor<=0;
end
end
else if(rx_data=="v") 
begin
control<=1;
motor<=motor+1;
switch<=1;
if(~btn)
begin
switch<=0;
control<=0;
motor<=0;
end

end



end


always@(posedge clk or negedge rst_n)
begin
	if(~rst_n)
	begin
		buf_rdreq <= 1'b0;
		rd_state <= S_RD_IDLE;
	end
	else
	begin
		case(rd_state)
			S_RD_IDLE:
			begin
				if(~buf_empty)
				begin
					buf_rdreq <= 1'b1;
					rd_state <= S_RD_FIFO;
				end
			end
			S_RD_FIFO:
			begin
				buf_rdreq <= 1'b0;
				rd_state <= S_RD_SEND;
			end
			S_RD_SEND:
			begin
				if(uart_tx_ready)
					rd_state <= S_RD_IDLE;
				else
					rd_state <= S_RD_SEND;
			end
			default:
				rd_state <= S_RD_IDLE;
		endcase
	end
	
end

wire[7:0] rx_data;
wire rx_data_en;
uart_rx uart_rx_m0
(
	.clk(clk),
	.rst_n(rst_n),
	.rxd(rxd),
	.rx_data(rx_data),
	.rx_data_en(rx_data_en)
);
uart_tx uart_tx_m0(
	.clk(clk),
	.rst_n(rst_n),
	.tx_data_en(uart_tx_data_en),
	.tx_data(uart_tx_data),
	.ready(uart_tx_ready),
	.txd(txd)
);

uart_buf uart_buf_m0(
	.aclr(~rst_n),
	.clock(clk),
	.data(rx_data),                          //the data we wrote inside
	//.data(rx_data_en? rx_data:buf_data),
	.rdreq(buf_rdreq),
	.wrreq(rx_data_en),
	//.wrreq(buf_wrreq | rx_data_en),
	.empty(buf_empty),
	.full(),
	.q(uart_tx_data),                           //the data we read from coupter (fpga data transmit)
	.usedw());
	
	

assign step =motor^motor1;

assign buzzer=(voice);
assign dir= direction;

assign enable =control?~switch:~switch1;
	
endmodule 





