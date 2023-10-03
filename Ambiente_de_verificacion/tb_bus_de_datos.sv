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


    //Instruccion
    trans_bus #(.width(16), .max_drivers(4)) transaccion[3];
	  int max_retardo = 10;
	  tipo_trans tipo_spec;
  
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
      	$dumpfile("test.vcd");
        $dumpvars(0, DUT);
        clk = 0;
      
        for (int i = 0; i < drivers ; i++) begin
          agente_monitor[i]= new();
          agente_driver[i]= new();
        end
      
      	prueba = new();
      
        prueba.agente_monitor	= agente_monitor;
        prueba.agente_driver	= agente_driver;
      

        //Inicializacion de las interfaces
      
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
  
      
      	for (int i = 0; i < 1000; i++) begin
        	@(posedge clk);
     	  end
      
      
      	transaccion[0] = new();
      	transaccion[0].max_retardo = max_retardo;
      	transaccion[0].randomize();
      	tipo_spec = envio;
      	transaccion[0].tipo = tipo_spec;
     	  transaccion[0].paquete = {transaccion[0].ID, transaccion[0].payload};
      	transaccion[0].destino = transaccion[0].ID;
      
      
      	//Necesito conectar desde el agente hasta la instancia especifica del driver y el monitor

        //Meto la transaccion en el driver especifico
      	prueba.driver_monitor_inst[transaccion[0].driver-1].inst_driver.agente_driver.put(transaccion[0]); //Meto la transaccion en el driver 1

        //Meto la instruccion en el agente de destino
      	prueba.driver_monitor_inst[transaccion[0].ID].inst_monitor.agente_monitor.put(transaccion[0]);
      
      
      	for (int i = 0; i < 1000; i++) begin
        	@(posedge clk);
     	  end
      
      	
      	$finish;
      
      

      
    end 

endmodule