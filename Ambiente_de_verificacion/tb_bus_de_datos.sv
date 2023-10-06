`timescale 1ns/1ps

`include "Test.sv"

module tb_bus_de_datos;
    reg clk;
    parameter width = 16;
    parameter depth = 8;
    parameter drivers = 4;
    parameter bits = 1;


    //Instruccion
  	test #(.width(width), .depth(depth), .drivers(drivers), .broadcast({8{1'b1}})) test_inst;
    FIFOS #(.width(width), .drivers(drivers), .bits(bits)) _FIFOS (.clk(clk));
  
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

      	test_inst = new();
        
        test_inst._FIFOS = _FIFOS;
      
        //Inicializacion de las interfaces
      
      	for (int i = 0; i < drivers; i++)begin
            test_inst.ambiente_inst.driver_monitor_inst[i].fifo_in = _FIFOS;//Dentro del driver_monitor
            test_inst.ambiente_inst.driver_monitor_inst[i].fifo_out = _FIFOS;
          	
        end
     	
      	test_inst.ambiente_inst._FIFOS = _FIFOS; //Dentro del ambiente
          
        for (int i = 0; i < drivers; i++)begin
            test_inst.ambiente_inst.driver_monitor_inst[i].inst_driver.fifo_in = _FIFOS;//Dentro del driver
          
        end
          
        for (int i = 0; i < drivers; i++)begin
            test_inst.ambiente_inst.driver_monitor_inst[i].inst_monitor.fifo_out = _FIFOS;//Dentro del monitor
		  
        end 
      	
        test_inst.ambiente_inst.if_conexion;
      
        fork
            test_inst.run();
        join_none
  
      
      	for (int i = 0; i < 100; i++) begin
        	@(posedge clk);
        end
      	
      	#500000;
        $display("[%g]  Test: Se alcanza el tiempo límite de la prueba",$time);
        #20
        $finish;


      
    end 

endmodule