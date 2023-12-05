`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Reference book: "FPGA Prototyping by Verilog Examples"
//                      "Xilinx Spartan-3 Version"
// Written by: Dr. Pong P. Chu
// Published by: Wiley, 2008
//
// Adapted for Basys 3 by David J. Marion aka FPGA Dude
//
//////////////////////////////////////////////////////////////////////////////////

module graphic(
    input clk,  
    input reset,    //btnC
    input [3:0] btn,        // btn[0] = left up, btn[1] = left down, btn[2] = right up, btn[3] = right down
    input gra_still,        // still graphics - newgame, game over states
    input video_on,
    input [9:0] x,
    input [9:0] y,
    output graph_on,
    output reg hit, missl, missr,   // ball hit or miss
    output reg [11:0] graph_rgb
    );
    
    // maximum x, y values in display area
    parameter X_MAX = 639;
    parameter Y_MAX = 479;
    
    // create 60Hz refresh tick
    wire refresh_tick;
    assign refresh_tick = ((y == 481) && (x == 0)) ? 1 : 0; // start of vsync(vertical retrace)
    
    
//    // WALLS
//    // LEFT wall boundaries
//    parameter L_WALL_L = 32;    
//    parameter L_WALL_R = 39;    // 8 pixels wide
    // TOP wall boundaries
    parameter T_WALL_T = 64;    
    parameter T_WALL_B = 71;    // 8 pixels wide
    // BOTTOM wall boundaries
    parameter B_WALL_T = 472;    
    parameter B_WALL_B = 479;    // 8 pixels wide
    
    
    
//    // PADDLE
//    // paddle horizontal boundaries
//    parameter X_PAD_L = 600;
//    parameter X_PAD_R = 603;    // 4 pixels wide
//    // paddle vertical boundary signals
//    wire [9:0] y_pad_t, y_pad_b;
//    parameter PAD_HEIGHT = 72;  // 72 pixels high
//    // register to track top boundary and buffer
//    reg [9:0] y_pad_reg = 204;      // Paddle starting position
//    reg [9:0] y_pad_next;
//    // paddle moving velocity when a button is pressed
//    parameter PAD_VELOCITY = 3;     // change to speed up or slow down paddle movement
    
    //Add by myself
    // PADDLE
    // paddle horizontal boundaries
    parameter x_padr_l = 600;
    parameter x_padr_r = 603;    // 4 pixels wide
    // paddle vertical boundary signals
    wire [9:0] y_padr_t, y_padr_b;
    parameter PADr_HEIGHT = 72;  // 72 pixels high
    // register to track top boundary and buffer
    reg [9:0] y_padr_reg = 204;      // Paddle starting position
    reg [9:0] y_padr_next;
    // paddle moving velocity when a button is pressed
    parameter PADr_VELOCITY = 3;     // change to speed up or slow down paddle 
    
    // paddle horizontal boundaries
    parameter x_padl_l = 36;
    parameter x_padl_r = 39;    // 4 pixels wide
    // paddle vertical boundary signals
    wire [9:0] y_padl_t, y_padl_b;
    parameter PADl_HEIGHT = 72;  // 72 pixels high
    // register to track top boundary and buffer
    reg [9:0] y_padl_reg = 204;      // Paddle starting position
    reg [9:0] y_padl_next;
    // paddle moving velocity when a button is pressed
    parameter PADl_VELOCITY = 3;     // change to speed up or slow down paddle movement
    //Add by myself
    
    
    // BALL
    // square rom boundaries
    parameter BALL_SIZE = 8;
    // ball horizontal boundary signals
    wire [9:0] x_ball_l, x_ball_r;
    // ball vertical boundary signals
    wire [9:0] y_ball_t, y_ball_b;
    // register to track top left position
    reg [9:0] y_ball_reg, x_ball_reg;
    // signals for register buffer
    wire [9:0] y_ball_next, x_ball_next;
    // registers to track ball speed and buffers
    reg [9:0] x_delta_reg, x_delta_next;
    reg [9:0] y_delta_reg, y_delta_next;
    // positive or negative ball velocity
    parameter BALL_VELOCITY_POS = 2;    // ball speed positive pixel direction(down, right)
    parameter BALL_VELOCITY_NEG = -2;   // ball speed negative pixel direction(up, left)
    // round ball from square image
    wire [2:0] rom_addr, rom_col;   // 3-bit rom address and rom column
    reg [7:0] rom_data;             // data at current rom address
    wire rom_bit;                   // signify when rom data is 1 or 0 for ball rgb control
    
    
    // Register Control
    always @(posedge clk or posedge reset)
        if(reset) begin
            y_padr_reg <= 204;
            y_padl_reg <= 204;
            x_ball_reg <= 0;
            y_ball_reg <= 0;
            x_delta_reg <= 10'h002;
            y_delta_reg <= 10'h002;
        end
        else begin
            y_padr_reg <= y_padl_next;
            y_padl_reg <= y_padr_next;
            x_ball_reg <= x_ball_next;
            y_ball_reg <= y_ball_next;
            x_delta_reg <= x_delta_next;
            y_delta_reg <= y_delta_next;
        end
    
    
    // ball rom
    always @*
        case(rom_addr)
            3'b000 :    rom_data = 8'b00111100; //   ****  
            3'b001 :    rom_data = 8'b01111110; //  ******
            3'b010 :    rom_data = 8'b11111111; // ********
            3'b011 :    rom_data = 8'b11111111; // ********
            3'b100 :    rom_data = 8'b11111111; // ********
            3'b101 :    rom_data = 8'b11111111; // ********
            3'b110 :    rom_data = 8'b01111110; //  ******
            3'b111 :    rom_data = 8'b00111100; //   ****
        endcase
    
    
    // OBJECT STATUS SIGNALS
    wire t_wall_on, b_wall_on, padr_on, padl_on, sq_ball_on, ball_on;
    wire [11:0] padr_rgb, padl_rgb, ball_rgb, bg_rgb;
    
    
//    // pixel within wall boundaries
//    assign l_wall_on = ((L_WALL_L <= x) && (x <= L_WALL_R)) ? 1 : 0;
    assign t_wall_on = ((T_WALL_T <= y) && (y <= T_WALL_B)) ? 1 : 0;
    assign b_wall_on = ((B_WALL_T <= y) && (y <= B_WALL_B)) ? 1 : 0;
    
    
    // assign object colors
    assign wall_rgb   = 12'h00F;    // blue walls
    assign padr_rgb   = 12'h00F;    // blue paddle
    assign padl_rgb   = 12'h00F;    // blue paddle
    assign ball_rgb   = 12'hF00;    // red ball
    assign bg_rgb     = 12'h0FF;    // aqua background
    
    
    // paddle 
    assign y_padl_t = y_padl_reg;                             // paddle top position
    assign y_padl_b = y_padl_t + PADl_HEIGHT - 1;              // paddle bottom position
    assign padl_on = (x_padl_l <= x) && (x <= x_padl_r) &&     // pixel within paddle boundaries
                    (y_padl_t <= y) && (y <= y_padl_b);
                    
    // paddle 
    assign y_padr_t = y_padr_reg;                             // paddle top position
    assign y_padr_b = y_padr_t + PADr_HEIGHT - 1;              // paddle bottom position
    assign padr_on = (x_padr_l <= x) && (x <= x_padr_r) &&     // pixel within paddle boundaries
                    (y_padr_t <= y) && (y <= y_padr_b);
       
                    
    // Paddle Control
    always @* begin //fix push in the same time
        y_padr_next = y_padr_reg;     // no move
        y_padl_next = y_padl_reg;     // no move
        
        if(refresh_tick)
            if(btn[3] & (y_padr_b < (B_WALL_T - 1 - PADr_VELOCITY))) //edit btn[3] to push k
                y_padr_next = y_padr_reg + PADr_VELOCITY;  // move down
            else if(btn[2] & (y_padr_t > (T_WALL_B - 1 - PADr_VELOCITY))) //edit btn[2] to push i
                y_padr_next = y_padr_reg - PADr_VELOCITY;  // move up
            else if(btn[1] & (y_padl_b < (B_WALL_T - 1 - PADl_VELOCITY))) //edit btn[1] to push s
                y_padl_next = y_padl_reg + PADl_VELOCITY;  // move down
            else if(btn[0] & (y_padl_t > (T_WALL_B - 1 - PADl_VELOCITY))) //edit btn[0] to push w
                y_padl_next = y_padl_reg - PADl_VELOCITY;  // move up
    end
    
    
    // rom data square boundaries
    assign x_ball_l = x_ball_reg;
    assign y_ball_t = y_ball_reg;
    assign x_ball_r = x_ball_l + BALL_SIZE - 1;
    assign y_ball_b = y_ball_t + BALL_SIZE - 1;
    // pixel within rom square boundaries
    assign sq_ball_on = (x_ball_l <= x) && (x <= x_ball_r) &&
                        (y_ball_t <= y) && (y <= y_ball_b);
    // map current pixel location to rom addr/col
    assign rom_addr = y[2:0] - y_ball_t[2:0];   // 3-bit address
    assign rom_col = x[2:0] - x_ball_l[2:0];    // 3-bit column index
    assign rom_bit = rom_data[rom_col];         // 1-bit signal rom data by column
    // pixel within round ball
    assign ball_on = sq_ball_on & rom_bit;      // within square boundaries AND rom data bit == 1
 
  
    // new ball position
    assign x_ball_next = (gra_still) ? X_MAX / 2 :
                         (refresh_tick) ? x_ball_reg + x_delta_reg : x_ball_reg;
    assign y_ball_next = (gra_still) ? Y_MAX / 2 :
                         (refresh_tick) ? y_ball_reg + y_delta_reg : y_ball_reg;
    
    // change ball direction after collision
    always @* begin
        hit = 1'b0;
        missl = 1'b0;
        missr = 1'b0;
        x_delta_next = x_delta_reg;
        y_delta_next = y_delta_reg;
        
        if(gra_still) begin
            x_delta_next = BALL_VELOCITY_NEG;
            y_delta_next = BALL_VELOCITY_POS;
        end
        
        else if(y_ball_t < T_WALL_B)                   // reach top
            y_delta_next = BALL_VELOCITY_POS;   // move down
        
        else if(y_ball_b > (B_WALL_T))         // reach bottom wall
            y_delta_next = BALL_VELOCITY_NEG;   // move up
        
//        else if(x_ball_l <= L_WALL_R)           // reach left wall
//            x_delta_next = BALL_VELOCITY_POS;   // move right
        
        else if((x_padr_l <= x_ball_r) && (x_ball_r <= x_padr_r) &&
                (y_padr_t <= y_ball_b) && (y_ball_t <= y_padr_b)) begin
                    x_delta_next = BALL_VELOCITY_NEG;
                    hit = 1'b1;   //hit right         
        end
        
        else if((x_padl_r >= x_ball_l) && (x_ball_l <= x_padl_l) &&
                (y_padl_t <= y_ball_b) && (y_ball_t <= y_padl_b)) begin
                    x_delta_next = BALL_VELOCITY_POS;
                    hit = 1'b1;   //hit left      
        end
        
        else if(x_ball_r > X_MAX) // miss right
            missr = 1'b1;
            
        else if(x_ball_r < 0) //miss left
            missl = 1'b1;
    end                    
    
    // output status signal for graphics 
    assign graph_on = t_wall_on | b_wall_on | padl_on | padr_on | ball_on;
    
    
    // rgb multiplexing circuit
    always @*
        if(~video_on)
            graph_rgb = 12'h000;      // no value, blank
        else
            if(t_wall_on | b_wall_on)
                graph_rgb = wall_rgb;     // wall color
            else if(padr_on)
                graph_rgb = padr_rgb;      // paddle color
            else if(padl_on)
                graph_rgb = padl_rgb;      // paddle color
            else if(ball_on)
                graph_rgb = ball_rgb;     // ball color
            else
                graph_rgb = bg_rgb;       // background
       
endmodule