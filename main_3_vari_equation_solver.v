module main_3_vari_equation_solver (
	input clk, 
	input rst, 
	input PS2_CLK,
	input PS2_DATA,
	input main_en,
	input [4:0] disp_control, // 00 X0, 01 X1, 10 X2, 11 FFFF
	output reg done,
	output reg keyboard_overflow, 
	output reg keyboard_at_start,
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

//Get Keyboard Input

wire keyboard_err;
wire [7:0] keyboard_result;

keyboard get_keyboard (clk, PS2_CLK, PS2_DATA, keyboard_err, keyboard_result); //This is always running because it has no enable capability. This should be fine.

parameter NUM_PAD_0 = 8'h70,
			 NUM_PAD_1 = 8'h69,
			 NUM_PAD_2 = 8'h72,
			 NUM_PAD_3 = 8'h7A,
			 NUM_PAD_4 = 8'h6B,
			 NUM_PAD_5 = 8'h73,
			 NUM_PAD_6 = 8'h74,
			 NUM_PAD_7 = 8'h6C,
			 NUM_PAD_8 = 8'h75,
			 NUM_PAD_9 = 8'h7D,
			 NUM_PAD_MINUS = 8'h7B,
			 NUM_PAD_ENTER = 8'h5A,
			 NUM_PAD_PLUS = 8'h79;

reg [3:0] keyboard_num;
reg keyboard_minus;
reg keyboard_invalid;
reg keyboard_enter;
reg keyboard_proceed; //Control signal for CALC states in K2N
reg keyboard_continue; //Control signal for WAIT states in K2N

always@(posedge clk or negedge rst) //Interprets the results of a keyboard press. Will signal invalid until a valid input is given.
	if (rst == 1'b0)
	begin
		keyboard_num <= 4'b0;
		keyboard_minus <= 1'b0;
		keyboard_invalid <= 1'b0;
		keyboard_enter <= 1'b0;
		keyboard_proceed <= 1'b0;
		keyboard_continue <= 1'b0;
	end
	else
		case (keyboard_result)
			NUM_PAD_0: 
			begin
				keyboard_num <= 4'd0;
				keyboard_minus <= 1'b0;
				keyboard_invalid <= 1'b0;
				keyboard_enter <= 1'b0;
				keyboard_proceed <= 1'b0;
				keyboard_continue <= 1'b1;
			end 
			NUM_PAD_1:
			begin
				keyboard_num <= 4'd1;
				keyboard_minus <= 1'b0;
				keyboard_invalid <= 1'b0;
				keyboard_enter <= 1'b0;
				keyboard_proceed <= 1'b0;
				keyboard_continue <= 1'b1;
			end 
			NUM_PAD_2:
			begin
				keyboard_num <= 4'd2;
				keyboard_minus <= 1'b0;
				keyboard_invalid <= 1'b0;
				keyboard_enter <= 1'b0;
				keyboard_proceed <= 1'b0;
				keyboard_continue <= 1'b1;
			end 
			NUM_PAD_3:
			begin
				keyboard_num <= 4'd3;
				keyboard_minus <= 1'b0;
				keyboard_invalid <= 1'b0;
				keyboard_enter <= 1'b0;
				keyboard_proceed <= 1'b0;
				keyboard_continue <= 1'b1;
			end 
			NUM_PAD_4:
			begin
				keyboard_num <= 4'd4;
				keyboard_minus <= 1'b0;
				keyboard_invalid <= 1'b0;
				keyboard_enter <= 1'b0;
				keyboard_proceed <= 1'b0;
				keyboard_continue <= 1'b1;
			end 
			NUM_PAD_5:
			begin
				keyboard_num <= 4'd5;
				keyboard_minus <= 1'b0;
				keyboard_invalid <= 1'b0;
				keyboard_enter <= 1'b0;
				keyboard_proceed <= 1'b0;
				keyboard_continue <= 1'b1;
			end 
			NUM_PAD_6:
			begin
				keyboard_num <= 4'd6;
				keyboard_minus <= 1'b0;
				keyboard_invalid <= 1'b0;
				keyboard_enter <= 1'b0;
				keyboard_proceed <= 1'b0;
				keyboard_continue <= 1'b1;
			end 
			NUM_PAD_7:
			begin
				keyboard_num <= 4'd7;
				keyboard_minus <= 1'b0;
				keyboard_invalid <= 1'b0;
				keyboard_enter <= 1'b0;
				keyboard_proceed <= 1'b0;
				keyboard_continue <= 1'b1;
			end 
			NUM_PAD_8:
			begin
				keyboard_num <= 4'd8;
				keyboard_minus <= 1'b0;
				keyboard_invalid <= 1'b0;
				keyboard_enter <= 1'b0;
				keyboard_proceed <= 1'b0;
				keyboard_continue <= 1'b1;
			end 
			NUM_PAD_9:
			begin
				keyboard_num <= 4'd9;
				keyboard_minus <= 1'b0;
				keyboard_invalid <= 1'b0;
				keyboard_enter <= 1'b0;
				keyboard_proceed <= 1'b0;
				keyboard_continue <= 1'b1;
			end 
			NUM_PAD_MINUS:
			begin
				keyboard_num <= 4'd0;
				keyboard_minus <= 1'b1;
				keyboard_invalid <= 1'b0;
				keyboard_enter <= 1'b0;
				keyboard_proceed <= 1'b0;
				keyboard_continue <= 1'b0;
			end 
			NUM_PAD_ENTER:
			begin
				keyboard_num <= 4'd0;
				keyboard_minus <= 1'b0;
				keyboard_invalid <= 1'b0;
				keyboard_enter <= 1'b1;
				keyboard_proceed <= 1'b0;
				keyboard_continue <= 1'b0;
			end 
			NUM_PAD_PLUS:
			begin
				keyboard_num <= 4'd0;
				keyboard_minus <= 1'b0;
				keyboard_invalid <= 1'b0;
				keyboard_enter <= 1'b1;
				keyboard_proceed <= 1'b1;
				keyboard_continue <= 1'b0;
			end 
			8'h0: 
			begin
				keyboard_num <= 4'd0;
				keyboard_minus <= 1'b0;
				keyboard_invalid <= 1'b0;
				keyboard_enter <= 1'b0;
				keyboard_proceed <= 1'b0;
				keyboard_continue <= 1'b0;
			end 
			default:
			begin
				keyboard_num <= 4'd0;
				keyboard_minus <= 1'b0;
				keyboard_invalid <= 1'b1;
				keyboard_enter <= 1'b0;
				keyboard_proceed <= 1'b0;
				keyboard_continue <= 1'b0;
			end 
		endcase
//Intentionally useless comment.

//FSM For Keyboard to 16 Bit Number

reg [15:0] k2n_number;
reg [15:0] k2n_abs;
reg [3:0] k2n_digit;
reg k2n_is_negative;
reg k2n_done;

reg [5:0] S_K2N;
reg [5:0] NS_K2N;

parameter START_K2N = 6'd0,
			 WAIT_THOUSAND = 6'd1,
			 CALC_THOUSAND = 6'd2,
			 MINUS_THOUSAND = 6'd3,
			 WAIT_HUNDRED = 6'd4,
			 CALC_HUNDRED = 6'd5,
			 MINUS_HUNDRED = 6'd6,
			 WAIT_TEN = 6'd7,
			 CALC_TEN = 6'd8,
			 MINUS_TEN = 6'd9,
			 WAIT_ONE = 6'd10,
			 CALC_ONE = 6'd11,
			 MINUS_ONE = 6'd12,
			 DONE_K2N = 6'd27,
			 ERROR_K2N = 6'b111111;
			 
always@(posedge clk or negedge rst)
	if (rst == 1'b0)
		S_K2N <= START_K2N;
	else
		S_K2N <= NS_K2N;
		
//FSM State Transitions
//This is a large case/if structure, but the busses are small, so there should be no problems.
		
always@(*)
	case (S_K2N)
		START_K2N:
		begin
			if (k2n_en == 1'b1)
				NS_K2N = WAIT_THOUSAND;
			else
				NS_K2N = START_K2N;
		end
		WAIT_THOUSAND:
		begin
			if (keyboard_invalid)
				NS_K2N = START_K2N;
			else if (keyboard_enter)
				NS_K2N = DONE_K2N;
			else if (keyboard_minus)
				NS_K2N = MINUS_THOUSAND;
			else if (keyboard_continue)
				NS_K2N = CALC_THOUSAND;
			else
				NS_K2N = WAIT_THOUSAND;
		end
		CALC_THOUSAND:
		begin
			if (keyboard_invalid)
				NS_K2N = START_K2N;
			else if (keyboard_enter)
				NS_K2N = DONE_K2N;
			else if (keyboard_proceed)
				NS_K2N = WAIT_HUNDRED;
			else
				NS_K2N = CALC_THOUSAND;
		end
		MINUS_THOUSAND: NS_K2N = WAIT_THOUSAND;
		WAIT_HUNDRED:
		begin
			if (keyboard_invalid)
				NS_K2N = START_K2N;
			else if (keyboard_enter)
				NS_K2N = DONE_K2N;
			else if (keyboard_minus)
				NS_K2N = MINUS_HUNDRED;
			else if (keyboard_continue)
				NS_K2N = CALC_HUNDRED;
			else
				NS_K2N = WAIT_HUNDRED;
		end
		CALC_HUNDRED:
		begin
			if (keyboard_invalid)
				NS_K2N = START_K2N;
			else if (keyboard_enter)
				NS_K2N = DONE_K2N;
			else if (keyboard_proceed)
				NS_K2N = WAIT_TEN;
			else
				NS_K2N = CALC_HUNDRED;
		end
		MINUS_HUNDRED: NS_K2N = WAIT_HUNDRED;
		WAIT_TEN:
		begin
			if (keyboard_invalid)
				NS_K2N = START_K2N;
			else if (keyboard_enter)
				NS_K2N = DONE_K2N;
			else if (keyboard_minus)
				NS_K2N = MINUS_TEN;
			else if (keyboard_continue)
				NS_K2N = CALC_TEN;
			else
				NS_K2N = WAIT_TEN;
		end
		CALC_TEN:
		begin
			if (keyboard_invalid)
				NS_K2N = START_K2N;
			else if (keyboard_enter)
				NS_K2N = DONE_K2N;
			else if (keyboard_proceed)
				NS_K2N = WAIT_ONE;
			else
				NS_K2N = CALC_TEN;
		end
		MINUS_TEN: NS_K2N = WAIT_TEN;
		WAIT_ONE:
		begin
			if (keyboard_invalid)
				NS_K2N = START_K2N;
			else if (keyboard_enter)
				NS_K2N = DONE_K2N;
			else if (keyboard_minus)
				NS_K2N = MINUS_ONE;
			else if (keyboard_continue)
				NS_K2N = CALC_ONE;
			else
				NS_K2N = WAIT_ONE;
		end
		CALC_ONE:
		begin
			if (keyboard_invalid)
				NS_K2N = START_K2N;
			else if (keyboard_overflow)
				NS_K2N = START_K2N;
			else if (keyboard_enter)
				NS_K2N = DONE_K2N;
			else if (keyboard_proceed)
				NS_K2N = DONE_K2N;
			else
				NS_K2N = CALC_ONE;
		end
		MINUS_ONE: NS_K2N = WAIT_ONE;
		DONE_K2N:
		begin
			if (k2n_en == 1'b0)
				NS_K2N = START_K2N;
			else
				NS_K2N = DONE_K2N;
		end
		default: NS_K2N = ERROR_K2N;
	endcase

//FSM What changes in each state?
	
always@(posedge clk or negedge rst)
	if (rst == 1'b0)
	begin
		k2n_number <= 16'b0;
		k2n_abs <= 16'b0;
		k2n_digit <= 4'b0;
		k2n_is_negative <= 1'b0;
		k2n_done <= 1'b0;
		keyboard_overflow <= 1'b0;
		keyboard_at_start <= 1'b0;
	end
	else
		case (S_K2N)
			START_K2N:
			begin
				k2n_number <= 16'b0;
				k2n_abs <= 20'b0;
				k2n_digit <= 4'b0;
				k2n_is_negative <= 1'b0;
				k2n_done <= 1'b0;
				keyboard_overflow <= 1'b0;
				keyboard_at_start <= 1'b1;
			end
			WAIT_THOUSAND:
			begin
				keyboard_at_start <= 1'b0;
				k2n_digit <= keyboard_num;
			end
			CALC_THOUSAND:
			begin
				k2n_abs[7:4] <= k2n_digit;
				if (k2n_is_negative)
				begin
					k2n_number <= 17'h10000 - k2n_abs[15:0];
				end
				else
				begin
					k2n_number <= k2n_abs[15:0];
				end
			end
			MINUS_THOUSAND:
			begin
				k2n_is_negative <= !k2n_is_negative;
			end
			WAIT_HUNDRED:
			begin
				k2n_digit <= keyboard_num;
			end
			CALC_HUNDRED:
			begin
				k2n_abs <= (k2n_abs * 10) + k2n_digit;
				if (k2n_is_negative)
				begin
					k2n_number <= 17'h10000 - k2n_abs[15:0];
				end
				else
				begin
					k2n_number <= k2n_abs[15:0];
				end
			end
			MINUS_HUNDRED:
			begin
				k2n_is_negative <= !k2n_is_negative;
			end
			WAIT_TEN:
			begin
				k2n_digit <= keyboard_num;
			end
			CALC_TEN:
			begin
				k2n_abs <= (k2n_abs * 10) + k2n_digit;
				if (k2n_is_negative)
				begin
					k2n_number <= 17'h10000 - k2n_abs[15:0];
				end
				else
				begin
					k2n_number <= k2n_abs[15:0];
				end
			end
			MINUS_TEN:
			begin
				k2n_is_negative <= !k2n_is_negative;
			end
			WAIT_ONE:
			begin
				k2n_digit <= keyboard_num;
			end
			CALC_ONE:
			begin
				k2n_abs <= (k2n_abs * 10) + k2n_digit;
				if (k2n_is_negative)
				begin
					k2n_number <= 17'h10000 - k2n_abs[15:0];
				end
				else
				begin
					k2n_number <= k2n_abs[15:0];
				end
				if (13'h1000 < k2n_abs)
					keyboard_overflow <= 1'b1;
			end
			MINUS_ONE:
			begin
				k2n_is_negative <= !k2n_is_negative;
			end
			DONE_K2N:
			begin
				k2n_done <= 1'b1;
			end
		endcase
		
//LU Decomposition

wire LU_done;
reg LU_en;

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

/*
always@(*)
begin
	A00 = 16'h10; //1 | 1  1 1 |       |  2 |
	A01 = 16'h10; //1 | 6 -4 5 | = A ; | 31 | = C
	A02 = 16'h10; //1 | 5  2 2 |       | 13 |  
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
*/

LU_Decomposition_parallel my_solver (clk, rst, LU_en, A00, A01, A02, A10, A11, A12, A20, A21, A22, C0, C1, C2, X0, X1, X2, L10, L20, L21, U11, U12, U22, Z1, Z2, LU_done, LU_error_ovf, LU_error_dbz, LU_error_FSM, test);

// Display

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

twelve_four_fixed_decimal_w_neg to_decimal(Xin, seg7_neg_sign, seg7_thousand, seg7_hundred, seg7_ten, seg7_one, seg7_tenth, seg7_centi, seg7_milli, seg7_tenth_milli);

//FSM for Control

reg k2n_en;

reg [4:0] S;
reg [4:0] NS;

parameter START_MAIN = 5'd0,
			 GET_A00 = 5'd1,
			 STORE_A00 = 5'd15,
			 GET_A01 = 5'd2,
			 STORE_A01 = 5'd16,
			 GET_A02 = 5'd3,
			 STORE_A02 = 5'd17,
			 GET_A10 = 5'd4,
			 STORE_A10 = 5'd18,
			 GET_A11 = 5'd5,
			 STORE_A11 = 5'd19,
			 GET_A12 = 5'd6,
			 STORE_A12 = 5'd20,
			 GET_A20 = 5'd7,
			 STORE_A20 = 5'd21,
			 GET_A21 = 5'd8,
			 STORE_A21 = 5'd22,
			 GET_A22 = 5'd9,
			 STORE_A22 = 5'd23,
			 GET_C0 = 5'd10,
			 STORE_C0 = 5'd24,
			 GET_C1 = 5'd11,
			 STORE_C1 = 5'd25,
			 GET_C2 = 5'd12,
			 STORE_C2 = 5'd26,
			 CALCULATE = 5'd13,
			 DONE_MAIN = 5'd14,
			 ERROR_MAIN = 5'b11111;
			 
always@(posedge clk or negedge rst)
	if (rst == 1'b0)
		S <= START_MAIN;
	else
		S <= NS;
		
//FSM State Transitions
always@(*)
	case(S)
		START_MAIN:
			if (main_en == 1'b1)
				NS = GET_A00;
			else
				NS = START_MAIN;
		GET_A00:
			if (k2n_done)
				NS = STORE_A00;
			else
				NS = GET_A00;
		STORE_A00: NS = GET_A01;
		GET_A01:
			if (k2n_done)
				NS = STORE_A01;
			else
				NS = GET_A01;
		STORE_A01: NS = GET_A02;
		GET_A02:
			if (k2n_done)
				NS = STORE_A02;
			else
				NS = GET_A02;
		STORE_A02: NS = GET_A10;
		GET_A10:
			if (k2n_done)
				NS = STORE_A10;
			else
				NS = GET_A10;
		STORE_A10: NS = GET_A11;
		GET_A11:
			if (k2n_done)
				NS = STORE_A11;
			else
				NS = GET_A11;
		STORE_A11: NS = GET_A12;
		GET_A12:
			if (k2n_done)
				NS = STORE_A12;
			else
				NS = GET_A12;
		STORE_A12: NS = GET_A20;
		GET_A20:
			if (k2n_done)
				NS = STORE_A20;
			else
				NS = GET_A20;
		STORE_A20: NS = GET_A21;
		GET_A21: 
			if (k2n_done)
				NS = STORE_A21;
			else
				NS = GET_A21;
		STORE_A21: NS = GET_A22;
		GET_A22:
			if (k2n_done)
				NS = STORE_A22;
			else
				NS = GET_A11;
		STORE_A22: NS = GET_C0;
		GET_C0:
			if (k2n_done)
				NS = STORE_C0;
			else
				NS = GET_C0;
		STORE_C0: NS = GET_C1;
		GET_C1: 
			if (k2n_done)
				NS = STORE_C1;
			else
				NS = GET_C1;
		STORE_C1: NS = GET_C2;
		GET_C2:
			if (k2n_done)
				NS = STORE_C2;
			else
				NS = GET_C2;
		STORE_C2: NS = CALCULATE;
		CALCULATE:
			if (LU_done)
				NS = DONE_MAIN;
			else
				NS = CALCULATE;
		DONE_MAIN:
			if (main_en == 1'b0)
				NS = START_MAIN;
			else
				NS = DONE_MAIN;
		default: NS = ERROR_MAIN;
	endcase


//FSM Output
always@(posedge clk or negedge rst)
		if (rst == 1'b0)
		begin
			k2n_en <= 1'b0;
			LU_en <= 1'b0;
			A00 <= 16'b0;
			A01 <= 16'b0;
			A02 <= 16'b0;
			A10 <= 16'b0;
			A11 <= 16'b0;
			A12 <= 16'b0;
			A20 <= 16'b0;
			A21 <= 16'b0;
			A22 <= 16'b0;
			C0 <= 16'b0;
			C1 <= 16'b0;
			C2 <= 16'b0;
			done <= 1'b0;
		end
		else
			case(S)
				START_MAIN: 
				begin
					k2n_en <= 1'b0;
					LU_en <= 1'b0;
					A00 <= 16'b0;
					A01 <= 16'b0;
					A02 <= 16'b0;
					A10 <= 16'b0;
					A11 <= 16'b0;
					A12 <= 16'b0;
					A20 <= 16'b0;
					A21 <= 16'b0;
					A22 <= 16'b0;
					C0 <= 16'b0;
					C1 <= 16'b0;
					C2 <= 16'b0;
					done <= 1'b0;
				end
				GET_A00:
				begin
					k2n_en <= 1'b1;
					A00 <= k2n_number;
				end
				STORE_A00:
				begin
					k2n_en <= 1'b0;
				end
				GET_A01:
				begin
					k2n_en <= 1'b1;
					A01 <= k2n_number;
				end
				STORE_A01:
				begin
					k2n_en <= 1'b0;
				end
				GET_A02:
				begin
					k2n_en <= 1'b1;
					A02 <= k2n_number;
				end
				STORE_A02:
				begin
					k2n_en <= 1'b0;
				end
				GET_A10:
				begin
					k2n_en <= 1'b1;
					A10 <= k2n_number;
				end
				STORE_A10:
				begin
					k2n_en <= 1'b0;
				end
				GET_A11:
				begin
					k2n_en <= 1'b1;
					A10 <= k2n_number;
				end
				STORE_A11:
				begin
					k2n_en <= 1'b0;
				end
				GET_A12:
				begin
					k2n_en <= 1'b1;
					A12 <= k2n_number;
				end
				STORE_A12:
				begin
					k2n_en <= 1'b0;
				end
				GET_A20:
				begin
					k2n_en <= 1'b1;
					A20 <= k2n_number;
				end
				STORE_A20:
				begin
					k2n_en <= 1'b0;
				end
				GET_A21:
				begin
					k2n_en <= 1'b1;
					A21 <= k2n_number;
				end
				STORE_A21:
				begin
					k2n_en <= 1'b0;
				end
				GET_A22:
				begin
					k2n_en <= 1'b1;
					A22 <= k2n_number;
				end
				STORE_A22:
				begin
					k2n_en <= 1'b0;
				end
				GET_C0:
				begin
					k2n_en <= 1'b1;
					C0 <= k2n_number;
				end
				STORE_C0:
				begin
					k2n_en <= 1'b0;
				end
				GET_C1:
				begin
					k2n_en <= 1'b1;
					C1 <= k2n_number;
				end
				STORE_C1:
				begin
					k2n_en <= 1'b0;
				end
				GET_C2:
				begin
					k2n_en <= 1'b1;
					C2 <= k2n_number;
				end
				STORE_C2:
				begin
					k2n_en <= 1'b0;
				end
				CALCULATE:
				begin
					LU_en <= 1'b1;
				end
				DONE_MAIN:
				begin
					done <= 1'b1;
				end
			endcase

endmodule 