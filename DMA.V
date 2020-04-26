module instr_memory(IR,clck);
output reg [31:0] IR;
input clck;

initial
begin
IR=32'b000010_0101010101010_10_1100100000_0; //(4*32)
#50;
IR=32'b000011_10101010101010_10_111110100_1;

end

endmodule


module CPU(Hbrust,Addresult,Dreq,Back,Data_count,Addr,Pwrite,Addr_bus,cWrite,cRead,clck,IR,D_ack,Breq,Data,Data_bus);
output reg Dreq,Back,Pwrite,cWrite,cRead;
output reg [1:0] Data_count;
output reg [1:0] Hbrust;
inout  [31:0] Data,Data_bus;
output reg [31:0] Addr,Addr_bus,Addresult;
input   [31:0] IR;
input   clck,D_ack,Breq;
reg [31:0] cpuo_data;
reg [31:0] reg_file[0:4];
integer file;

assign Data=(Pwrite==1)?cpuo_data:32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
assign Data_bus=(cWrite==1)?cpuo_data:32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;

always@(posedge clck)
begin

if((IR[31:26]==0) || (IR[31:26]==3)) //add op
begin
reg_file[2]<=reg_file[0]+reg_file[1];
Addresult<= reg_file[2];
end

if((IR[31:26]==2)& (Back==0)) //SW op
begin
case(IR[12:11])
0:begin   //Transfer 1*32 bits 
  Hbrust<=0;
  Addr_bus<=IR[10:1];
  cWrite<=1;
  cpuo_data<=1000;
  end
1:begin //Transfer 2*32 bits
  Hbrust<=1;
  Addr_bus<=IR[10:1];
  cWrite<=1;
  cpuo_data<=1000;
  @(negedge clck)
  Addr_bus<=IR[10:1];
  cWrite<=1;
  cpuo_data<=2000;
  end
2:begin //Transfer 4*32 bits
  Hbrust<=2;
  Addr_bus<=IR[10:1];
  cWrite<=1;
  cpuo_data<=1000;
  @(negedge clck)
  @(negedge clck)
  Addr_bus<=IR[10:1];
  cWrite<=1;
  cpuo_data<=2000;
  @(negedge clck)
  Addr_bus<=IR[10:1];
  cWrite<=1;
  cpuo_data<=3000;
  @(negedge clck)
  Addr_bus<=IR[10:1];
  cWrite<=1;
  cpuo_data<=4000;    
  end
endcase 

cWrite<=0;

end


if((IR[31:26]==1)&(Back==0)) //LW op
begin
cRead<=1;
case(IR[12:11])
0:begin //Transfer 1*32 bits 
  Hbrust<=0;
  Addr_bus<=IR[10:1];
  cRead<=1;
  cpuo_data<=Data_bus;

  end
1:begin //Transfer 2*32 bits 
  Hbrust<=1;
  Addr_bus<=IR[10:1];
  cRead<=1;
  cpuo_data<=Data_bus;
  @(negedge clck)
  Addr_bus<=IR[10:1];
  cRead<=1;
  cpuo_data<=Data_bus;
  end
2:begin //Transfer 4*32 bits
  Hbrust<=2; 
  Addr_bus<=IR[10:1];
  cRead<=1;
  cpuo_data<=Data_bus;
  @(negedge clck)
  Addr_bus<=IR[10:1];
  cRead<=1;
  cpuo_data<=Data_bus;
  @(negedge clck)
  Addr_bus<=IR[10:1];
  cRead<=1;
  cpuo_data<=Data_bus;
  @(negedge clck)
  Addr_bus<=IR[10:1];
  cRead<=1;
  cpuo_data<=Data_bus;  
  end
endcase  
cRead<=0;

end //end of lW if 

if(IR[31:26]==3) //DMA Write & Read
begin
Dreq<=1;
reg_file[2]<=reg_file[0]+reg_file[1];
Addresult<= reg_file[2];

if(D_ack==1)
begin
Back<=1;
case(IR[0])

1: begin//write Mode 
if(IR[14:13]==0) //1*32 bits 
begin
Data_count<=0;
Addr<=IR[10:1];
Pwrite<=1;
cpuo_data<=1000;
end
else if(IR[14:13]==1)//2*32 bits
begin
Data_count<=1;
Addr<=IR[10:1];
Pwrite<=1;
Addr<=IR[10:1];
cpuo_data<=1000;
@(negedge clck)
Addr<=IR[10:1];
Pwrite<=1;
Addr<=IR[10:1];
cpuo_data<=2000;
end
else if(IR[14:13]==2) //4*32 bits
begin
Data_count<=2;
Addr<=IR[10:1];
Pwrite<=1;
cpuo_data<=1000;
@(negedge clck)
Addr<=IR[10:1];
Pwrite<=1;
cpuo_data<=2000;
@(negedge clck)
Addr<=IR[10:1];
Pwrite<=1;
cpuo_data<=3000;
@(negedge clck)
Addr<=IR[10:1];
Pwrite<=1;
cpuo_data<=4000;
end
end

0:begin //Read mode
if(IR[14:13]==0)//1*32 bits
begin
Data_count<=0;
Addr<=IR[10:1];
Pwrite<=0;
cpuo_data<=Data;
end
if(IR[14:13]==1)//2*32 bits
begin
Data_count<=1;
Addr<=IR[10:1];
Pwrite<=0;
cpuo_data<=Data;
@(negedge clck)
Addr<=IR[10:1];
Pwrite<=0;
cpuo_data<=Data;
end
if(IR[14:13]==1)//4*32 bits
begin
Data_count<=2;
Addr<=IR[10:1];
Pwrite<=0;
cpuo_data<=Data;
@(negedge clck)
Addr<=IR[10:1];
Pwrite<=0;
cpuo_data<=Data;
@(negedge clck)
Addr<=IR[10:1];
Pwrite<=0;
cpuo_data<=Data;
@(negedge clck)
Addr<=IR[10:1];
Pwrite<=0;
cpuo_data<=Data;
end

end

endcase 

end 

if(Breq==1)
Back<=1;

end

end //end always block 


initial
begin
reg_file[0]=4; reg_file[1]=6; Back<=0; cWrite=0; cRead=0; Hbrust=0;
end

endmodule

module DMA(Dbrust,DWrite,DRead,D_ack,Breq,intr,Addr_bus,Dreq,Addr,Data_count,clck,Reset,Pwrite,Data,Data_bus,Back);
output reg D_ack,Breq,intr,DWrite,DRead;
output reg [31:0] Addr_bus;
input  Dreq,clck,Reset,Pwrite,Back;
input [31:0] Addr;
output reg[1:0] Dbrust;
input [1:0] Data_count;
inout [31:0]Data_bus,Data;
reg [31:0] addr_reg,Dma_data;
reg [31:0] Data_reg;
reg [1:0] Data_count_reg;
reg [31:0] zero;

assign Data=(Pwrite==0)?Dma_data:32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
assign Data_bus=(DWrite==1)?Dma_data:32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;

always @(posedge  clck or posedge Reset)
begin

if(Reset) //Clear all Registers in DMA when Reset
begin
addr_reg<=0;
Data_count_reg<=0;
Data_reg<=0;
end

if(Dreq==1)
begin 
D_ack<=1;
addr_reg<=Addr;
Data_count_reg<=Data_count;
Breq<=1;
end


if(Pwrite==1) //Write mode
  begin 
  DWrite<=1;
case(Data_count)
0:begin // Transfer 1*32 bits
  Dbrust<=0;
  Addr_bus<=addr_reg;
  Dma_data<=Data;
  end  
1:begin // Transfer 2*32 bits
  Dbrust<=1;
  Addr_bus<=addr_reg;
  Dma_data<=Data;
  @(negedge clck)
  Addr_bus<=addr_reg;
  Dma_data<=Data;
  end
2:begin //Transfer 4*32 bits
  Dbrust<=2;
  Addr_bus<=addr_reg;
  Dma_data<=Data;
  @(negedge clck)
  Addr_bus<=addr_reg;
  Dma_data<=Data;
  @(negedge clck)
  Addr_bus<=addr_reg;
  Dma_data<=Data;
  @(negedge clck)
  Addr_bus<=addr_reg;
  Dma_data<=Data;
  end
endcase
end

if(Pwrite==0)//Read mode
begin
  DRead<=1;
  Dma_data<=Data_bus;
case(Data_count)
0:begin // Transfer 1*32 bits
  Dbrust<=0;
  Addr_bus<=addr_reg;
  Dma_data<=Data_bus;
  end
1:begin // Transfer 2*32 bits
  Dbrust<=1;
  Addr_bus<=addr_reg;
  Dma_data<=Data_bus;
  @(negedge clck)
  Dma_data<=Data_bus;
  end
2:begin // Transfer 4*32 bits
  Dbrust<=2;
  Addr_bus<=addr_reg;
  Dma_data<=Data_bus;
  @(negedge clck)
  Dma_data<=Data_bus;
  @(negedge clck)
  Dma_data<=Data_bus;
  @(negedge clck)
  Dma_data<=Data_bus;
  end
endcase
end

end


initial
begin
zero<=0; DWrite=0; DRead<=0; Dbrust=0; D_ack=1;
end
endmodule


module IO_1(cWrite,DWrite,cRead,DRead,Hbrust,Dbrust,Addr_bus,Data_bus,clck);
input cWrite,DWrite,cRead,DRead,clck;
input [1:0]Hbrust,Dbrust;
inout [31:0] Data_bus;
input [31:0] Addr_bus;
reg [31:0] IO_1_Data;


assign Data_bus = ((cRead==1 ||DRead==1) & (Addr_bus == 500))? IO_1_Data : 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;


always @(posedge clck)
begin

if((cRead==1 ||DRead==1) & (Addr_bus == 500)) //Read mode
begin

if(Hbrust==0 || Dbrust==0) 
  begin //Transfer 1*32 bits  
  IO_1_Data <= 1000;
  end
else if(Hbrust==1 || Dbrust==1)
  begin //Transfer 2*32 bits
  IO_1_Data <= 1000;
  @(negedge clck)
  IO_1_Data <= 2000;
  end
else if(Hbrust==2 || Dbrust==2)  
  begin //Transfer 4*32 bits
  IO_1_Data <= 1000;
  @(negedge clck)
  IO_1_Data <= 2000;
  @(negedge clck)
  IO_1_Data <= 3000;
  @(negedge clck)
  IO_1_Data <= 4000;
  end


end // end of condition 

if((cWrite==1 | DWrite==1) & (Addr_bus == 500)) //write mode
begin
if(Hbrust==0 || Dbrust==0)  
  begin //Transfer 1*32 bits
  IO_1_Data <= Data_bus;
  end
else if(Hbrust==1 || Dbrust==1) 
  begin //Transfer 2*32 bits   
  IO_1_Data <= Data_bus;
  @(negedge clck)
  IO_1_Data <= Data_bus;
  end
else if(Hbrust==2 || Dbrust==2) 
  begin //Transfer 4*32 bits
  IO_1_Data <= Data_bus;
  @(negedge clck)
  IO_1_Data <= Data_bus;
  @(negedge clck)
  IO_1_Data <= Data_bus;
  @(negedge clck)
  IO_1_Data <= Data_bus;
  end  

end //endof condition 
   

end //End always block
initial
begin
IO_1_Data=0; 
end

endmodule

module IO_2(cWrite,DWrite,cRead,DRead,Hbrust,Dbrust,Addr_bus,Data_bus,clck);
input cWrite,DWrite,cRead,DRead,clck;
input [1:0]Hbrust,Dbrust;
inout [31:0] Data_bus;
input [31:0] Addr_bus;
reg [31:0] IO_2_Data;


assign Data_bus = ((cRead==1 ||DRead==1) & (Addr_bus == 700))? IO_2_Data : 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;


always @(posedge clck)
begin

if((cRead==1 ||DRead==1) & (Addr_bus == 700)) //Read mode
begin

if(Hbrust==0 || Dbrust==0) 
  begin //Transfer 1*32 bits  
  IO_2_Data <= 1000;
  end
else if(Hbrust==1 || Dbrust==1)
  begin //Transfer 2*32 bits
  IO_2_Data <= 1000;
  @(negedge clck)
  IO_2_Data <= 2000;
  end
else if(Hbrust==2 || Dbrust==2)  
  begin //Transfer 4*32 bits
  IO_2_Data <= 1000;
  @(negedge clck)
  IO_2_Data <= 2000;
  @(negedge clck)
  IO_2_Data <= 3000;
  @(negedge clck)
  IO_2_Data <= 4000;
  end


end // end of condition 

if((cWrite==1 | DWrite==1) & (Addr_bus == 700)) //write mode
begin
if(Hbrust==0 || Dbrust==0)  
  begin //Transfer 1*32 bits
  IO_2_Data <= Data_bus;
  end
else if(Hbrust==1 || Dbrust==1) 
  begin //Transfer 2*32 bits   
  IO_2_Data <= Data_bus;
  @(negedge clck)
  IO_2_Data <= Data_bus;
  end
else if(Hbrust==2 || Dbrust==2) 
  begin //Transfer 4*32 bits
  IO_2_Data <= Data_bus;
  @(negedge clck)
  IO_2_Data <= Data_bus;
  @(negedge clck)
  IO_2_Data <= Data_bus;
  @(negedge clck)
  IO_2_Data <= Data_bus;
  end  

end //endof condition 
   

end //End always block
initial
begin
IO_2_Data=0;
end
endmodule

module memory(cWrite,DWrite,cRead,DRead,Hbrust,Dbrust,Addr_bus,Data_bus,clck);
input cWrite,DWrite,cRead,DRead,clck;
input [1:0]Hbrust,Dbrust;
inout [31:0] Data_bus;
input [31:0] Addr_bus;
reg [31:0] mem[0:3];
reg [31:0] mem_data;
assign Data_bus=((cRead==1 || DRead==1) & (Addr_bus == 800))?mem_data:32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
always@(posedge clck)
begin

if( (cRead==1 ||DRead==1) &( Addr_bus==800 ) ) //Read mode
begin

if(Hbrust==0 || Dbrust==0) 
  begin //Transfer 1*32 bits  
  mem[0] <= 1000;
  mem_data<=mem[0];
  end

if(Hbrust==1 || Dbrust==1)
  begin //Transfer 2*32 bits
  mem[0] <= 1000;
  mem_data<=mem[0];
  @(negedge clck)
  mem[1] <= 2000;
  mem_data<=mem[1];
  end

if(Hbrust==2 || Dbrust==2)  
  begin //Transfer 4*32 bits
  mem[0] <= 1000;
  mem_data<=mem[0];
  @(negedge clck)
  mem[1] <= 2000;
  mem_data<=mem[1];
  @(negedge clck)
  mem[2] <= 2000;
  mem_data<=mem[2];
  @(negedge clck)
  mem[3] <= 3000;
  mem_data<=mem[3];
  end

end

if((cWrite==1 || DWrite==1)& ( Addr_bus==800 ) ) //write mode
begin

if(Hbrust==0 || Dbrust==0)  
  begin //Transfer 1*32 bits
  mem_data <= Data_bus;
  mem[0]<=mem_data;
  end
if(Hbrust==1 || Dbrust==1)
  begin // Transfer 2*32 bits 
  mem_data <= Data_bus;
  mem[0]<=mem_data;
  @(negedge clck)
  mem_data <= Data_bus;
  mem[1]<=mem_data;
  end
if(Hbrust==2 || Dbrust==2) 
  begin //Transfer 4*32 bits
  mem_data <= Data_bus;
  mem[0]<=mem_data;
  @(negedge clck)
  mem_data <= Data_bus;
  mem[1]<=mem_data;
  @(negedge clck)
  mem_data <= Data_bus;
  mem[2]<=mem_data;
  @(negedge clck)
  mem_data <= Data_bus;
  mem[3]<=mem_data;  
  end  
end


end // always block

endmodule

module CLK(clock);
output reg clock;

initial
begin
clock=0;
end

always
begin
#10 clock=~clock;
end

endmodule



module To(Addresult);
output [31:0]Addresult;
wire Clck;
wire cWrite,DWrite,cRead,DRead;
wire dreq,d_ack,breq,back,addr,pwrite;
wire  [31:0]Addr_bus,Addr;
wire [31:0]Data_bus,Data;
wire [1:0] data_count,Hburst,Dburst;
wire [31:0]IR;
CLK myclock(Clck);
instr_memory inst(IR,Clck);
CPU cpu(Hburst,Addresult,dreq,back,data_count,Addr,pwrite,Addr_bus,cWrite,cRead,Clck,IR,d_ack,breq,Data,Data_bus); 
DMA dma(Dburst,DWrite,DRead,d_ack,breq,intr,addr_bus,dreq,Addr,data_count,Clck,reset,pwrite,Data,Data_bus,back);
IO_1 io1(cWrite,DWrite,cRead,DRead,Hburst,Dburst,Addr_bus,Data_bus,Clck);
IO_2 io2(cWrite,DWrite,cRead,DRead,Hburst,Dburst,Addr_bus,Data_bus,Clck);
memory mem(cWrite,DWrite,cRead,DRead,Hburst,Dburst,Addr_bus,Data_bus,Clck);
endmodule

