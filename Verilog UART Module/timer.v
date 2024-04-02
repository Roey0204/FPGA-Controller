module timer(
input clk_in,
output clk_out
);
reg [24:0] cnt;
reg tick=0;
always@(posedge clk_in)

if(cnt==359999)
begin
cnt=0;
tick =~tick;

end
else
begin
cnt=cnt+1;
end
assign clk_out = tick;
endmodule
