
//	This module has a bank of sounds, one is selected using soundIndex


module sound_gen (input logic [3:0] soundIndex,				// zero represents no sound
						input logic [15:0] t,
						//input logic Reset,
						input logic keypress,				// used by envelope_gen
						input logic I2S_LRCLK,
						input logic[6:0] note,
						output shortint outputWave,
						input logic[9:0] SW,
						input logic clk,
						input logic[7:0] keycode,
						output logic[31:0] paramvalue, 
						output logic[3:0] Param);

	//byte alg, env0, env1, env2;
	logic [6:0] op0note, op1note, op2note; //Frequency of each operator in midi note
	logic [6:0] op0offset, op1offset, op2offset;		//7 bit signed
	logic [5:0] alg;
	logic [3:0] env0, env1, env2;
	logic [11:0] beta0, beta1, beta2;
	logic [7:0] ft0, ft1, ft2;				//Fine tune for each operator. 8 bit signed
	logic [15:0] wt0, wt1, wt2;
	logic pressUp, pressDown, pressLeft, pressRight;
	
	//Note 0 modified to be 0hz as opposed to 8 hz.
shortint NoteToCount[127:0] = 
	'{0 ,13 ,14 ,14 ,15 ,16 ,17 ,18 ,19 ,20 ,22 ,23 ,24 ,26 ,27 ,29 ,31 ,32 ,34 ,36 ,39 ,41 ,43 ,46 ,49 ,51 ,55 ,58 ,61 ,65 ,69 ,73 ,77 ,82 ,87 ,92 ,97 ,103 ,109 ,116 ,122 ,130 ,137 ,146 ,154 ,163 ,173 ,183 ,194 ,206 ,218 ,231 ,245 ,259 ,275 ,291 ,309 ,327 ,346 ,367 ,389 ,412 ,436 ,462 ,490 ,519 ,550 ,583 ,617 ,654 ,693 ,734 ,778 ,824 ,873 ,925 ,980 ,1038 ,1100 ,1165 ,1234 ,1308 ,1386 ,1468 ,1555 ,1648 ,1746 ,1849 ,1959 ,2076 ,2199 ,2330 ,2469 ,2615 ,2771 ,2936 ,3110 ,3295 ,3491 ,3699 ,3919 ,4152 ,4399 ,4660 ,4937 ,5231 ,5542 ,5872 ,6221 ,6591 ,6983 ,7398 ,7838 ,8304 ,8797 ,9321 ,9875 ,10462 ,11084 ,11743 ,12441 ,13181 ,13965 ,14795 ,15675 ,16607 ,17595 ,18641};


	//Increment wt
	//Each operator in a voice can potentially have a different frequency
	always_ff @ (negedge I2S_LRCLK)
	begin
		wt0 <= wt0 + NoteToCount[~op0note] + {{8{ft0[7]}}, ft0};
		wt1 <= wt1 + NoteToCount[~op1note] + {{8{ft1[7]}}, ft1};
		wt2 <= wt2 + NoteToCount[~op2note] + {{8{ft2[7]}}, ft2};
	end
	
	algorithm	alg0	(.alg(alg), .t(t), /*.Reset(Reset),*/ .keypress(keypress),
							.wt0(wt0), .wt1(wt1), .wt2(wt2),
							.env0(env0),	.env1(env1),	.env2(env2),
							.beta0(beta0),	.beta1(beta1),	.beta2(beta2),
							.outputWave(outputWave));
							
	always_ff @ (posedge clk)
	begin
		case(soundIndex)	// This case statement represents a set of sounds which can be assigned to keypresses
			0:					// no sound
				begin
				alg <= 25;
				op0note <= 0;
				op1note <= 0;
				op2note <= 0;
				ft0 <= 0;
				ft1 <= 0;
				ft2 <= 0;
				env0 <= 0;
				env1 <= 0;
				env2 <= 0;
				beta0 <= 0;
				beta1 <= 0;
				beta2 <= 0;
				op0offset <= 0; 
				op1offset <= 0; 
				op2offset <= 0;
				end
				
			1:					// sine wave (1.05 Hz)
				begin
				alg <= 0;
				op0note <= 1;
				op1note <= 0;
				op2note <= 0;
				ft0 <= 0;
				ft1 <= 0;
				ft2 <= 0;
				env0 <= 0;
				env1 <= 0;
				env2 <= 0;
				beta0 <= 600;
				beta1 <= 600;
				beta2 <= 600;
				end
				
			2:					// sine wave
				begin
				alg <= 0;
				op0note <= note;
				op1note <= 0;
				op2note <= 0;
				ft0 <= 0;
				ft1 <= 0;
				ft2 <= 0;
				env0 <= 1;
				env1 <= 1;
				env2 <= 1;
				beta0 <= 600;
				beta1 <= 600;
				beta2 <= 600;
				end
				
			3:				// sine wave 123 Hz
				begin
				alg <= 0;
				op0note <= 7'h47;
				op1note <= 0;
				op2note <= 0;
				ft0 <= 0;
				ft1 <= 0;
				ft2 <= 0;
				env0 <= 2;
				env1 <= 2;
				env2 <= 2;
				beta0 <= 600;
				beta1 <= 600;
				beta2 <= 600;
				end
				
			4:				// two operator square wave
				begin
				alg <= 7;					// op0 -> op1 -> output
				op0note <= note + 12; //2nd harmonic (2 x fundamental)
				op1note <= note;		//Fundamental
				op2note <= 0;
				ft0 <= 0;
				ft1 <= 0;
				ft2 <= 0;
				env0 <= 0;
				env1 <= 0;
				env2 <= 0;
				beta0 <= SW[9:4];
				beta1 <= 600;
				beta2 <= 0;
				end
				
			5:				// two operator square wave (123 Hz)
				begin
				alg <= 7;				// op0 -> op1 -> output
				op0note <= 7'h47;
				op1note <= 7'h3B;
				op2note <= 0;
				ft0 <= 0;
				ft1 <= 0;
				ft2 <= 0;
				env0 <= 0;
				env1 <= 0;
				env2 <= 0;
				beta0 <= 500;
				beta1 <= 600;
				beta2 <= 0;
				end
			
			6:				// three operator square wave ( Hz)
				begin
				alg <= 13;				// op0 -> op1 -> op2 -> output
				op0note <= note + 24; //3rd harmonic
				op1note <= note + 12; //2nd harmonic
				op2note <= note;		//Fundamental
				ft0 <= 0;
				ft1 <= 0;
				ft2 <= 0;
				env0 <= 0;
				env1 <= 0;
				env2 <= 0;
				beta0 <= 100;
				beta1 <= 400;
				beta2 <= 600;
				end
				
			7:				// three operator sawtooth wave (215 Hz)
				begin
				alg <= 13;				// op0 -> op1 -> op2 -> output
				op0note <= note;		//Fundamental
				op1note <= note;		//Fundamental
				op2note <= note;		//Fundamental
				ft0 <= 0;
				ft1 <= 0;
				ft2 <= 0;
				env0 <= 0;
				env1 <= 0;
				env2 <= 0;
				beta0 <= 300;
				beta1 <= 600;
				beta2 <= 600;
				end
				
			8:				// three operator triangle wave ( Hz)
				begin
				alg <= 13;				// op0 -> op1 -> op2 -> output
				op0note <= note + 24;
				op1note <= note + 12;
				op2note <= note;
				ft0 <= 0;
				ft1 <= 0;
				ft2 <= 0;
				env0 <= 0;
				env1 <= 0;
				env2 <= 0;
				beta0 <= 200;
				beta1 <= -200;
				beta2 <= 600;
				end
				
			9:				// fade in
				begin
				alg <= 19;				// (op0 + (op1 -> op2)) -> output
				op0note <= note;	//Fundamental with fine tune down
				op1note <= note+12;	//2nd harmonic
				op2note <= note;		//Fundamental
				ft0 <= -1;
				ft1 <= 0;
				ft2 <= 0;
				env0 <= 1;
				env1 <= 1;
				env2 <= 1;
				beta0 <= 200;
				beta1 <= 2;
				beta2 <= 200;
				end
				
			10:			// "dual frequency" (triangle wae -> sine)
				begin
				alg <= 13;				// op0 -> op1 -> op2 -> output
				op0note <= 7'h00;		//-1.34 Hz lfo
				op1note <= 7'h00;		//0.67 Hz lfo
				op2note <= note;		//Fundamental
				ft0 <= 2;
				ft1 <= 1;
				ft2 <= 0;
				env0 <= 1;
				env1 <= 1;
				env2 <= 1;
				beta0 <= -200;
				beta1 <= 900;
				beta2 <= 600;
				end
				
			11:			//Organ sound
				begin
				alg <= 6;				// op0 + op1 + op2 -> output
				op0note <= note;	//Fund
				op1note <= note+12;//2nd harm
				op2note <= note+24;//3rd harm
				ft0 <= 0;
				ft1 <= 0;
				ft2 <= 0;
				env0 <= 2;
				env1 <= 2;
				env2 <= 2;
				beta0 <= 300;
				beta1 <= SW[6:4] << 5;
				beta2 <= SW[9:7] << 5;
				end
			
			12:			//Fifth modulation with fine tune
				begin
				alg <= 13;				// op0 -> op1 -> op2 -> output
				op0note <= note+7;
				op1note <= note+7;		//Fifth
				op2note <= note;		//Fundamental
				ft0 <= 1;
				ft1 <= 0;
				ft2 <= 0;
				env0 <= 1;
				env1 <= 1;
				env2 <= 1;
				beta0 <= 2;
				beta1 <= 6;
				beta2 <= 600;
				end
		endcase
		
		//Individually controllable parameters for default case
		if(keycode == 8'h52)//Press up
		begin
			pressUp <= 1;
		end
		
		if(keycode == 8'h00 & pressUp)//Release Up
		begin
			pressUp <= 0;
			case(Param)
				0:
					alg <= alg + 1;
				1:
					op0offset <= op0offset + 1;
				2:
					op1offset <= op1offset + 1;
				3:
					op2offset <= op2offset + 1;
				4:
					ft0 <= ft0 + 1;
				5:
					ft1 <= ft1 + 1;
				6:
					ft2 <= ft2 + 1;
				7:
					env0 <= env0 + 1;
				8:
					env1 <= env1 + 1;
				9:
					env2 <= env2 + 1;
				10:
					beta0 <= beta0 + 1;
				11:
					beta1 <= beta1 + 1;
				12:
					beta2 <= beta2 + 1;
				endcase
		end
		
		if(keycode == 8'h51)//Press down
		begin
			pressDown <= 1;
		end
		
		if(keycode == 8'h00 & pressDown)//Release down
		begin
			pressDown <= 0;
			case(Param)
				0:
					alg <= alg - 1;
				1:
					op0offset <= op0offset - 1;
				2:
					op1offset <= op1offset - 1;
				3:
					op2offset <= op2offset - 1;
				4:
					ft0 <= ft0 - 1;
				5:
					ft1 <= ft1 - 1;
				6:
					ft2 <= ft2 - 1;
				7:
					env0 <= env0 - 1;
				8:
					env1 <= env1 - 1;
				9:
					env2 <= env2 - 1;
				10:
					beta0 <= beta0 - 1;
				11:
					beta1 <= beta1 - 1;
				12:
					beta2 <= beta2 - 1;
				endcase
		end
		
		if(keycode == 8'h50)//Press left
			pressLeft <= 1;
		
		if(keycode == 8'h00 & pressLeft)//Release left
		begin
			pressLeft <= 0;
			if(Param == 0)
				Param <= 12;
			else
				Param <= Param - 1;
		end
			
		
		if(keycode == 8'h4f)//Press right
			pressRight <= 1;
		
		if(keycode == 8'h00 & pressRight)
		begin
			pressRight <= 0;
			if(Param == 12)
				Param <= 0;
			else
				Param <= Param + 1;
		end
		op0note <= note + op0offset;
		op1note <= note + op1offset;
		op2note <= note + op2offset;
	end
	
	always_comb
	begin
		case(Param)
		0:
			paramvalue = {{26{1'b0}}, alg};
		1:
			paramvalue = {{25{op0offset[6]}}, op0offset};
		2:
			paramvalue = {{25{op1offset[6]}}, op1offset};
		3:
			paramvalue = {{25{op2offset[6]}}, op2offset};
		4:
			paramvalue = {{24{ft0[7]}}, ft0};
		5:
			paramvalue = {{24{ft1[7]}}, ft1};
		6:
			paramvalue = {{24{ft2[7]}}, ft2};
		7:
			paramvalue = {{28{1'b0}}, env0};
		8:
			paramvalue = {{28{1'b0}}, env1};
		9:
			paramvalue = {{28{1'b0}}, env2};
		10:
			paramvalue = {{20{beta0[11]}}, beta0};
		11:
			paramvalue = {{20{beta1[11]}}, beta1};
		12:
			paramvalue = {{20{beta2[11]}}, beta2};
		default:
			paramvalue = 0;
		endcase
	end
	
					
endmodule
