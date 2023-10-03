`include "driver_monitor.sv"

class ambiente #(parameter width = 16,  parameter depth = 8, parameter drivers = 4 );

    //Declaracion de los componentes del ambiente
    driver_monitor #(.width(width), .depth(depth), .drivers(drivers)) driver_monitor_inst [drivers];

    //Declaracion de la interface que conecta con el DUT
  	virtual FIFOS #(.width(width), .drivers(drivers), .bits(1)) _FIFOS;
  	
    //Declaracion de los mailboxes 
    trans_bus_mbx agente_monitor[drivers];  
    trans_bus_mbx agente_driver[drivers];

    function new();

        //Instanciacion de los mailboxes
        for (int i = 0; i < drivers; i++)begin
            agente_monitor[i] = new();
            agente_driver[i] = new();
        end
        
        //instanciacion de los componentes del ambiente
        for (int i = 0; i < drivers; i++)begin
            driver_monitor_inst[i] = new(i + 1);   //Los construyo y les digo cual es su terminal
        end
      
      	foreach(driver_monitor_inst[i]) begin//Mailboxes
          	$display ("Los mailboxes %d se conectaron",i);
          	driver_monitor_inst[i].agente_driver    = agente_driver[i];
          	driver_monitor_inst[i].agente_monitor  = agente_monitor[i];
        end

    endfunction
  
  	function if_conexion();//Conexion interfaces
      
      	for(int i = 0; i < drivers ; i++) begin
           
            driver_monitor_inst[i].fifo_in.rst = _FIFOS.rst;
           
          
          	driver_monitor_inst[i].fifo_in.pndng[0][i] = _FIFOS.pndng[0][i];
            driver_monitor_inst[i].fifo_in.D_pop[0][i] = _FIFOS.D_pop[0][i];
            driver_monitor_inst[i].fifo_out.push[0][i]= _FIFOS.push[0][i];
            driver_monitor_inst[i].fifo_out.pop[0][i]= _FIFOS.pop[0][i];
            driver_monitor_inst[i].fifo_out.D_push[0][i] = _FIFOS.D_push[0][i];
        end 
    endfunction

  
  
    virtual task run();
        $display("[%g]  El ambiente fue inicializado",$time);

        for (int i = 0; i < drivers; i++)begin //Se debe usar un for porque hay que hacer que cada uno haga run
            fork
                driver_monitor_inst[i].run();
              	@(posedge _FIFOS.clk);
            join_none
          @(posedge _FIFOS.clk);
        end
    endtask 
endclass