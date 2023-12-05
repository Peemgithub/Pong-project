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

module left_counter(
    input clk,
    input reset,
    input d_incl, d_clr,
    output [3:0] digl0, digl1
    );
    
    // signal declaration
    reg [3:0] r_digl0, r_digl1, digl0_next, digl1_next;
    
    // register control
    always @(posedge clk or posedge reset)
        if(reset) begin
            r_digl1 <= 0;
            r_digl0 <= 0;
        end
        
        else begin
            r_digl1 <= digl1_next;
            r_digl0 <= digl0_next;
        end
    
    // next state logic
    always @* begin
        digl0_next = r_digl0;
        digl1_next = r_digl1;
        
        if(d_clr) begin
            digl0_next <= 0;
            digl1_next <= 0;
        end
        
        else if(d_incl)
            if(r_digl0 == 9) begin
                digl0_next = 0;
                
                if(r_digl1 == 9)
                    digl1_next = 0;
                else
                    digl1_next = r_digl1 + 1;
            end
        
            else    // dig0 != 9
                digl0_next = r_digl0 + 1;
    end
    
    // output
    assign digl0 = r_digl0;
    assign digl1 = r_digl1;
    
endmodule