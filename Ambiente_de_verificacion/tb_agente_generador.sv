`timescale 1ns/1ps

`include "Ambiente.sv"

module tb_bus_de_datos;
    reg clk;
    parameter width = 16;
    parameter depth = 8;
    parameter drivers = 4;
    parameter bits = 1;


    //Instruccion
	int max_retardo = 10;
  
    test_agente_mbx test_agente;
  	ambiente #(.width(width), .depth(depth), .drivers(drivers), .broadcast({8{1'b1}})) prueba;
    FIFOS #(.width(width), .drivers(drivers), .bits(bits)) _FIFOS (.clk(clk));
  	instrucciones_agente instruccion;
  
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
      	$dumpfile("test.vcd");
        $dumpvars(0, DUT);
        clk = 0;
      
      	prueba = new();
      
      
        //Inicializacion de las interfaces
      
      	for (int i = 0; i < drivers; i++)begin
            prueba.driver_monitor_inst[i].fifo_in = _FIFOS;//Dentro del driver_monitor
            prueba.driver_monitor_inst[i].fifo_out = _FIFOS;
          	
        end
     	
      	prueba._FIFOS = _FIFOS; //Dentro del ambiente
          
        for (int i = 0; i < drivers; i++)begin
          prueba.driver_monitor_inst[i].inst_driver.fifo_in = _FIFOS;//Dentro del driver
          
        end
          
        for (int i = 0; i < drivers; i++)begin
          prueba.driver_monitor_inst[i].inst_monitor.fifo_out = _FIFOS;//Dentro del monitor
		  
        end 
      	
      	prueba.if_conexion;
      
        fork
            prueba.run();
        join_none
  
      
      	for (int i = 0; i < 1000; i++) begin
        	@(posedge clk);
     	 end
      
      	//Prueba 1////////////////////////////////////

      
      	//Prueba 2////////////////////////////////////
      	
      	
      	//Prueba 3////////////////////////////////////
      	
      
      	//Prueba 4/////////////////////////////////////
      	instruccion = all_for_one;
      
      	prueba.test_agente.put(instruccion);
      	
      
      	for (int i = 0; i < 10000; i++) begin
        	@(posedge clk);
     	end
      	
      	$finish;

      
    end 

endmodule