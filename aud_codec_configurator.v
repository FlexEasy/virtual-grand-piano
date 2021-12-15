module codec_configurator(
    input               clk,

    output[23:0]        i2c_data,
    output              i2c_start,
    output              i2c_sclk,
    output              i2c_sdat,

    input               done,
    input               ack
    ); 

/*
    reg [23:0] i2c_data;
    reg i2c_start;
    wire i2c_sclk;
    wire i2c_sdat;
    reg done;
    reg ack;
*/
    /*================== WM8731 configuration, datasheet pg49 ===================
     * 2 byte configuration for the wm8731  register
     * 7-bit addr[15:9] and 9-bit config[8:0]
    */
    
    // Headphone out configuration pg 50, 
    reg[15:0] CONFIG_LEFT_HP_OUT;
    reg[15:0] CONFIG_RIGHT_HP_OUT;
    assign CONFIG_LEFT_HP_OUT = 15'b0000010_00_1111111;         // both +6 dB
    assign CONFIG_RIGHT_HP_OUT = 15'b0000011_00_1111111;

    // Analog audio path control, R4, pg 51
    // select DAC and disable line in & mic
    reg [15:0] CONFIG_ANALOG_AUDIO_PATH_CTRL;
    assign CONFIG_ANALOG_AUDIO_PATH_CTRL = 15'b0000100_00_0_0_1_0_0_1_0; 

    // Digital Audio Path control, R5, pg 52
    reg [15:0] CONFIG_DIGITAL_AUDIO_PATH_CTRL;
    assign CONFIG_DIGITAL_AUDIO_PATH = 15'b0000101_000_0_0_0_00_0;

    // Power down control, R6, pg 52
    // disbale line and mic inputs 
    reg [15:0] CONFIG_POWER_DOWN_CONTROL;	
    assign CONFIG_POWER_DOWN_CONTROL = 15'b0000110_0_0_0_0_0_0_1_1_1;	 				

    // Digital audio interface control, R7, pg 36, 53
    // Enable slave mode, Select 16-bit length and I2S format
    reg [15:0] CONFIG_DIGITAL_AUDIO_INTERFACE_FORMAT;
    assign CONFIG_DIGITAL_AUDIO_INTERFACE_FORMAT = 15'b0000111_0_0_0_0_0_00_10

    // Sampling Control, R8, pg 38-42, 53
    // MCLK frequency requirment: 12.288 MHz, DAC Sampling rate: 48kHz
    reg [15:0] CONFIG_SAMPLING_CTRL;
    assign CONFIG_SAMPLING_CTRL = 15'b0001000_0_0_0_0000_0_0

    // Active controle
    reg [15:0] CONFIG_ACTIVE_CONTROL;						// activate interface 
    assign CONFIG_ACTIVE_CONTROL = 15'b0001001_000000001;

    /*============== END WM config parameters setup ==================*/
    

    // 7-bit addr specifying the wm8731 
    reg [6:0] wm_addr;
    assign wm_addr = 7'b0011010;


    // State machine for configuration 
    reg [4:0] CONFIG_STATE;


    i2c_controller i2c(
    .clk(clk),
    .i2c_sclk(i2c_sclk),
    .i2c_sdat(i2c_sdat),
    .start(i2c_start),
    .done(done),
    .ack(ack),
    .i2c_data(i2c_data)
    );


    initial @(posedge clk) begin
    //reg [7:0] i2c_addr = 8'b00110100;
    //reg [15:0] WM_Config = 16'b0000110000000111;
    i2c_data <= 24'b001101000000110000000111;
    i2c_start <= 1;
    end

    always @(posedge clk) begin


    end



    reg [3:0] state;

// configuration states 
parameter 
    ST_IDLE=0, 
    ST_START=1, 
    ST_LEFT_HP=2, 
    ST_RIGHT_HP=3, 
    ST_ANALOG_AUD_PATH=4,
    ST_DIGITAL_AUD_PATH=5,
    ST_PWR_DWN_CTRL=6,
    ST_DIGI_AUD_INTERFACE_FORMAT=7,
    ST_SAMPLING_CTRL=8,
    ST_ACTIVE_CTRL=9,
    ST_FINISH=10;

always @( posedge clk, posedge rst ) begin
    if( rst )
       state <= ST_IDLE;
    else begin
        case( state )
        ST_IDLE:
        begin
        // Either coniguration has finished or no need to configure yet
            if (i_start_config)
                state <= ST_IDLE;
            else
                state <= ST_START;
        end
        ST_START:
        begin
            // start our configuration process 
            state <= ST_LEFT_HP;
        end
        ST_LEFT_HP:
        begin
            // send the config parameters to wm8731
            i2c_data[23:16] <= wm_addr;
            i2c_data[15:0] <= CONFIG_LEFT_HP_OUT;
            i2c_start <= 1;
        end
        ST_RIGHT_HP:
        begin
            if( inp ) state <= 2'b01;
            else state <= 2'b10;
        end
        endcase
    end
end
endmodule
