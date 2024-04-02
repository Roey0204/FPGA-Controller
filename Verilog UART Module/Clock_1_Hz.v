module Clock_1_Hz (
 input clk_in,
 input [1:0] SW,
 output [1:0] LED,
 output clk_out
);
 reg [27:0] cnt=1;
 reg tick=0;
 always @(posedge clk_in)
	begin
		cnt<= cnt +1;
	
if(cnt>= 59999)
		begin
		cnt <= 0;
		tick=~tick;
		end
		end

 assign clk_out = tick;
endmodule