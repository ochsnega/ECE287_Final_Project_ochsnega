module LU_Decomposition 
	(input clk, 
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
	output reg [15:0] U12, // U12 = A12 - L10_mult_A12 (6)
	output reg [15:0] U22, // U22 = (A22 - L10_mult_A02) - L21_mult_(A12 - L10_mult_A02) (7, 8, 9)
	output reg [15:0] Z1, // Z1 = C1 - L10_mult_C0 (10)
	output reg [15:0] Z2, // Z2 = C2 - L20_mult_C0 - L21_mult_Z1 (11, 12)
	output reg done,
	output reg error_ovf,
	output reg error_dbz,
	output reg error_fsm,
	output reg test
);

//Need: L10, L20, L21
//reg [15:0] L10; // L10 = A10_div_A00 (1)
//reg [15:0] L20; // L20 = A20_div_A00 (2)
//reg [15:0] L21; // L21 = (A_21 - L20_mult_A01)_div_U11 (4, 5)

//Need: u11, u12, u22
//reg [15:0] U11; // U11 = A11 - L10_mult_A01 (3)
//reg [15:0] U12; // U12 = A12 - L10_mult_A12 (6)
//reg [15:0] U22; // U22 = (A22 - L10_mult_A02) - L21_mult_(A12 - L10_mult_A02) (7, 8, 9)

//Need: z1, z2
//reg [15:0] Z1; // Z1 = C1 - L10_mult_C0 (10)
//reg [15:0] Z2; // Z2 = C2 - L20_mult_C0 - L21_mult_Z1 (11, 12)

//Instantiate mul and div
//Note: mul and div have inverted rst signals

/*
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
reg sv_rst;

always@(*)
	sv_rst = !rst;
	
reg mult_start;
wire mult_busy;
wire mult_done;
wire mult_valid;
wire mult_ovf;
reg [15:0] multiplier;
reg [15:0] multiplicand;
wire [15:0] product;

mul my_mul (clk, sv_rst, mult_start, mult_busy, mult_done, mult_valid, mult_ovf, multiplier, multiplicand, product);

/*
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

reg div_start;
wire div_busy;
wire div_done;
wire div_valid;
wire div_dbz;
wire div_ovf;
reg [15:0] dividend;
reg [15:0] divisor;
wire [15:0] quotient;

div my_div (clk, sv_rst, div_start, div_busy, div_done, div_valid, div_dbz, div_ovf, dividend, divisor, quotient);

//FSM:

reg [5:0] S;
reg [5:0] NS;

parameter START = 6'd0,
			 CALC_L10 = 6'd1,
			 STORE_L10 = 6'd2,
			 CALC_L20 = 6'd3,
			 STORE_L20 = 6'd4,
			 CALC_U11 = 6'd5,
			 STORE_U11 = 6'd6,
			 CALC_L21_NUM = 6'd7,
			 STORE_L21_NUM = 6'd8,
			 CALC_L21= 6'd9,
			 STORE_L21 = 6'd10,
			 CALC_U12 = 6'd11,
			 STORE_U12 = 6'd12,
			 CALC_U22_INNER = 6'd13,
			 STORE_U22_INNER = 6'd14,
			 CALC_U22_OUTER = 6'd15,
			 STORE_U22_OUTER = 6'd16,
			 CALC_U22 = 6'd17,
			 STORE_U22 = 6'd18,
			 CALC_Z1 = 6'd19,
			 STORE_Z1 = 6'd20,
			 CALC_Z2_FIRST = 6'd21,
			 STORE_Z2_FIRST = 6'd22,
			 CALC_Z2 = 6'd23,
			 STORE_Z2 = 6'd24,
			 CALC_X2 = 6'd25,
			 STORE_X2 = 6'd26,
			 CALC_X1_NUM = 6'd27,
			 STORE_X1_NUM = 6'd28,
			 CALC_X1 = 6'd29,
			 STORE_X1 = 6'd30,
			 CALC_X0_FIRST = 6'd31,
			 STORE_X0_FIRST = 6'd32,
			 CALC_X0_NUM = 6'd33,
			 STORE_X0_NUM = 6'd34,
			 CALC_X0 = 6'd35,
			 STORE_X0 = 6'd36,
			 DONE = 6'd37,
			 ERROR = 6'hFF;
			 
always@(posedge clk or negedge rst)
	if(rst == 1'b0)
		S <= START;
	else
		S <= NS;

// Switch cases logic.
		
always@(*)
	case(S)
		START:
			if (en == 1'b1)
				NS = CALC_L10;
			else
				NS = START;
		CALC_L10:
			if (div_done == 1'b1)
				NS = STORE_L10;
			else
				NS = CALC_L10;
		STORE_L10: NS = CALC_L20;
		CALC_L20:
			if (div_done == 1'b1)
				NS = STORE_L20;
			else
				NS = CALC_L20;
		STORE_L20: NS = CALC_U11;
		CALC_U11:
			if(mult_done == 1'b1)
				NS = STORE_U11;
			else
				NS = CALC_U11;
		STORE_U11: NS = CALC_L21_NUM;
		CALC_L21_NUM:
			if (mult_done == 1'b1)
				NS = STORE_L21_NUM;
			else
				NS = CALC_L21_NUM;
		STORE_L21_NUM: NS = CALC_L21;
		CALC_L21:
			if (div_done == 1'b1)
				NS = STORE_L21;
			else
				NS = CALC_L21;
		STORE_L21: NS = CALC_U12;
		CALC_U12:
			if (mult_done == 1'b1)
				NS = STORE_U12;
			else
				NS = CALC_U12;
		STORE_U12: NS = CALC_U22_INNER;
		CALC_U22_INNER:
			if (mult_done == 1'b1)
				NS = STORE_U22_INNER;
			else
				NS = CALC_U22_INNER;
		STORE_U22_INNER: NS = CALC_U22_OUTER;
		CALC_U22_OUTER:
			if (mult_done == 1'b1)
				NS = STORE_U22_OUTER;
			else	
				NS = CALC_U22_OUTER;
		STORE_U22_OUTER: NS = CALC_U22;
		CALC_U22:
			if (mult_done == 1'b1)
				NS = STORE_U22;
			else
				NS = CALC_U22;
		STORE_U22: NS = CALC_Z1;
		CALC_Z1: 
			if (mult_done == 1'b1)
				NS = STORE_Z1;
			else
				NS = CALC_Z1;
		STORE_Z1: NS = CALC_Z2_FIRST;
		CALC_Z2_FIRST:
			if (mult_done == 1'b1)
				NS = STORE_Z2_FIRST;
			else
				NS = CALC_Z2_FIRST;
		STORE_Z2_FIRST: NS = CALC_Z2;
		CALC_Z2:
			if (mult_done == 1'b1)
				NS = STORE_Z2;
			else
				NS = CALC_Z2;
		STORE_Z2: NS = CALC_X2;
		CALC_X2:
			if (div_done == 1'b1)
				NS = STORE_X2;
			else
				NS = CALC_X2;
		STORE_X2: NS = CALC_X1_NUM;
		CALC_X1_NUM:
			if (mult_done == 1'b1)
				NS = STORE_X1_NUM;
			else
				NS = CALC_X1_NUM;
		STORE_X1_NUM: NS = CALC_X1;
		CALC_X1:
			if (div_done == 1'b1)
				NS = STORE_X1;
			else
				NS = CALC_X1;
		STORE_X1: NS = CALC_X0_FIRST;
		CALC_X0_FIRST:
			if (mult_done == 1'b1)
				NS = STORE_X0_FIRST;
			else
				NS = CALC_X0_FIRST;
		STORE_X0_FIRST: NS = CALC_X0_NUM;
		CALC_X0_NUM:
			if (mult_done == 1'b1)
				NS = STORE_X0_NUM;
			else
				NS = CALC_X0_NUM;
		STORE_X0_NUM: NS = CALC_X0;
		CALC_X0:
			if (div_done == 1'b1)
				NS = STORE_X0;
			else
				NS = CALC_X0;
		STORE_X0: NS = DONE;
		DONE: 
			if (en == 1'b0)
				NS = START;
			else
				NS = DONE;
		default: NS = ERROR;
				
	endcase

// What happens in each case.

always@(posedge clk or negedge rst)
	if (rst == 1'b0)
		begin
			L10 <= 16'b0;
			L20 <= 16'b0;
			L21 <= 16'b0;
			U11 <= 16'b0;
			U12 <= 16'b0;
			U22 <= 16'b0;
			Z1 <= 16'b0;
			Z2 <= 16'b0;
			X0 <= 16'b0;
			X1 <= 16'b0;
			X2 <= 16'b0;
			done <= 1'b0;
			error_ovf <= 1'b0;
			error_dbz <= 1'b0;
			error_fsm <= 1'b0;
			mult_start <= 1'b0;
			multiplier <= 16'b0;
			multiplicand <= 16'b0;
			div_start <= 1'b0;
			dividend <= 16'b0;
			divisor <= 16'b0;
			test <= 1'b0;
		end
	else
		case(S)
			START:
			begin
				L10 <= 16'b0;
				L20 <= 16'b0;
				L21 <= 16'b0;
				U11 <= 16'b0;
				U12 <= 16'b0;
				U22 <= 16'b0;
				Z1 <= 16'b0;
				Z2 <= 16'b0;
				X0 <= 16'b0;
				X1 <= 16'b0;
				X2 <= 16'b0;
				done <= 1'b0;
				error_ovf <= 1'b0;
				error_dbz <= 1'b0;
				mult_start <= 1'b0;
				multiplier <= 16'b0;
				multiplicand <= 16'b0;
				div_start <= 1'b0;
				dividend <= A10;
				divisor <= A00;
				test <= 1'b0;
			end
			CALC_L10:
			begin
				div_start <= 1'b1;
				//test <= 1'b1;
			end
			STORE_L10:
			begin
				div_start <= 1'b0;
				//L10 <= quotient;
				if (div_ovf == 1'b1)
					error_ovf <= 1'b1;
				if (div_dbz == 1'b1)
					error_dbz <= 1'b1;
				dividend <= A20;
				divisor <= A00;
				test <= 1'b0;
			end
			CALC_L20:
			begin
				div_start <= 1'b1;
				//test <= 1'b1;
			end
			STORE_L20:
			begin
				div_start <= 1'b0;
				L20 <= quotient;
				if (div_ovf == 1'b1)
					error_ovf <= 1'b1;
				if (div_dbz == 1'b1)
					error_dbz <= 1'b1;
				multiplier <= L10;
				multiplicand <= A01;
			end
			CALC_U11:
			begin
				mult_start <= 1'b1;
				test <= 1'b1;
			end
			STORE_U11:
			begin
				mult_start <= 1'b0;
				U11 <= A11 - product;
				if (mult_ovf == 1'b1)
					error_ovf <= 1'b1;
				multiplier <= L20;
				multiplicand <= A01;
			end
			CALC_L21_NUM:
			begin
				mult_start <= 1'b1;
			end
			STORE_L21_NUM:
			begin
				mult_start <= 1'b0;
				if (mult_ovf == 1'b1)
					error_ovf <= 1'b1;
				dividend <= A21 - product;
				divisor <= U11;
			end
			CALC_L21:
			begin
				div_start <= 1'b1;
			end
			STORE_L21:
			begin
				div_start <= 1'b0;
				L21 <= quotient;
				if (div_ovf == 1'b1)
					error_ovf <= 1'b1;
				if (div_dbz == 1'b1)
					error_ovf <= 1'b0;
				multiplier <= L10;
				multiplicand <= A12;
			end
			CALC_U12:
			begin
				mult_start <= 1'b1;
			end
			STORE_U12:
			begin
				mult_start <= 1'b0;
				U12 <= A12 - product;
				if (mult_ovf == 1'b1)
					error_ovf <= 1'b1;
				multiplier <= L10;
				multiplicand <= A02;
			end
			CALC_U22_INNER:
			begin
				mult_start <= 1'b1;
			end
			STORE_U22_INNER:
			begin
				mult_start <= 1'b0;
				if (mult_ovf == 1'b1)
					error_ovf <= 1'b1;
				multiplier <= L21;
				multiplicand <= A12 - product;
			end
			CALC_U22_OUTER:
			begin
				mult_start <= 1'b1;
			end
			STORE_U22_OUTER:
			begin
				mult_start <= 1'b0;
				U22 <= product;
				if (mult_ovf == 1'b1)
					error_ovf <= 1'b1;
				multiplier <= L10;
				multiplicand <= A02;
			end
			CALC_U22:
			begin
				mult_start <= 1'b1;
			end
			STORE_U22:
			begin
				mult_start <= 1'b1;
				U22 <= (A22 - product) - U22;
				if (mult_ovf == 1'b1)
					error_ovf <= 1'b1;
				multiplier <= L10;
				multiplicand <= C0;
			end
			CALC_Z1:
			begin
				mult_start <= 1'b1;
			end
			STORE_Z1:
			begin
				mult_start <= 1'b0;
				Z1 <= C1 - product;
				if (mult_ovf == 1'b1)
					error_ovf <= 1'b1;
				multiplier <= L20;
				multiplicand <= C0;
			end
			CALC_Z2_FIRST:
			begin
				mult_start <= 1'b1;
			end
			STORE_Z2_FIRST:
			begin
				mult_start <= 1'b0;
				Z2 <= C2 - product;
				if (mult_ovf == 1'b1)
					error_ovf <= 1'b1;
				multiplier <= L21;
				multiplicand <= Z1;
			end
			CALC_Z2:
			begin
				mult_start <= 1'b1;
			end
			STORE_Z2:
			begin
				mult_start <= 1'b0;
				Z2 <= Z2 - product;
				if (mult_ovf == 1'b1)
					error_ovf <= 1'b1;
				dividend <= Z2;
				divisor <= U22;
			end
			CALC_X2:
			begin
				div_start <= 1'b1;
			end
			STORE_X2:
			begin
				div_start <= 1'b0;
				X2 <= quotient;
				if (div_ovf == 1'b1)
					error_ovf <= 1'b1;
				if (div_dbz == 1'b1)
					error_dbz <= 1'b1;
				multiplier <= U12;
				multiplicand <= X2;
			end
			CALC_X1_NUM:
			begin
				mult_start <= 1'b1;
			end
			STORE_X1_NUM:
			begin
				mult_start <= 1'b0;
				if (mult_ovf == 1'b1)
					error_ovf <= 1'b1;
				dividend <= Z1 - product;
				divisor <= U11;
			end
			CALC_X1:
			begin
				div_start <= 1'b1;
			end
			STORE_X1:
			begin
				div_start <= 1'b0;
				X1 <= quotient;
				if (div_ovf == 1'b1)
					error_ovf <= 1'b1;
				if (div_dbz == 1'b1)
					error_dbz <= 1'b1;
				multiplier <= A01;
				multiplicand <= X1;
			end
			CALC_X0_FIRST:
			begin
				mult_start <= 1'b1;
			end
			STORE_X0_FIRST:
			begin
				mult_start <= 1'b0;
				X0 <= C0 - product;
				if (mult_ovf == 1'b1)
					error_ovf <= 1'b1;
				multiplier <= A02;
				multiplicand <= X2;
			end
			CALC_X0_NUM:
			begin
				mult_start <= 1'b1;
			end
			STORE_X0_NUM:
			begin
				mult_start <= 1'b0;
				if (mult_ovf == 1'b1)
					error_ovf <= 1'b1;
				dividend <= X0 - product;
				divisor <= A00;
			end
			CALC_X0:
			begin
				div_start <= 1'b1;
			end
			STORE_X0:
			begin
				div_start <= 1'b0;
				X0 <= quotient;
				if (div_ovf == 1'b1)
					error_ovf <= 1'b1;
				if (div_dbz == 1'b1)
					error_dbz <= 1'b1;
			end
			DONE:
			begin
				done <= 1'b1;
			end		
			default: 
			begin
				error_fsm <= 1'b1;
				done <= 1'b1;
			end
		endcase
		
endmodule 



























