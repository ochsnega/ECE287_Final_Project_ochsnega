module LU_Decomposition_parallel (
	input clk, 
	input rst, 
	input en, 
	input [15:0] A00,
	input [15:0] A01,
	input [15:0] A02,
	input [15:0] A10,
	input [15:0] A11,
	input [15:0] A12,
	input [15:0] A20,
	input [15:0] A21,
	input [15:0] A22,
	input [15:0] C0,
	input [15:0] C1,
	input [15:0] C2,
	output reg [15:0] X0, // X0 = (C0 - A01_mult_X1 - A02_mult_X2)_div_A00 (16, 17, 18)
	output reg [15:0] X1, // X1 = (Z1 - U12_mult_X2)_div_U11 (14, 15)
	output reg [15:0] X2, // X2 = Z2_div_U22 (13) 
	output reg [15:0] L10, // L10 = A10_div_A00 (1)
	output reg [15:0] L20, // L20 = A20_div_A00 (2)
	output reg [15:0] L21, // L21 = (A_21 - L20_mult_A01)_div_U11 (4, 5)
	output reg [15:0] U11, // U11 = A11 - L10_mult_A01 (3)
	output reg [15:0] U12, // U12 = A12 - L10_mult_A02 (6)
	output reg [15:0] U22, // U22 = (A22 - L20_mult_A02) - L21_mult_U12 (7, 8, 9)
	output reg [15:0] Z1, // Z1 = C1 - L10_mult_C0 (10)
	output reg [15:0] Z2, // Z2 = C2 - L20_mult_C0 - L21_mult_Z1 (11, 12)
	output reg done,
	output reg error_ovf,
	output reg error_dbz,
	output reg error_fsm,
	output reg test
);

/* //Multiplication module header
module mul #(
    parameter WIDTH=16,  // width of numbers in bits (integer and fractional)
    parameter FBITS=4   // fractional bits within WIDTH
    ) (
    input wire logic clk,    // clock
    input wire logic rst,    // reset
    input wire logic start,  // start calculation
    output     logic busy,   // calculation in progress
    output     logic done,   // calculation is complete (high for one tick)
    output     logic valid,  // result is valid
    output     logic ovf,    // overflow
    input wire logic signed [WIDTH-1:0] a,   // multiplier (factor)
    input wire logic signed [WIDTH-1:0] b,   // mutiplicand (factor)
    output     logic signed [WIDTH-1:0] val  // result value: product
    );
*/

/* //Division module header
module div #(
    parameter WIDTH=16,  // width of numbers in bits (integer and fractional)
    parameter FBITS=4   // fractional bits within WIDTH
    ) (
    input wire logic clk,    // clock
    input wire logic rst,    // reset
    input wire logic start,  // start calculation
    output     logic busy,   // calculation in progress
    output     logic done,   // calculation is complete (high for one tick)
    output     logic valid,  // result is valid
    output     logic dbz,    // divide by zero
    output     logic ovf,    // overflow
    input wire logic signed [WIDTH-1:0] a,   // dividend (numerator)
    input wire logic signed [WIDTH-1:0] b,   // divisor (denominator)
    output     logic signed [WIDTH-1:0] val  // result value: quotient
    );
*/

reg inv_rst;

always@(*)
	inv_rst = !rst;
	
//Instantiate multipliers and dividers. (Note, this may not be the most efficient way to do this.
reg L10_start;
wire L10_busy, L10_done, L10_valid, L10_dbz, L10_ovf;
reg [15:0] L10_dividend, L10_divisor;
wire [15:0] L10_quotient;
div calc_L10 (clk, inv_rst, L10_start, L10_busy, L10_done, L10_valid, L10_dbz, L10_ovf, L10_dividend, L10_divisor, L10_quotient);

reg L20_start;
wire L20_busy, L20_done, L20_valid, L20_dbz, L20_ovf;
reg [15:0] L20_dividend, L20_divisor;
wire [15:0] L20_quotient;
div calc_L20 (clk, inv_rst, L20_start, L20_busy, L20_done, L20_valid, L20_dbz, L20_ovf, L20_dividend, L20_divisor, L20_quotient);

reg U11_start;
wire U11_busy, U11_done, U11_valid, U11_ovf;
reg [15:0] U11_multiplier, U11_multiplicand;
wire [15:0] U11_product;
mul calc_U11 (clk, inv_rst, U11_start, U11_busy, U11_done, U11_valid, U11_ovf, U11_multiplier, U11_multiplicand, U11_product);

reg L21_num_start;
wire L21_num_busy, L21_num_done, L21_num_valid, L21_num_ovf;
reg [15:0] L21_num_multiplier, L21_num_multiplicand;
wire [15:0] L21_num_product;
mul calc_L21_num (clk, inv_rst, L21_num_start, L21_num_busy, L21_num_done, L21_num_valid, L21_num_ovf, L21_num_multiplier, L21_num_multiplicand, L21_num_product);

reg L21_start;
wire L21_busy, L21_done, L21_valid, L21_dbz, L21_ovf;
reg [15:0] L21_dividend, L21_divisor;
wire [15:0] L21_quotient;
div calc_L21 (clk, inv_rst, L21_start, L21_busy, L21_done, L21_valid, L21_dbz, L21_ovf, L21_dividend, L21_divisor, L21_quotient);

reg U12_start;
wire U12_busy, U12_done, U12_valid, U12_ovf;
reg [15:0] U12_multiplier, U12_multiplicand;
wire [15:0] U12_product;
mul calc_U12 (clk, inv_rst, U12_start, U12_busy, U12_done, U12_valid, U12_ovf, U12_multiplier, U12_multiplicand, U12_product);

reg U22_outer_start;
wire U22_outer_busy, U22_outer_done, U22_outer_valid, U22_outer_ovf;
reg [15:0] U22_outer_multiplier, U22_outer_multiplicand;
wire [15:0] U22_outer_product;
mul calc_U22_outer (clk, inv_rst, U22_outer_start, U22_outer_busy, U22_outer_done, U22_outer_valid, U22_outer_ovf, U22_outer_multiplier, U22_outer_multiplicand, U22_outer_product);

reg U22_start;
wire U22_busy, U22_done, U22_valid, U22_ovf;
reg [15:0] U22_multiplier, U22_multiplicand;
wire [15:0] U22_product;
mul calc_U22 (clk, inv_rst, U22_start, U22_busy, U22_done, U22_valid, U22_ovf, U22_multiplier, U22_multiplicand, U22_product);

reg Z1_start;
wire Z1_busy, Z1_done, Z1_valid, Z1_ovf;
reg [15:0] Z1_multiplier, Z1_multiplicand;
wire [15:0] Z1_product;
mul calc_Z1 (clk, inv_rst, Z1_start, Z1_busy, Z1_done, Z1_valid, Z1_ovf, Z1_multiplier, Z1_multiplicand, Z1_product);

reg Z2_first_start;
wire Z2_first_busy, Z2_first_done, Z2_first_valid, Z2_first_ovf;
reg [15:0] Z2_first_multiplier, Z2_first_multiplicand;
wire [15:0] Z2_first_product;
mul calc_Z2_first (clk, inv_rst, Z2_first_start, Z2_first_busy, Z2_first_done, Z2_first_valid, Z2_first_ovf, Z2_first_multiplier, Z2_first_multiplicand, Z2_first_product);

reg Z2_start;
wire Z2_busy, Z2_done, Z2_valid, Z2_ovf;
reg [15:0] Z2_multiplier, Z2_multiplicand;
wire [15:0] Z2_product;
mul calc_Z2 (clk, inv_rst, Z2_start, Z2_busy, Z2_done, Z2_valid, Z2_ovf, Z2_multiplier, Z2_multiplicand, Z2_product);

reg X2_start;
wire X2_busy, X2_done, X2_valid, X2_dbz, X2_ovf;
reg [15:0] X2_dividend, X2_divisor;
wire [15:0] X2_quotient;
div calc_X2 (clk, inv_rst, X2_start, X2_busy, X2_done, X2_valid, X2_dbz, X2_ovf, X2_dividend, X2_divisor, X2_quotient);

reg X1_num_start;
wire X1_num_busy, X1_num_done, X1_num_valid, X1_num_ovf;
reg [15:0] X1_num_multiplier, X1_num_multiplicand;
wire [15:0] X1_num_product;
mul calc_X1_num (clk, inv_rst, X1_num_start, X1_num_busy, X1_num_done, X1_num_valid, X1_num_ovf, X1_num_multiplier, X1_num_multiplicand, X1_num_product);

reg X1_start;
wire X1_busy, X1_done, X1_valid, X1_dbz, X1_ovf;
reg [15:0] X1_dividend, X1_divisor;
wire [15:0] X1_quotient;
div calc_X1 (clk, inv_rst, X1_start, X1_busy, X1_done, X1_valid, X1_dbz, X1_ovf, X1_dividend, X1_divisor, X1_quotient);

reg X0_first_start;
wire X0_first_busy, X0_first_done, X0_first_valid, X0_first_ovf;
reg [15:0] X0_first_multiplier, X0_first_multiplicand;
wire [15:0] X0_first_product;
mul calc_X0_first (clk, inv_rst, X0_first_start, X0_first_busy, X0_first_done, X0_first_valid, X0_first_ovf, X0_first_multiplier, X0_first_multiplicand, X0_first_product);

reg X0_num_start;
wire X0_num_busy, X0_num_done, X0_num_valid, X0_num_ovf;
reg [15:0] X0_num_multiplier, X0_num_multiplicand;
wire [15:0] X0_num_product;
mul calc_X0_num (clk, inv_rst, X0_num_start, X0_num_busy, X0_num_done, X0_num_valid, X0_num_ovf, X0_num_multiplier, X0_num_multiplicand, X0_num_product);

reg X0_start;
wire X0_busy, X0_done, X0_valid, X0_dbz, X0_ovf;
reg [15:0] X0_dividend, X0_divisor;
wire [15:0] X0_quotient;
div calc_X0 (clk, inv_rst, X0_start, X0_busy, X0_done, X0_valid, X0_dbz, X0_ovf, X0_dividend, X0_divisor, X0_quotient);




always@(*)
begin
	//Inputs for mul, div
	L10_dividend = A10;
	L10_divisor = A00;
	L20_dividend = A20;
	L20_divisor = A00;
	U11_multiplier = L10;
	U11_multiplicand = A01;
	L21_num_multiplier = L20;
	L21_num_multiplicand = A01;
	L21_dividend = A21 - L21_num_product;
	L21_divisor = U11;
	U12_multiplier = L10;
	U12_multiplicand = A02;
	U22_outer_multiplier = L21;
	U22_outer_multiplicand = U12;
	U22_multiplier = L20;
	U22_multiplicand = A02;
	Z1_multiplier = L10;
	Z1_multiplicand = C0;
	Z2_first_multiplier = L20;
	Z2_first_multiplicand = C0;
	Z2_multiplier = L21;
	Z2_multiplicand = Z1;
	X2_dividend = Z2;
	X2_divisor = U22;
	X1_num_multiplier = U12;
	X1_num_multiplicand = X2;
	X1_dividend = Z1 - X1_num_product;
	X1_divisor = U11;
	X0_first_multiplier = A01;
	X0_first_multiplicand = X1;
	X0_num_multiplier = A02;
	X0_num_multiplicand = X2;
	X0_dividend = C0 - X0_first_product - X0_num_product;
	X0_divisor = A00;
	
	//Outputs
	L10 = L10_quotient;
	L20 = L20_quotient;
	L21 = L21_quotient;
	U11 = A11 - U11_product;
	U12 = A12 - U12_product;
	U22 = A22 - U22_product - U22_outer_product;
	Z1 = C1 - Z1_product;
	Z2 = C2 - Z2_first_product - Z2_product;
	X0 = X0_quotient;
	X1 = X1_quotient;
	X2 = X2_quotient;
	
	error_ovf = L10_ovf | L20_ovf | U11_ovf | L21_num_ovf | L21_ovf | U12_ovf | U22_outer_ovf | U22_ovf | Z1_ovf | Z2_first_ovf | Z2_ovf | X2_ovf | X1_num_ovf | X1_ovf | X0_first_ovf | X0_num_ovf | X0_ovf;
	error_dbz = L10_dbz | L20_dbz | L21_dbz | X2_dbz | X1_dbz | X0_dbz;
end

reg [3:0] S;
reg [3:0] NS;

parameter START = 4'h0,
			 CALC_L10_L20 = 4'h1,
			 CALC_U11_L21_num_U12_U22_Z1_Z2_first = 4'h2,
			 CALC_L21_U22_outer_Z2 = 4'h3,
			 CALC_X2 = 4'h4,
			 CALC_X1_num_X0_num = 4'h5,
			 CALC_X1 = 4'h6,
			 CALC_X0_first = 4'h7,
			 CALC_X0 = 4'h8,
			 DONE = 4'h9,
			 ERROR = 4'hF;
			 
always@(posedge clk or negedge rst)
	if (rst == 1'b0)
		S = START;
	else 
		S = NS;
		
always@(*)
	case(S)
		START:
			begin
				if (en == 1'b1)
					NS = CALC_L10_L20;
				else
					NS = START;
			end
		CALC_L10_L20:
			begin
				if (L10_done & L20_done)
					NS = CALC_U11_L21_num_U12_U22_Z1_Z2_first;
				else
					NS = CALC_L10_L20;
			end
		CALC_U11_L21_num_U12_U22_Z1_Z2_first:
			begin
				if (U11_done & L21_num_done & U12_done & U22_done & Z1_done & Z2_first_done)
					NS = CALC_L21_U22_outer_Z2;
				else
					NS = CALC_U11_L21_num_U12_U22_Z1_Z2_first;
			end
		CALC_L21_U22_outer_Z2:
			begin
				if (L21_done & U22_outer_done & Z2_done)
					NS = CALC_X2;
				else
					NS = CALC_L21_U22_outer_Z2;
			end
		CALC_X2:
			begin
				if (X2_done)
					NS = CALC_X1_num_X0_num;
				else
					NS = CALC_X2;
			end
		CALC_X1_num_X0_num:
			begin
				if (X1_num_done & X0_num_done)
					NS = CALC_X1;
				else
					NS = CALC_X1_num_X0_num;
			end
		CALC_X1:
			begin
				if (X1_done)
					NS = CALC_X0_first;
				else
					NS = CALC_X1;
			end
		CALC_X0_first:
			begin
				if (X0_first_done)
					NS = CALC_X0;
				else
					NS = CALC_X0_first;
			end
		CALC_X0:
			begin
				if (X0_done)
					NS = DONE;
				else
					NS = CALC_X0;
			end
		DONE:
			begin
				if (en == 1'b1)
					NS = DONE;
				else
					NS = START;
			end
		default:
			begin
				NS = ERROR;
			end
	endcase
	
always@(posedge clk or negedge rst)
	if (rst == 1'b0)
		begin
			L10_start <= 1'b0;
			L20_start <= 1'b0;
			U11_start <= 1'b0;
			L21_num_start <= 1'b0;
			U12_start <= 1'b0;
			U22_start <= 1'b0;
			Z1_start <= 1'b0;
			Z2_first_start <= 1'b0;
			L21_start <= 1'b0;
			U22_outer_start <= 1'b0;
			Z2_start <= 1'b0;
			X2_start <= 1'b0;
			X1_num_start <= 1'b0;
			X0_num_start <= 1'b0;
			X1_start <= 1'b0;
			X0_first_start <= 1'b0;
			X0_start <= 1'b0;
			done <= 1'b0;
			error_fsm <= 1'b0;
			test <= 1'b0;
		end
	else
		case(S)
			START:
				begin
					L10_start <= 1'b0;
					L20_start <= 1'b0;
					U11_start <= 1'b0;
					L21_num_start <= 1'b0;
					U12_start <= 1'b0;
					U22_start <= 1'b0;
					Z1_start <= 1'b0;
					Z2_first_start <= 1'b0;
					L21_start <= 1'b0;
					U22_outer_start <= 1'b0;
					Z2_start <= 1'b0;
					X2_start <= 1'b0;
					X1_num_start <= 1'b0;
					X0_num_start <= 1'b0;
					X1_start <= 1'b0;
					X0_first_start <= 1'b0;
					X0_start <= 1'b0;
					done <= 1'b0;
					error_fsm <= 1'b0;
					test <= 1'b0;
				end
			CALC_L10_L20:
				begin
					L10_start <= 1'b1;
					L20_start <= 1'b1;
				end
			CALC_U11_L21_num_U12_U22_Z1_Z2_first:
				begin
					U11_start <= 1'b1;
					L21_num_start <= 1'b1;
					U12_start <= 1'b1;
					U22_start <= 1'b1;
					Z1_start <= 1'b1;
					Z2_first_start <= 1'b1;
				end
			CALC_L21_U22_outer_Z2:
				begin
					L21_start <= 1'b1;
					U22_outer_start <= 1'b1;
					Z2_start <= 1'b1;
				end
			CALC_X2:
				begin
					X2_start <= 1'b1;
				end
			CALC_X1_num_X0_num:
				begin
					X1_num_start <= 1'b1;
					X0_num_start <= 1'b1;
				end
			CALC_X1:
				begin
					X1_start <= 1'b1;
				end
			CALC_X0_first:
				begin
					X0_first_start <= 1'b1;
				end
			CALC_X0:
				begin
					X0_start <= 1'b1;
				end
			DONE:
				begin
					done <= 1'b1;
				end
			ERROR:
				begin
					error_fsm <= 1'b1;
					done <= 1'b1;
				end
			default:
				begin
					error_fsm <= 1'b1;
					done <= 1'b1;
				end
		endcase

endmodule 