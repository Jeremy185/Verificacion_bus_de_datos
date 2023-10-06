`include "Agente_generador.sv"
class ambiente #(parameter width = 16,  parameter depth = 8, parameter drivers = 4, parameter bc = {8{1'b1}}, parameter n_transacs = 100, parameter max_retardo = 10);

    //Declaracion de los componentes del ambiente
    driver_monitor #(.width(width), .depth(depth), .drivers(drivers)) driver_monitor_inst [drivers];
  	agente #(.width(width), .depth(depth), .drivers(drivers), .bc(bc), .n_transacs(n_transacs), .mx_retardo(max_retardo)) agente_inst;
  	check #(.width(width), .depth(depth), .drivers(drivers), .bc(bc), .n_transacs(n_transacs)) checker_inst;

    //Declaracion de la interface que conecta con el DUT
  	virtual FIFOS #(.width(width), .drivers(drivers), .bits(1)) _FIFOS;
  	
    //Declaracion de los mailboxes 
    trans_bus_mbx agente_monitor[drivers];  
    trans_bus_mbx agente_driver[drivers];
    trans_bus_mbx monitor_checker[drivers]; //Mailboxes para poder comunicar todos los monitores con el checker 
  
    test_agente_mbx test_agente;
    test_agente_mbx test_checker; //Mailbox para poder comunicar al agente con el checker
    

    function new();

        //Instanciacion de los mailboxes
        for (int i = 0; i < drivers; i++)begin
            agente_monitor[i] = new();
            agente_driver[i] = new();
        end
        
        for (int i = 0; i < drivers; i++)begin
            monitor_checker[i] = new();
        end

        test_agente = new();
        test_checker = new();


        //instanciacion de los componentes del ambiente
        for (int i = 0; i < drivers; i++)begin
          	driver_monitor_inst[i] = new(i);   //Los construyo y les digo cual es su terminal
        end
        
        agente_inst = new();
        checker_inst = new();
      
        for(int i = 0; i < drivers; i++) begin//Mailboxes
          	$display ("Los mailboxes %d se conectaron",i);
          
            //Conecto los drivers y monitores con el agente
          	driver_monitor_inst[i].inst_driver.agente_driver    = agente_driver[i];
          	driver_monitor_inst[i].inst_monitor.agente_monitor  = agente_monitor[i];
            agente_inst.agente_driver[i] = agente_driver[i];
            agente_inst.agente_monitor[i] = agente_monitor[i];

            agente_inst.test_agente = test_agente; //Conecto el test con el agente.
            checker_inst.test_checker = test_checker;//Conecto el test con el checker

            //Conexion de los monitores con el checker
            driver_monitor_inst[i].inst_monitor.monitor_checker = monitor_checker[i];
            checker_inst.monitor_checker[i] = monitor_checker[i];
        
          end

    endfunction
  
  	function if_conexion;//Conexion interfaces
      
      for(int i = 0 ; i < drivers ; i++) begin
            driver_monitor_inst[i].fifo_in.rst = _FIFOS.rst;
          	driver_monitor_inst[i].fifo_in.pndng[0][i] = _FIFOS.pndng[0][i];
            driver_monitor_inst[i].fifo_in.D_pop[0][i] = _FIFOS.D_pop[0][i];
            driver_monitor_inst[i].fifo_out.push[0][i]= _FIFOS.push[0][i];
        	driver_monitor_inst[i].fifo_out.pop[0][i] = _FIFOS.pop[0][i];
            driver_monitor_inst[i].fifo_out.D_push[0][i] = _FIFOS.D_push[0][i];
        end 
    endfunction

  
  
    virtual task run();
        $display("[%g]  El ambiente fue inicializado",$time);
		fork
          for (int i = 0; i < drivers; i++)begin //Se debe usar un for porque hay que hacer que cada uno haga run
              driver_monitor_inst[i].run();
              @(posedge _FIFOS.clk);
          end
          
          for(int i = 0; i < 100 ; i++)begin
            @(posedge _FIFOS.clk);
          end
          agente_inst.run();
          //checker_inst.run();
          
          
          
          

        join_none
      
    endtask 
endclass