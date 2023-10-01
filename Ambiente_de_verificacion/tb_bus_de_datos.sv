`include "driver_monitor.sv"

module tb_bus_de_datos;
  	reg clk;
  	
  	tipo_trans tipo_spec;
  
  	trans_bus_mbx agente_driver;
  	trans_bus_mbx agente_monitor;
  
  	driver #(.width(16), .depth(8), .drivers(4)) driver_inst;
  	monitor#(.width(16), .depth(8), .drivers(4)) monitor_inst;
  
  	trans_bus #(.width(16), .max_drivers(4)) transaccion[3];
  	int max_retardo = 10;
	
  	FIFO #(.width(16)) fifo_in (.clk(clk));
 	FIFO #(.width(16)) fifo_out (.clk(clk));
  
  	always #5 clk = ~clk;
  
  
    initial begin
		clk = 0;
      	agente_driver = new();   //Inicializacion del mailbox
      	agente_monitor = new();
      
        driver_inst = new(1);// Inicializacion del driver 
      	monitor_inst = new(1);//Inicializacion del monitor
      
      	driver_inst.agente_driver = agente_driver; 
      	driver_inst.fifo_in = fifo_in;
      
      	
      	monitor_inst.agente_monitor = agente_monitor; 
      	monitor_inst.fifo_out = fifo_out;
      	
      	//Transaccion random
      	
      	transaccion[0] = new();
      	transaccion[0].max_retardo = max_retardo;
      	transaccion[0].randomize();
      	tipo_spec = envio;
      	transaccion[0].tipo = tipo_spec;
     	transaccion[0].paquete = {transaccion[0].ID, transaccion[0].payload};
      	transaccion[0].destino = $bits(transaccion[0].ID);
      	agente_driver.put(transaccion[0]); //Meto la transaccion
      	agente_monitor.put(transaccion[0]); //Meto la transaccion en el monitor

    
      	transaccion[1] = new();
      	transaccion[1].max_retardo = max_retardo;
      	transaccion[1].randomize();
      	tipo_spec = envio;
      	transaccion[1].tipo = tipo_spec;
     	transaccion[1].paquete = {transaccion[1].ID, transaccion[1].payload};
      	transaccion[1].destino = $bits(transaccion[1].ID);
      	agente_driver.put(transaccion[1]); //Meto la transaccion
      	agente_monitor.put(transaccion[1]); //Meto la transaccion en el monitor

      	transaccion[2] = new();
      	transaccion[2].max_retardo = max_retardo;
      	transaccion[2].randomize();
      	tipo_spec = envio;
      	transaccion[2].tipo = tipo_spec;
     	transaccion[2].paquete = {transaccion[2].ID, transaccion[2].payload};
      	transaccion[2].destino = $bits(transaccion[2].ID);
      	agente_driver.put(transaccion[2]); //Meto la transaccion
      	agente_monitor.put(transaccion[2]); //Meto la transaccion en el monitor
		
      	fork
        	driver_inst.run();
          	monitor_inst.run();
        join_none
		
      	@(posedge clk);
        fifo_out.push = 0;
     	while (driver_inst.espera < transaccion[0].retardo)begin
            fifo_out.push = 0;
          	@(posedge clk);
        end
        
     	@(posedge clk);
        fifo_out.push = 1;
      	fifo_out.D_push = transaccion[0].paquete;
        while (driver_inst.espera == transaccion[0].retardo)begin
            fifo_out.push = 1;
          	@(posedge clk);
        end
		
      	@(posedge clk);
        fifo_out.push = 0;
        while (driver_inst.espera < transaccion[1].retardo)begin
            fifo_out.push = 0;
          	@(posedge clk);
        end
		
      	@(posedge clk);
        fifo_out.push = 1;
      	fifo_out.D_push = transaccion[1].paquete;
        while (driver_inst.espera == transaccion[1].retardo)begin
            fifo_out.push = 1;
          	@(posedge clk);
        end

      	@(posedge clk);
        fifo_out.push = 0;
        while (driver_inst.espera < transaccion[2].retardo)begin
            fifo_out.push = 0;
          	@(posedge clk);
        end
		
      	@(posedge clk);
        fifo_out.push = 1;
      	fifo_out.D_push = transaccion[2].paquete;
        while (driver_inst.espera == transaccion[2].retardo)begin
            fifo_out.push = 1;
          	@(posedge clk);
        end
      
    
      
    end
  
  	always@(posedge clk) begin
    		if ($time > 100000)begin
      		$display("Test_bench: Tiempo límite de prueba en el test_bench alcanzado");
      		$finish;
    		end
  		end
endmodule