

//	Top level module for the FM synthesizer
//	ECE 385 final Project		David Gong and Isaac Brorson

module synthfreq (

      ///////// Clocks /////////
      input    MAX10_CLK1_50,

      ///////// KEY /////////
      input    [ 1: 0]   KEY,

      ///////// SW /////////
      input    [ 9: 0]   SW,

      ///////// LEDR /////////
      output   [ 9: 0]   LEDR,

      ///////// HEX /////////
      output   [ 7: 0]   HEX0,
      output   [ 7: 0]   HEX1,
      output   [ 7: 0]   HEX2,
      output   [ 7: 0]   HEX3,
      output   [ 7: 0]   HEX4,
      output   [ 7: 0]   HEX5,

      ///////// SDRAM /////////
      output             DRAM_CLK,
      output             DRAM_CKE,
      output   [12: 0]   DRAM_ADDR,
      output   [ 1: 0]   DRAM_BA,
      inout    [15: 0]   DRAM_DQ,
      output             DRAM_LDQM,
      output             DRAM_UDQM,
      output             DRAM_CS_N,
      output             DRAM_WE_N,
      output             DRAM_CAS_N,
      output             DRAM_RAS_N,

      ///////// VGA /////////
      output             VGA_HS,
      output             VGA_VS,
      output   [ 3: 0]   VGA_R,
      output   [ 3: 0]   VGA_G,
      output   [ 3: 0]   VGA_B,





      ///////// ARDUINO /////////
      inout    [15: 0]   ARDUINO_IO,
      inout              ARDUINO_RESET_N
		
);

//=======================================================
//  REG/WIRE declarations
//=======================================================
	logic SPI0_CS_N, SPI0_SCLK, SPI0_MISO, SPI0_MOSI, USB_GPX, USB_IRQ, USB_RST;
	logic [7:0] keycode0, keycode1, keycode2;
	
	//I2s
	logic I2S_MCLK, I2S_DIN, I2S_LRCLK, I2S_DOUT, I2S_SCLK;
	//I2C
	logic i2c0_sda_in, i2c0_scl_in, i2c0_sda_oe, i2c0_scl_oe;
	
	assign i2c0_scl_in = ARDUINO_IO[15];
	assign i2c0_sda_in = ARDUINO_IO[14];
	assign ARDUINO_IO[15] = i2c0_scl_oe ? 1'b0 : 1'bz;
	assign ARDUINO_IO[14] = i2c0_sda_oe ? 1'b0 : 1'bz;

//=======================================================
//  Structural coding
//=======================================================
	assign ARDUINO_IO[10] = SPI0_CS_N;
	assign ARDUINO_IO[13] = SPI0_SCLK;
	assign ARDUINO_IO[11] = SPI0_MOSI;
	assign ARDUINO_IO[12] = 1'bZ;
	assign SPI0_MISO = ARDUINO_IO[12];
	
	assign I2S_SCLK = ARDUINO_IO[5];
	assign I2S_LRCLK = ARDUINO_IO[4];
	assign ARDUINO_IO[3] = I2S_MCLK;
	assign ARDUINO_IO[2] = I2S_DIN;
	assign I2S_DOUT = ARDUINO_IO[1];
	
	assign ARDUINO_IO[9] = 1'bZ;
	assign USB_IRQ = ARDUINO_IO[9];
		
	//Assignments specific to Circuits At Home UHS_20
	assign ARDUINO_RESET_N = USB_RST;
	assign ARDUINO_IO[8] = 1'bZ;
	//GPX is unconnected to shield, not needed for standard USB host - set to 0 to prevent interrupt
	assign USB_GPX = 1'b0;
	
	HexDriver h0 (.In0(SW[3:0]), .Out0(HEX0));
	HexDriver h1 (.In0(SW[7:4]), .Out0(HEX1));
	HexDriver h2 (.In0(SW[9:8]), .Out0(HEX2));
	HexDriver h4 (.In0(Param), .Out0(HEX4));
	
	assign {HEX3[7:0], HEX5[7:0]} = 24'hffff;
	//assign LEDR[9:0] = SW[9:0];
	
	
	assign Reset_h = ~KEY[0];		// we should rename this so that "KEY" isn't confused with keyboard keys
	
	logic[1:0] clkdiv;
	logic[31:0] ShiftReg;			// holds the audio data output
	logic[11:0] t;						// "time" variable
	
	shortint outputWave;								// temp variable which gets stored into ShiftReg every edge of LRCLK
	shortint wave0, wave1, wave2;		// outputWave is the superposition of all waves
	logic key0, key1, key2;				//Pressed or not pressed
	logic [6:0] note0, note1, note2;	//MIDI notes of each voice
	logic [31:0] paramvalue;
	logic [4:0] Param;
	
	
	
	assign I2S_LRCLK_RISING = I2S_LRCLK & ~I2S_LRCLK_prev;
	assign I2S_LRCLK_FALLING = ~I2S_LRCLK & I2S_LRCLK_prev;
	
	assign I2S_DIN = ShiftReg[31];
	
	logic I2S_LRCLK_prev;
	always_ff @ (posedge MAX10_CLK1_50)
	begin
		clkdiv++;
	end
	assign I2S_MCLK = clkdiv[1];		// MCLK is half the frequency of MAX10_CLK
	
	
	
	always_ff @ (posedge I2S_SCLK)
	begin
		if(Reset_h)
			begin
			t <= 0;
			ShiftReg <= 0;
			end
		else
			begin
			I2S_LRCLK_prev <= I2S_LRCLK;
			ShiftReg <= ShiftReg << 1;
			
			if(I2S_LRCLK_RISING)
				begin
				ShiftReg[31:16] <= outputWave;
				end
			else if(I2S_LRCLK_FALLING)
				begin
				ShiftReg[31:16] <= outputWave;
				t <= t + 1;
				end
			outputWave = (wave0 >>> 2) + (wave1 >>> 2) + (wave2 >>> 2);
		end
	end
	
	
	//Converts USB Keyboard keycode to Midi note
	keycodenote kc0(.clk(MAX10_CLK1_50), .keycode(keycode0), .note(note0), .keypress(key0));
	keycodenote kc1(.clk(MAX10_CLK1_50), .keycode(keycode1), .note(note1), .keypress(key1));
	keycodenote kc2(.clk(MAX10_CLK1_50), .keycode(keycode2), .note(note2), .keypress(key2));

	
	/*algorithm al0(.alg(SW[5:0]), .t(t), .keypress(key0), 
				.note(note0), .I2S_LRCLK(I2S_LRCLK),
				.beta0(200), .beta1(200), .beta2(200),
				.env0(0), .env1(0), .env2(0),	
				.outputWave(wave0));
								
	algorithm al1(.alg(SW[5:0]), .t(t), .keypress(key1), 
				.note(note1), .I2S_LRCLK(I2S_LRCLK),
				.beta0(200), .beta1(200), .beta2(200),
				.env0(0), .env1(0), .env2(0),	
				.outputWave(wave1));
				
	algorithm al2(.alg(SW[5:0]), .t(t), .keypress(key2), 
				.note(note2), .I2S_LRCLK(I2S_LRCLK),
				.beta0(200), .beta1(200), .beta2(200),
				.env0(0), .env1(0), .env2(0),	
				.outputWave(wave2));*/
	
	//Button as key press
	/*sound_gen sg1(.soundIndex(SW[3:0]), .t(t), .keypress(~KEY[1]),	
					  .I2S_LRCLK(I2S_LRCLK), .note(7'h37), .outputWave(wave0), .SW(SW));*/
	
	sound_gen sg0(.soundIndex(SW[3:0]), .t(t), .keypress(key0),	
					  .I2S_LRCLK(I2S_LRCLK), .note(note0), .outputWave(wave0), 
					  .clk(MAX10_CLK1_50), .keycode(keycode0), 
					  .paramvalue(paramvalue), .Param(Param));
					  
	sound_gen sg1(.soundIndex(SW[3:0]), .t(t), .keypress(key1),	
					  .I2S_LRCLK(I2S_LRCLK), .note(note1), .outputWave(wave1),
					  .clk(MAX10_CLK1_50), .keycode(keycode0));
	
	sound_gen sg2(.soundIndex(SW[3:0]), .t(t), .keypress(key2),	
					  .I2S_LRCLK(I2S_LRCLK), .note(note2), .outputWave(wave2),
					  .clk(MAX10_CLK1_50), .keycode(keycode0));
	
	
	finalproject fp(
		.*,
		
		.clk_clk(MAX10_CLK1_50),          						  //clk.clk
		.reset_reset_n(1'b1),   									  //reset.reset_n
		.sdram_clk_clk(DRAM_CLK),   								  //sdram_clk.clk
		.sdram_wire_addr(DRAM_ADDR),  							  // sdram_wire.addr
		.sdram_wire_ba(DRAM_BA),    								  //.ba
		.sdram_wire_cas_n(DRAM_CAS_N), 							  //.cas_n
		.sdram_wire_cke(DRAM_CKE),   								  //.cke
		.sdram_wire_cs_n(DRAM_CS_N),  							  //.cs_n
		.sdram_wire_dq(DRAM_DQ),                             //.dq
		.sdram_wire_dqm({DRAM_UDQM,DRAM_LDQM}),              //.dqm
		.sdram_wire_ras_n(DRAM_RAS_N),                       //.ras_n
		.sdram_wire_we_n(DRAM_WE_N),                         //.we_n
		
		//SPI
		.spi0_MISO(SPI0_MISO),         							  //.MISO
		.spi0_MOSI(SPI0_MOSI),        							  //.MOSI
		.spi0_SCLK(SPI0_SCLK),         							  //.SCLK
		.spi0_SS_n(SPI0_CS_N),			 							  //.SS
		
		//USB
		.usb_rst_export(USB_RST),
		.usb_irq_export(USB_IRQ),
		.usb_gpx_export(USB_GPX),
		
		//IO
		.key_export(KEY),
		.hex_digits_export({hex_num_4, hex_num_3, hex_num_1, hex_num_0}),
		.leds_export({hundreds, signs, LEDR}),
		.keycode0_export(keycode0),
		.keycode1_export(keycode1),
		.keycode2_export(keycode2),
		.param_export(Param),
		.paramvalue_export(paramvalue)
	);

endmodule
