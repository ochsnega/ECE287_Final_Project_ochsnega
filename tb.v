`timescale 1 ps / 1 ps

module tb;

	reg[7:0] step_val;
	
	task decimalPoint();
	begin
		$write(".");
	end
	endtask
	
	task writeVal(input val);
	begin
		case (val)
			1'b0: $write("0");
			1'b1: $write("1");
		endcase
	end
	endtask
	
	task sevenSeg(input [6:0] val);
	begin
		case (val)
			7'b0000001: $write("0");
			7'b1001111: $write("1");
			7'b0010010: $write("2");
			7'b0000110: $write("3");
			7'b1001100: $write("4");
			7'b0100100: $write("5");
			7'b0100000: $write("6");
			7'b0001111: $write("7");
			7'b0000000: $write("8");
			7'b0001100: $write("9");
			7'b0001000: $write("A");
			7'b1100000: $write("B");
			7'b0110001: $write("C");
			7'b1000011: $write("D");
			7'b0110000: $write("E");
			7'b0111000: $write("F");
			default: $write("seg:ERROR");
		endcase
	end
	endtask
	
	task sevenSegNeg(input [6:0] val);
	begin
		case (val)
			7'b1111110: $write("-");
			7'b1111111: $write("+");
			default: $display("neg:ERROR");
		endcase
	end
	endtask
	
	task step();
	begin
		step_val = step_val + 1;
	end
	endtask

	
	parameter simdelay = 20; // guaranteed 2 clocks
	parameter clock_delay = 5;
	parameter fullclk = 11;
		
/*
	module main_3_vari_equation_solver (
		input clk, 
		input rst, 
		input LU_en,
		input [1:0] disp_control, // 00 X0, 01 X1, 10 X2, 11 FFFF
		output LU_done, 
		output LU_error_ovf, 
		output LU_error_dbz, 
		output LU_error_FSM, 
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

	reg clk;
	reg rst;
	reg en;
	reg [3:0] disp_control;
	wire done;
	wire LU_error_ovf;
	wire LU_error_dbz;
	wire LU_error_FSM;
	wire test;
	wire [6:0] seg7_neg_sign;
	wire [6:0] seg7_thousand;
	wire [6:0] seg7_hundred;
	wire [6:0] seg7_ten;
	wire [6:0] seg7_one;
	wire [6:0] seg7_tenth;
	wire [6:0] seg7_centi;
	wire [6:0] seg7_milli;
	wire [6:0] seg7_tenth_milli;
		
	main_3_vari_equation_solver DUT(
			clk, 
			rst, 
			en,
			disp_control,
			done,
			LU_error_ovf,
			LU_error_dbz,
			LU_error_FSM,
			test,
			seg7_neg_sign,
			seg7_thousand,
			seg7_hundred,
			seg7_ten,
			seg7_one,
			seg7_tenth,
			seg7_centi,
			seg7_milli,
			seg7_tenth_milli
			);
	
	initial
	begin
		
		/* start clk and reset */
		#(simdelay) rst = 1'b0; clk = 1'b0; step_val = 8'd0;
		#(simdelay) rst = 1'b1; /* go into normal circuit operation */ 
		
		/* start */ #(simdelay) en = 1'b1; disp_control = 4'b0011;
		end
	
	/* this checks done every clock and when it goes high ends the simulation */
	always @(clk)
	begin
		if (done == 1'b1)
		begin
			$write("DONE: \n");
			sevenSegNeg(seg7_neg_sign); sevenSeg(seg7_thousand); sevenSeg(seg7_hundred); sevenSeg(seg7_ten); sevenSeg(seg7_one); decimalPoint(); sevenSeg(seg7_tenth); sevenSeg(seg7_centi); sevenSeg(seg7_milli); sevenSeg(seg7_tenth_milli);
			$write("\n");
			writeVal(LU_error_ovf);
			$write("\n");
			writeVal(LU_error_dbz);
			$write("\n");
			writeVal(LU_error_FSM);
			$write("\n");
			writeVal(test);
			$stop;
		end
		else
		begin
			step();
		end
	end
	
		// this generates a clock
	always
	begin
		#(clock_delay) clk = !clk; 
	end
	
	//initial
	//	#(1000) $stop; // This stops the simulation ... May need to be greater or less depending on your program
	
endmodule