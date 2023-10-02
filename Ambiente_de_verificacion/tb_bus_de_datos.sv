// Code your testbench here
// or browse Examples
// Code your testbench here
// or browse Examples
`timescale 1ns/1ps
`include "Ambiente.sv"

module tb_bus_de_datos;
    reg clk;
    parameter width = 16;
    parameter depth = 8;
    parameter drivers = 4;
    parameter bits = 1;

    ambiente #(.width(width), .depth(depth), .drivers(drivers)) prueba;
    FIFOS #(.width(width), .drivers(drivers), .bits(bits)) _FIFOS (.clk(clk));
  
  	trans_bus_mbx agente_monitor[drivers];  
    trans_bus_mbx agente_driver[drivers];
  
  	always #5 clk = ~ clk;

    bs_gnrtr_n_rbtr  #(.bits(bits), .drvrs(drivers), .pckg_sz(width), .broadcast({8{1'b1}})) DUT (
        .clk        (_FIFOS.clk),
        .reset      (_FIFOS.rst),
        .pndng      (_FIFOS.pndng),
        .push       (_FIFOS.push),
        .pop        (_FIFOS.pop),
        .D_pop      (_FIFOS.D_pop),
        .D_push     (_FIFOS.D_push)
    );

    initial begin
        clk = 0;
      
      	prueba = new();
      
      	for (int i = 0; i< drivers; i++)begin  //Conexion de los mailbox
          	prueba.agente_monitor[i] = agente_monitor[i];
          	prueba.agente_driver[i] = agente_driver[i];
        end
      
      	for (int i = 0; i < drivers; i++)begin
            prueba.driver_monitor_inst[i].fifo_in = _FIFOS;//Dentro del driver_monitor
            prueba.driver_monitor_inst[i].fifo_out = _FIFOS;
          	
        end
     	
      	prueba._FIFOS = _FIFOS; //Inicializacion de las interfaces
          
        for (int i = 0; i < drivers; i++)begin
          prueba.driver_monitor_inst[i].inst_driver.fifo_in = _FIFOS;//Dentro del driver y del monitor
          
        end
          
        for (int i = 0; i < drivers; i++)begin
          prueba.driver_monitor_inst[i].inst_monitor.fifo_out = _FIFOS;
		  
        end 
      	
      	prueba.if_conexion();
      	
      
        
        fork
            prueba.run();
        join_none
     
      
      $display("ID solo para revisar %d", prueba.driver_monitor_inst[2].id);
      
    end 

endmodule