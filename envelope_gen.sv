
// This module generates an envelope which becomes a multiplier for an operator


//env0:
`define rise_0 3
`define max_0 100
`define fall_0 3

//env1:
`define rise_1 1
`define max_1 100
`define fall_1 1


module envelope_gen( input logic [3:0] env,			// index of the desired envelope
							input logic t,						// fourth bit of t, acts as a ~195Hz ~6.25kHz clock
							//input logic Reset,
							input logic keypress,
							output logic [7:0] magnitude);	// coefficient in front of an operator, gets divided by 100
							
	
	
	always_ff @ (posedge t)
	begin			
	
		case(env)
		
		0:
			begin
			
			if(keypress)								// key pressed
				begin
				
				if(magnitude < (`max_0 - `rise_0))
					magnitude += `rise_0;
				else
					magnitude = `max_0;
				end
			else											// key released
				begin
				
				if(magnitude > `fall_0)
					magnitude -= `fall_0;
				else
					magnitude = 0;
				end
			end
			
		1:
			begin
			
			if(keypress)								// key pressed
				begin
				
				if(magnitude < (`max_1 - `rise_1))
					magnitude += `rise_1;
				else
					magnitude = `max_1;
				end
			else											// key released
				begin
				
				if(magnitude > `fall_1)
					magnitude -= `fall_1;
				else
					magnitude = 0;
				end
			end
			
		2://On off envelope
			begin
			if(keypress)
				magnitude = 100;
			else
				magnitude = 0;
			end
			
		default:
			magnitude = 100;
		
		endcase		
	end

endmodule
