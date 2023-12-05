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

module right_counter(
    input clk,
    input reset,
    input d_incr, d_clr,
    output [3:0] digr0, digr1
    );
    
    // signal declaration
    reg [3:0] r_digr0, r_digr1, digr0_next, digr1_next;
    
    // register control
    always @(posedge clk or posedge reset)
        if(reset) begin
            r_digr1 <= 0;
            r_digr0 <= 0;
        end
        
        else begin
            r_digr1 <= digr1_next;
            r_digr0 <= digr0_next;
        end
    
    // next state logic
    always @* begin
        digr0_next = r_digr0;
        digr1_next = r_digr1;
        
        if(d_clr) begin
            digr0_next <= 0;
            digr1_next <= 0;
        end
        
        else if(d_incr)
            if(r_digr0 == 9) begin
                digr0_next = 0;
                
                if(r_digr1 == 9)
                    digr1_next = 0;
                else
                    digr1_next = r_digr1 + 1;
            end
        
            else    // dig0 != 9
                digr0_next = r_digr0 + 1;
    end
    
    // output
    assign digr0 = r_digr0;
    assign digr1 = r_digr1;
    
endmodule