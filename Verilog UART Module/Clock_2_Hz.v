module Clock_2_Hz (
 input clk_in,
 input [1:0] SW,
 output [1:0] LED,
 output clk_out
);
 reg [24:0] cnt=1;
 reg tick=0;
 always @(negedge clk_in )
	begin
		cnt<= cnt +1;
	
if(cnt>= 6000000)
		begin
		cnt <= 0;
		tick=~tick;
		end
		end

 assign clk_out = tick;
endmodule