module main_3_vari_equation_solver (
	input clk, 
	input rst, 
	input LU_en,
	input [4:0] disp_control, // 00 X0, 01 X1, 10 X2, 11 FFFF
	output LU_done, 
	output LU_error_ovf, 
	output LU_error_dbz, 
	output LU_error_FSM, 
	output test,
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

//Keyboard Input

//Display

//LU Decomposition

// wire LU_done;
// reg LU_en;

reg [15:0] A00; //Inputs for LU Decomposition
reg [15:0] A01; // | A00 A01 A02 | C0 |
reg [15:0] A02; // | A10 A11 A12 | C1 |
reg [15:0] A10; // | A20 A21 A22 | C2 |
reg [15:0] A11;
reg [15:0] A12;
reg [15:0] A20;
reg [15:0] A21;
reg [15:0] A22;
reg [15:0] C0;
reg [15:0] C1;
reg [15:0] C2;

wire [15:0] X0;
wire [15:0] X1;
wire [15:0] X2;
wire [15:0] L10;
wire [15:0] L20;
wire [15:0] L21;
wire [15:0] U11;
wire [15:0] U12;
wire [15:0] U22;
wire [15:0] Z1;
wire [15:0] Z2;

reg [15:0] Xin;

always@(*)
begin
	A00 = 16'h10; //1
	A01 = 16'h10; //1
	A02 = 16'h10; //1
	A10 = 16'h60; //6
	A11 = 16'hFFC0; //-4
	A12 = 16'h50; //5
	A20 = 16'h50; //5
	A21 = 16'h20; //2
	A22 = 16'h20; //2
	C0 = 16'h20; //2 //Expected results: (3, -2, 1)
	C1 = 16'h1F0; //31
	C2 = 16'hD0; //13
end

LU_Decomposition_parallel my_solver (clk, rst, LU_en, A00, A01, A02, A10, A11, A12, A20, A21, A22, C0, C1, C2, X0, X1, X2, L10, L20, L21, U11, U12, U22, Z1, Z2, LU_done, LU_error_ovf, LU_error_dbz, LU_error_FSM, test);

always@(*)
begin
	case (disp_control)
		5'b00000: Xin = X0;
		5'b00001: Xin = X1;
		5'b00010: Xin = X2;
		5'b00011: Xin = L10;
		5'b00100: Xin = L20;
		5'b00101: Xin = L21;
		5'b00110: Xin = U11;
		5'b00111: Xin = U12;
		5'b01000: Xin = U22;
		5'b01001: Xin = Z1;
		5'b01010: Xin = Z2;
		5'b01011: Xin = A00;
		5'b01100: Xin = A01;
		5'b01101: Xin = A02;
		5'b01110: Xin = A10;
		5'b01111: Xin = A11;
		5'b10000: Xin = A12;
		5'b10001: Xin = A20;
		5'b10010: Xin = A21;
		5'b10011: Xin = A22;
		5'b10100: Xin = C0;
		5'b10101: Xin = C1;
		5'b11000: Xin = C2;
		default: Xin = 16'h0FF0;
	endcase
end

/*
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
*/

twelve_four_fixed_decimal_w_neg to_decimal(Xin, seg7_neg_sign, seg7_thousand, seg7_hundred, seg7_ten, seg7_one, seg7_tenth, seg7_centi, seg7_milli, seg7_tenth_milli);

//FSM for Control

endmodule 