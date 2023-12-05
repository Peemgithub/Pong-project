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

module top(
    input clk,              // 100MHz
    input reset,            // btnC
    input [3:0] btn,        // btnD, btnU, btnL, btnR
    output hsync,           // to VGA Connector
    output vsync,           // to VGA Connector
    output [11:0] rgb,       // to DAC, to VGA Connector
    
    output [6:0] seg,
    output dp,
    output [3:0] an
    );
    
    // state declarations for 4 states
    parameter newgame = 2'b00;
    parameter play    = 2'b01;
    parameter newball = 2'b10;
    parameter over    = 2'b11;
           
        
    // signal declaration
    reg [1:0] state_reg, state_next;
    wire [9:0] w_x, w_y;
    wire w_vid_on, w_p_tick, graph_on, hit, missl, missr;
    wire [1:0] text_on;
    wire [11:0] graph_rgb, text_rgb;
    reg [11:0] rgb_reg, rgb_next;
    wire [3:0] digl0, digl1, digr0, digr1;
    reg [3:0] r_digr0, r_digr1, r_digl0, r_digl1; //add
    reg gra_still, d_incl, d_incr, d_clr, timer_start;
    wire timer_tick, timer_up;
//    reg [1:0] ball_reg, ball_next;
    
    
    // Module Instantiations
    vga_controller vga_unit(
        .clk_100MHz(clk),
        .reset(reset),
        .video_on(w_vid_on),
        .hsync(hsync),
        .vsync(vsync),
        .p_tick(w_p_tick),
        .x(w_x),
        .y(w_y));
    
    text text_unit(
        .clk(clk),
        .x(w_x),
        .y(w_y),
        .digl0(digl0),
        .digl1(digl1),
        .digr0(digr0),
        .digr1(digr1),
//        .ball(ball_reg),
        .text_on(text_on),
        .text_rgb(text_rgb));
        
    graphic graph_unit(
        .clk(clk),
        .reset(reset),
        .btn(btn),
        .gra_still(gra_still),
        .video_on(w_vid_on),
        .x(w_x),
        .y(w_y),
        .hit(hit),
        .missl(missl),
        .missr(missr),
        .graph_on(graph_on),
        .graph_rgb(graph_rgb));
    
    // 60 Hz tick when screen is refreshed
    assign timer_tick = (w_x == 0) && (w_y == 0);
    timer timer_unit(
        .clk(clk),
        .reset(reset),
        .timer_tick(timer_tick),
        .timer_start(timer_start),
        .timer_up(timer_up));
    
//    counter counter_unit(
//        .clk(clk),
//        .reset(reset),
//        .d_incl(d_incl),
//        .d_incr(d_incr),
//        .d_clr(d_clr),
//        .digl0(digl0),
//        .digl1(digl1),
//        .digr0(digr0),
//        .digr1(digr1));
        
    left_counter lcounter_unit(
        .clk(clk),
        .reset(reset),
        .d_incl(d_incl),
        .d_clr(d_clr),
        .digl0(digl0),
        .digl1(digl1));
        
    right_counter rcounter_unit(
        .clk(clk),
        .reset(reset),
        .d_incr(d_incr),
        .d_clr(d_clr),
        .digr0(digr0),
        .digr1(digr1));
       
    
    // FSMD state and registers
    always @(posedge clk or posedge reset)
        if(reset) begin
            state_reg <= newgame;
//            ball_reg <= 0;
            rgb_reg <= 0;
        end
    
        else begin
            state_reg <= state_next;
//            ball_reg <= ball_next;
            if(w_p_tick)
                rgb_reg <= rgb_next;
        end
    
    // FSMD next state logic
    always @* begin
        gra_still = 1'b1;
        timer_start = 1'b0;
        d_incl = 1'b0;
        d_incr = 1'b0;
        d_clr = 1'b0;
        state_next = state_reg;
//        ball_next = ball_reg;
        
        case(state_reg)
            newgame: begin
//                ball_next = 2'b11;          // three balls
                d_clr = 1'b1;               // clear score
                
                if(btn != 4'b0000) begin      // button pressed
                    state_next = play;
//                    ball_next = ball_reg - 1;    
                end
            end
            
            play: begin
                gra_still = 1'b0;   // animated screen
                
//                if(hit)
////                    d_inc = 1'b1;   // increment score
//                    pass;
                
                if(missr) begin
                    if(r_digl1==9 && r_digl0==9)
                        state_next = over;
                    
                    else
                        d_incl = 1'b1;
                        state_next = newball;
                    
                    timer_start = 1'b1;     // 2 sec timer
//                    ball_next = ball_reg - 1;
                end
                
                else if(missl) begin
                    if(r_digr1==9 && r_digr0==9)
                        state_next = over;
                    
                    else
                        d_incr = 1'b1;
                        state_next = newball;
                    
                    timer_start = 1'b1;     // 2 sec timer
//                    ball_next = ball_reg - 1;
                end
            end
            
            newball: // wait for 2 sec and until button pressed
            if(timer_up && (btn != 4'b0000))
                state_next = play;
                
            over:   // wait 2 sec to display game over
                if(timer_up)
                    state_next = newgame;
        endcase           
    end
    
    // rgb multiplexing
    always @*
        if(~w_vid_on)
            rgb_next = 12'h000; // blank
        
        else
            if(text_on[1] || (state_reg == newgame) || ((state_reg == over) && text_on[0]))
                rgb_next = text_rgb;    // colors in pong_text
            
            else if(graph_on)
                rgb_next = graph_rgb;   // colors in graph_text
                
//            else if(text_on[2])
//                rgb_next = text_rgb;    // colors in pong_text
                
            else
                rgb_next = 12'h0FF;     // aqua background
    
    // output
    assign rgb = rgb_reg;
    
    
    ////////////////////////////////////////
    // Assign number
    wire [3:0] num3,num2,num1,num0; // From left to right
    
    assign num0=r_digr0;
    assign num1=r_digr1;
    assign num2=r_digl0;
    assign num3=r_digl1;

    wire an0,an1,an2,an3;
    assign an={an3,an2,an1,an0};
    
    ////////////////////////////////////////
    // Clock
    wire targetClk;
    wire [18:0] tclk;
    assign tclk[0]=clk;
    genvar c;
    generate for(c=0;c<18;c=c+1) begin
        clockDiv fDiv(tclk[c+1],tclk[c]);
    end endgenerate
    
    clockDiv fdivTarget(targetClk,tclk[18]);
    
    ////////////////////////////////////////
    // Display
    quadSevenSeg q7seg(seg,dp,an0,an1,an2,an3,num0,num1,num2,num3,targetClk);
    
endmodule