`timescale 1ns / 1ps

module Final(clk,reset,resetSW,CX,AN,Load,dataA,done,audioOut,aud_sd);
input clk,reset,resetSW,Load;
wire playSound;
input [7:0] dataA; 
output done;
output [7:0]CX,AN;
wire [7:0] pat0,pat1;
wire [1:0] m;
wire outsignal;
output audioOut;
output aud_sd;
slowerClkGen ck(clk,resetSW,outsignal);
counter count(outsignal,m);
Game M(outsignal,reset,done,Load,dataA,CX,AN,m,playSound);
SongPlayer S(clk,reset,playSound,audioOut,aud_sd);
endmodule


module Game(clk,reset,done,Load,dataA,CX,AN,m,playSound);//Converting Decimal to BCD
     output reg [7:0] CX,AN;
     output reg playSound;
     input [1:0] m;
     localparam n=8;
     reg [2:0] state_reg, state_next;
     output reg done;
     input wire clk, reset;
     input Load;
     input [n-1:0] dataA; 
     localparam [2:0] A=3'b000, B=3'b001, C=3'b010, D=3'b011, E=3'b100;
      reg done_next; 
      reg [7:0] registerA, registerA_next;
     
  always @(posedge clk, posedge reset)
           if (reset)
     begin
	 state_reg<=A;
	 registerA<=0;
	 done=0;
	 end
           else
     begin
	 state_reg<=state_next;   
	 registerA<=registerA_next;
	 done<=done_next; 
	 end
	   
  always@*
    begin
    state_next=state_reg;
    registerA_next=registerA;
	done_next=done;
	case (state_reg)
	
A:
  begin
  playSound=0;
  case (m)
    0: begin
  CX = 8'b0000_0000;//8
  AN = 8'b1111_1110;
  end
    1: begin
  CX = 8'b0000_0010;//0
  AN = 8'b1111_1101;
  end
  endcase
       
	    if (Load)
	    begin
		registerA ={4'b0, dataA};
		if (registerA==8'b0000_1000)//8
		state_next=B;
		//done_next=0;
		else 
		state_next=A;
		end       
	 end  
	  
B:
begin
playSound=0;
 case (m)
    0: begin
  CX = 8'b1001_1001;//4 
  AN = 8'b1111_1110;
  end
    1: begin
  CX = 8'b1001_1111;//1   
  AN = 8'b1111_1101;
  end
  endcase
  
	    if (Load)
	    begin
		registerA ={4'b0, dataA};
		if (registerA==8'b0000_1110)//14
		state_next=C;
		//done_next=0;
		else 
		state_next=B;
		end	    
	  end
	  
C:
begin
playSound=0;
 case (m)
    0: begin
  CX = 8'b0000_0000;//8
  AN = 8'b1111_1110;
  end
    1: begin
  CX = 8'b0001_1111;//7
  AN = 8'b1111_1101;
  end
  endcase
  
	  if (Load)
	    begin
		registerA ={4'b0, dataA};
		if (registerA==8'b0100_1110)//78
		state_next=D;
		//done_next=1;
		else 
		state_next=C;
		end
	end
	
D:	
begin
playSound=0;
  case (m)
    0: begin
  CX = 8'b0000_1000;//9
  AN = 8'b1111_1110;
  end
    1: begin
  CX = 8'b0000_1000;//9
  AN = 8'b1111_1101;
  end
  endcase 

	  if (Load)
	    begin
		registerA ={4'b0, dataA};
		if (registerA==8'b0110_0011)//99
		state_next=E; 
		//done_next=1;
		else 
		state_next=D; 
		end
	end 
	 
E:  
      begin
      playSound=1;
      
    case (m)
    0: begin
  CX = 8'b1111_1111;//off
  AN = 8'b1111_1110;
  end
    1: begin
  CX = 8'b1111_1111;//off
  AN = 8'b1111_1101;
  end
  endcase 
  end
	 
	  default:
	  begin
	  state_next=A;
	  done_next=0;
	  end
                 endcase
            end
endmodule


module counter (G,Q);
input G;
output reg [1:0]Q;
always @(posedge G)
Q<=Q+1;
endmodule


module slowerClkGen(clk, resetSW, outsignal);
    input clk;
    input resetSW;
    output  outsignal;
reg [26:0] counter;  
reg outsignal;
    always @ (posedge clk)
    begin
if (resetSW)
  begin
counter=0;
outsignal=0;
  end
else
  begin
  counter = counter +1;
  if (counter == 10_000) 
begin
outsignal=~outsignal;
counter =0;
end
 end
   end
endmodule



module SongPlayer( input clock, input reset, input playSound, output reg audioOut, output wire aud_sd);
reg [19:0] counter;
reg [31:0] time1, noteTime;
reg [9:0] msec, number;	//millisecond counter, and sequence number of musical note.
wire [4:0] note, duration;
wire [19:0] notePeriod;
parameter clockFrequency = 100_000_000; 

assign aud_sd = 1'b1;

MusicSheet 	mysong(number, notePeriod, duration	);
always @ (posedge clock) 
  begin
	if(reset | ~playSound) 
 		begin 
          counter <=0;  
          time1<=0;  
          number <=0;  
          audioOut <=1;	
     	end
else 
begin
		counter <= counter + 1; 
time1<= time1+1;
		if( counter >= notePeriod) 
   begin
			counter <=0;  
			audioOut <= ~audioOut ; 
   end	//toggle audio output 	
		if( time1 >= noteTime) 
begin	
				time1 <=0;  
number <= number + 1; 
end  //play next note
 if(number == 48) number <=0; // Make the number reset at the end of the song
	end
  end	
  always @(duration) noteTime = duration * clockFrequency/8; 
       //number of   FPGA clock periods in one note.
endmodule   



module MusicSheet( input [9:0] number,output reg [19:0] note, output reg [4:0] duration);
parameter   QUARTER = 5'b00010; 
parameter	HALF = 5'b00100;
parameter	ONE = 2* HALF;
parameter	TWO = 2* ONE;
parameter	FOUR = 2* TWO;
parameter C4=50_000_000/523.25,D4=50_000_000/587.33,E4 = 50_000_000/659.25,F4=50_000_000/698.84,G4 =50_000_000/783.99,C5 = C4/2, SP = 1;  
parameter A4=50_000_000/440 ,G3 = G4*2, A3=A4*2, A2=A3*2, A=A2*2;
always @ (number) begin
case(number) 
5: 	begin note = SP; duration = HALF; 	end	
6: 	begin note = C4; duration = QUARTER; end	 
7: 	begin note = E4; duration = QUARTER; end	
8: 	begin note = F4; duration = QUARTER; end	
9: 	begin note = G4; duration = ONE; 	end
10: begin note = SP; duration = QUARTER; end	
11: begin note = C4; duration = QUARTER; end	
12: begin note = E4; duration = QUARTER; end	
13: begin note = F4; duration = QUARTER; end	
14: begin note = G4;  duration = HALF;	end	
15: begin note = E4; duration = HALF; 	end	
16: begin note = C4; duration = HALF; 	end	
17: begin note = E4;  duration = HALF;	end	
18: begin note = D4; duration = ONE; 	end	
19: begin note = SP; duration = HALF; 	end	
20: begin note = E4; duration = QUARTER; end	
21: begin note = D4; duration = QUARTER; end	
22: begin note = C4; duration = ONE;end	
23: begin note = C4; duration = QUARTER; end	
24: begin note = E4; duration = HALF; end	
25: begin note = G4; duration = QUARTER; end	
26: begin note = G4; duration = QUARTER; end	
27: begin note = G4; duration = QUARTER; end	
28: begin note = F4; duration = ONE; end	
29: begin note = SP; duration = HALF; end	
30: begin note = E4; duration = QUARTER; end	
31: begin note = F4; duration = QUARTER; end	
32: begin note = G4; duration = HALF; end	
33: begin note = E4; duration = HALF; end	
34: begin note = D4; duration = HALF; end	
35: begin note = D4; duration = HALF; end	
36: begin note = D4; duration = HALF;end	
37: begin note = C4; duration = ONE; end	
38: begin note = SP;   duration = HALF;  end 
default: 	begin note = C4; duration = FOUR; 	end
endcase
end
endmodule