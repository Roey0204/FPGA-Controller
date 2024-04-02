
// This rom is used to map the user eye monitor phase steps (linear increasing from 0 to 63)
//  to the hardware values (non-linear).

module alt_eyemon_rom (
  i_addr,
  o_data
);

  input      [5:0] i_addr;
  output reg [5:0] o_data;
  
  always @ (*) begin
    case (i_addr)
      6'b000000: o_data = 6'b111111; // phase step '1' in NPP
      6'b000001: o_data = 6'b111110;
      6'b000010: o_data = 6'b111101;
      6'b000011: o_data = 6'b111100;
      6'b000100: o_data = 6'b111011;
      6'b000101: o_data = 6'b111010;
      6'b000110: o_data = 6'b111001;
      6'b000111: o_data = 6'b111000;
      6'b001000: o_data = 6'b110111;
      6'b001001: o_data = 6'b110110;
      6'b001010: o_data = 6'b110101;
      6'b001011: o_data = 6'b110100;
      6'b001100: o_data = 6'b110011;
      6'b001101: o_data = 6'b110010;
      6'b001110: o_data = 6'b110001;
      6'b001111: o_data = 6'b110000;
      6'b010000: o_data = 6'b010000; // phase step '17' in NPP
      6'b010001: o_data = 6'b010001;
      6'b010010: o_data = 6'b010010;
      6'b010011: o_data = 6'b010011;
      6'b010100: o_data = 6'b010100;
      6'b010101: o_data = 6'b010101;
      6'b010110: o_data = 6'b010110;
      6'b010111: o_data = 6'b010111;
      6'b011000: o_data = 6'b011000;
      6'b011001: o_data = 6'b011001;
      6'b011010: o_data = 6'b011010;
      6'b011011: o_data = 6'b011011;
      6'b011100: o_data = 6'b011100;
      6'b011101: o_data = 6'b011101;
      6'b011110: o_data = 6'b011110;
      6'b011111: o_data = 6'b011111;
      6'b100000: o_data = 6'b001111; // phase step '33' in NPP
      6'b100001: o_data = 6'b001110;
      6'b100010: o_data = 6'b001101;
      6'b100011: o_data = 6'b001100;
      6'b100100: o_data = 6'b001011;
      6'b100101: o_data = 6'b001010;
      6'b100110: o_data = 6'b001001;
      6'b100111: o_data = 6'b001000;
      6'b101000: o_data = 6'b000111;
      6'b101001: o_data = 6'b000110;
      6'b101010: o_data = 6'b000101;
      6'b101011: o_data = 6'b000100;
      6'b101100: o_data = 6'b000011;
      6'b101101: o_data = 6'b000010;
      6'b101110: o_data = 6'b000001;
      6'b101111: o_data = 6'b000000;
      6'b110000: o_data = 6'b100000; // phase step '49' in NPP
      6'b110001: o_data = 6'b100001;
      6'b110010: o_data = 6'b100010;
      6'b110011: o_data = 6'b100011;
      6'b110100: o_data = 6'b100100;
      6'b110101: o_data = 6'b100101;
      6'b110110: o_data = 6'b100110;
      6'b110111: o_data = 6'b100111;
      6'b111000: o_data = 6'b101000;
      6'b111001: o_data = 6'b101001;
      6'b111010: o_data = 6'b101010;
      6'b111011: o_data = 6'b101011;
      6'b111100: o_data = 6'b101100;
      6'b111101: o_data = 6'b101101;
      6'b111110: o_data = 6'b101110;
      6'b111111: o_data = 6'b101111; // phase step '64' in NPP
      default:   o_data = 6'b111111; // default to all 1s (maps to phase step '1' in NPP)
    endcase
  end
  
endmodule
