module twelve_four_fixed_decimal_w_neg (
	input [15:0] val,
	output [6:0] seg7_neg_sign,
	output [6:0] seg7_thousand,
	output [6:0] seg7_hundred,
	output [6:0] seg7_ten,
	output [6:0] seg7_one,
	output [6:0] seg7_tenth,
	output [6:0] seg7_centi,
	output [6:0] seg7_milli,
	output [6:0] seg7_tenth_milli
);

reg [3:0] result_thousand;
reg [3:0] result_hundred;
reg [3:0] result_ten;
reg [3:0] result_one;
reg [3:0] result_tenth;
reg [3:0] result_centi;
reg [3:0] result_milli;
reg [3:0] result_tenth_milli;
reg result_is_negative;

reg [15:0] twos_comp;

always@(*)
begin
	result_is_negative = val[15];
	
	if (result_is_negative)
		twos_comp[15:0] = 16'b1000000000000000 - val[14:0];
	else
		twos_comp = val;
		
	result_tenth_milli = (twos_comp[3:0] * 12'd625) % 4'd10;
	result_milli = ((twos_comp[3:0] * 12'd625) / 12'd10) % 4'd10; 
	result_centi = ((twos_comp[3:0] * 12'd625) / 12'd100) % 4'd10;
	result_tenth = ((twos_comp[3:0] * 12'd625) / 12'd1000) % 4'd10;
	result_one = twos_comp[15:4] % 12'd10;
	result_ten = (twos_comp[15:4] / 12'd10) % 12'd10;
	result_hundred = (twos_comp[15:4] / 12'd100) % 12'd10;
	result_thousand = (twos_comp[15:4] / 12'd1000) % 12'd10;
	
end

seven_segment_negative neg(result_is_negative, seg7_neg_sign);
seven_segment thousand(result_thousand, seg7_thousand);
seven_segment hundred(result_hundred, seg7_hundred);
seven_segment ten(result_ten, seg7_ten);
seven_segment one(result_one, seg7_one);
seven_segment tenth(result_tenth, seg7_tenth);
seven_segment centi(result_centi, seg7_centi);
seven_segment milli(result_milli, seg7_milli);
seven_segment tenth_milli(result_tenth_milli, seg7_tenth_milli);

endmodule 