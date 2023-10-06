`timescale 1ns/1ps
`include "Library.sv"
`include "interface_transactions.sv"


class monitor #(parameter width = 16, parameter depth = 8, parameter drivers = 4);
    
trans_bus_mbx agente_monitor;
trans_bus_mbx monitor_checker;

virtual FIFOS #(.width(width), .drivers(drivers), .bits(1)) fifo_out;

bit [width-1:0] cola_out[$]; //Declaracion del queue del monitor que solo almacenas paquetes recibidos
int   id;   //El id propio de cada terminal en logic para poderlo comparar con los ID de los paquetes


function new(int terminal);
    this.id = terminal;
    cola_out.delete();
endfunction

task run();
    $display("[%g] La FIFO de salida %d fue inicializada",$time, id );
   @(posedge fifo_out.clk);
  
    fifo_out.rst = 1;
    @(posedge fifo_out.clk);
  
    forever begin
      trans_bus #(.width(width), .max_drivers(drivers)) transaccion;
      fifo_out.rst = 0;
      $display("[%g] La FIFO de salida %d espera por una transacción",$time, id);

      agente_monitor.get(transaccion); //Tengo que meter todas las transacciones de los demas drivers en este mailbox en el caso de que se haga un all for one 
      //Tal vez podria quitar el case y hacer que el monitor este esperando un dato en cualquier momento, y que cuando se reciba entonces ya guarde el dato recibido
      //Dentro de la transaccion para que luego el checker verifique si esta correcto o no.


      transaccion.print_out("FIFO de salida: Transaccion recibida");
      $display("Transacciones pendientes en el mailbox agente_monitor %d = %g",id,agente_monitor.num());
  

      
      case(transaccion.tipo) //DATO EN NEGEDGE
        
        broadcast: begin		
          
            while(fifo_out.push[0][id]== 0 && transaccion.driver != transaccion.ID)begin
                @(posedge fifo_out.clk);
            end

          cola_out.push_back(fifo_out.D_push[0][id]); //Aqui cuando detecta una señal de push entonces envia el dato.
            transaccion.dato_recibido = fifo_out.D_push[0][id];//Guardo el dato que se recibio
            transaccion.monitor_receptor = id - 1;//Seteo el monitor que lo recibio
    transaccion.tiempo_recibido = $time;
            monitor_checker.put(transaccion);
            $display("FIFO out %d recibio el dato %b ", id, fifo_out.D_push[0][id]);
        end
        
        envio: begin		
            while(fifo_out.push[0][id]== 0 && transaccion.driver != transaccion.ID)begin
                @(posedge fifo_out.clk);
            end

          cola_out.push_back(fifo_out.D_push[0][id]); //Aqui cuando detecta una señal de push entonces envia el dato.
            transaccion.dato_recibido = fifo_out.D_push[0][id];
            transaccion.monitor_receptor = id - 1;
    transaccion.tiempo_recibido = $time;
            monitor_checker.put(transaccion);
            $display("FIFO out %d recibio el dato %b ", id, fifo_out.D_push[0][id]);
        end
        
      
        reset: begin		
            while(fifo_out.push[0][id]== 0 && transaccion.driver != transaccion.ID)begin
                @(posedge fifo_out.clk);
            end

          cola_out.push_back(fifo_out.D_push[0][id]); //Aqui cuando detecta una señal de push entonces envia el dato.
            transaccion.dato_recibido = fifo_out.D_push[0][id];
            transaccion.monitor_receptor = id - 1;
    transaccion.tiempo_recibido = $time;
            monitor_checker.put(transaccion);
            $display("FIFO out %d recibio el dato %b ", id, fifo_out.D_push[0][id]);
        end
        
        default: begin
          $display("[%g] Monitor Error: la transacción recibida no tiene tipo valido",$time);
          $finish;
    end 
    endcase
      
      
        @(posedge fifo_out.clk);
    end
endtask
endclass

class driver #(parameter width = 16, parameter depth = 8, parameter drivers = 4); //Funcionando
  trans_bus_mbx agente_driver;
  virtual FIFOS #(.width(width), .drivers(drivers), .bits(1)) fifo_in;  //declaracion del queue del driver    
  trans_bus cola_in[$];


  int espera;                     //Variable que hace el retardo
  int id;                         //Valor del id

  int retardo;
  function new(int terminal);
    this.id = terminal;         //Da el valor correspondiente a la terminal
    cola_in.delete();           //Inicializa la cola
  endfunction 

  task run();
      $display("[%g] La FIFO de entrada %d fue inicializada",$time, id );
      fifo_in.rst = 1;
      fifo_in.pndng[0][id] = 0;
      fifo_in.D_pop[0][id]  ='0;
  
    forever begin 
        trans_bus #(.width(width), .max_drivers(drivers)) transaccion;
      
        //Pongo la señal de pending que va a la entrada del dut en 0
        //fifo_in.D_pop[0][id-1]  ='0;  //Pongo todos los bits del paquete en 0 bits 
        fifo_in.rst    = 0;  //Pongo el reset en 0.
      
        $display("[%g]El driver %d espera por transaccion", $time, id);
        espera = 0;
        retardo = 0;
    
        
        agente_driver.get(transaccion); //obtengo la transaccion del mailbox
        transaccion.print_in("Driver: Transaccion recibida");
        $display("Transacciones pendientes en el mailbox agente_driver %d = %g",id,agente_driver.num());
        
        while(espera < transaccion.retardo)begin //Hago un retardo/////////
            @(posedge fifo_in.clk);
            espera = espera + 1;
        end
      
        if(agente_driver.num()==0)begin
            fifo_in.pndng[0][id] = 0;
        end else begin
            fifo_in.pndng[0][id] = 1;
        end
      
        transaccion.tiempo_envio = $time; //Le pongo el tiempo en el que se envio
        cola_in.push_back(transaccion); //Meto el dato dentro del que
      
        
        case(transaccion.tipo)
            broadcast: begin
                fifo_in.D_pop[0][id] = cola_in.pop_front.paquete;
                fifo_in.pndng[0][id] = 1;
                @(posedge fifo_in.clk);
                @(posedge fifo_in.clk);
                @(posedge fifo_in.clk);
                fifo_in.D_pop[0][id] = '0;
                fifo_in.pndng[0][id] = 0;
            end
            envio: begin
              $display("Entro driver %d", id);
              while(fifo_in.pop[0][id] == 0)begin
                @(posedge fifo_in.clk);
              end
              
              fifo_in.D_pop[0][id] = cola_in.pop_front.paquete;
              
            end
          
            reset: begin
                fifo_in.D_pop[0][id] = cola_in.pop_front.paquete;
                fifo_in.pndng[0][id] = 1;
                @(posedge fifo_in.clk);
                @(posedge fifo_in.clk);
                @(posedge fifo_in.clk);
                fifo_in.D_pop[0][id] = '0;
                fifo_in.pndng[0][id] = 0;
                @(posedge fifo_in.clk);
                @(posedge fifo_in.clk);

                fifo_in.rst = 1;
              
                @(posedge fifo_in.clk);

                fifo_in.rst = 0;
            end
            default: begin
              $display("[%g] Driver Error: la transacción recibida no tiene tipo valido",$time);
              $finish;
            end 
          
        endcase
        @(posedge fifo_in.clk);
    end

  endtask

endclass




class driver_monitor #(parameter width = 16, parameter depth = 8, parameter drivers = 4);

//Componentes
monitor #(.width(width), .depth(depth), .drivers(drivers)) inst_monitor;
driver #(.width(width), .depth(depth), .drivers(drivers)) inst_driver;

//Interfaces 
virtual FIFOS #(.width(width), .drivers(drivers), .bits(1)) fifo_in;
virtual FIFOS #(.width(width), .drivers(drivers), .bits(1)) fifo_out;



//Mailboxes
trans_bus_mbx agente_monitor;
trans_bus_mbx agente_driver;
int id;

function new(int terminal);
    this.id = terminal;
    //instanciacion del driver y el monitor
    inst_driver = new(terminal);
    inst_monitor = new(terminal);
  
    agente_monitor = new();
    agente_driver = new();
  
    //conexion del mailbox
    inst_monitor.agente_monitor = agente_monitor;
    inst_driver.agente_driver = agente_driver;

  
    //Conexion de la interface
    $display("El driver y el monitor %d se construyeron",id);
    inst_monitor.fifo_out = fifo_out;
    inst_driver.fifo_in = fifo_in;
endfunction 


virtual task run();  //Aqui corro en paralelo el driver y el monitor (en el ambiente se corre en paralelo solo los drivers_monitores)
    $display("[%g] El driver_monitor fue inicializado %d", $time, this.id);
    fork
      inst_driver.run();
        inst_monitor.run();
    join_none
endtask

endclass


class agente #(parameter width = 16, parameter depth = 8, parameter drivers = 4, parameter bc = {8{1'b1}}, parameter n_transacs = 100, parameter mx_retardo = 10);
  
  	//Mailboxes
  	test_agente_mbx                           test_agente;        //Mailbox para comunicar al agente con el test

  	//Estos van directamente conectados con los mailbox driver y monitor
  	trans_bus_mbx                             agente_driver[drivers];   	//Mailbox del agente driver
    trans_bus_mbx                             agente_monitor[drivers]; 		//Mailbox del agente monitor
    
    int                                       num_transacciones;          //Numero de transacciones
    int                                       max_retardo;                //Retardo maximo (para todas las transaccion
    
  	tipo_trans                                tpo_spec;
  
    logic [7:0]                               ID_spec;                    //ID especifico (para el caso de solo broadcast)
    
  	instrucciones_agente                      instruccion;
    trans_bus #(.width(width), .depth(depth)) transaccion;                //Es un ente tipo trans bus que se envia por el mailbox al driver
                                                                          //Tiene el tamaño del paquete que se va a enviar
    function new;
        num_transacciones = n_transacs;
        max_retardo = max_retardo;
      	ID_spec     = bc;
    endfunction
    
 
    task run;
        $display ("[%g] Agente fue inicializado", $time);
        
        forever begin
            #1
            if(test_agente.num() > 0)begin
                $display ("[%g] Agente: se recibe instruccion", $time);
                test_agente.get(instruccion);
                
        
                case(instruccion)
                    envio_aleatorio: begin  //Necesito que por cada transaccion se genere 
                        for (int i = 0; i < num_transacciones; i++) begin
                            transaccion = new();
                            transaccion.max_retardo = max_retardo;
                            transaccion.randomize();
                            tpo_spec = envio;
                            transaccion.tipo = tpo_spec;
                          	transaccion.instruccion = instruccion;
                            transaccion.paquete = {transaccion.ID, transaccion.payload};
                            transaccion.destino = transaccion.ID;
                          
                          	agente_driver[transaccion.driver].put(transaccion); //Meto la transaccion en el driver especifico
                          	agente_monitor[transaccion.ID].put(transaccion); //Meto la transaccion en el monitor destino 
                          	$display("Driver:%d",transaccion.driver);

                        end
                    end

                    broadcast_aleatorio: begin  //En este caso ya el broadcast no sera aleatorio
                                                //Porque se esta verificando que solo se haga broadcast
                        
                      for (int i = 0; i < num_transacciones; i++) begin
                            transaccion = new();
                            transaccion.max_retardo = max_retardo;
                            transaccion.randomize();
                          	transaccion.ID = ID_spec; //Se asigno el ID de broadcast.
                            tpo_spec = broadcast;
                            transaccion.tipo = tpo_spec;
                        	transaccion.instruccion = instruccion;
                            transaccion.paquete = {transaccion.ID, transaccion.payload};
                            transaccion.destino = transaccion.ID;
                            
                            agente_driver[transaccion.driver].put(transaccion); //Meto la transaccion en el driver especifico
                          
                        	for (int j = 0; j < drivers ; j++)begin  //Tengo que meter una instruccion dentro de cada monitor para que puedan recibir el broadcast
                              	agente_monitor[j].put(transaccion); //Meto la transaccion en el monitor destino 
                            end   
                        end
                      
                      
                      	//En este caso todos los monitores reciben la instruccion para que sepan que deben recibir el dato, ademas en el checker la forma de revisar que este
                      //Correcto es viendo que todos recibieron el mismo dato que esta en la instruccion

                    end

                    reset_half_sent: begin
                        for (int i = 0; i < num_transacciones; i++) begin
                            transaccion = new();
                            transaccion.max_retardo = max_retardo;
                            transaccion.randomize();
                            tpo_spec = reset;
                            transaccion.tipo = tpo_spec;
                          	transaccion.instruccion = instruccion;
                            transaccion.paquete = {transaccion.ID, transaccion.payload};
                            transaccion.destino = transaccion.ID;
                          
                            agente_driver[transaccion.driver].put(transaccion); //Meto la transaccion en el driver especifico
                          	agente_monitor[transaccion.ID].put(transaccion); //Meto la transaccion en el monitor destino 
                          
                          	
                          	//El primero es el unico que puede hacer reset
                          	tpo_spec = reset;
                          	transaccion.tipo = tpo_spec;
                          	agente_driver[0].put(transaccion); //Meto la transaccion en el driver especifico
                          	
                        end
                    end

                  
                    all_for_one: begin //driver, solo se pone la direccion ID como destino en todos los drivers con el mismo retardo, excepto en el destino, y en el monitor hay que
                      					//poner la cantidad de transacciones para que reciba todos los paquetes enviados (en el monitor de destino
                      
                        for (int i = 0; i < num_transacciones; i++) begin //En el primer loop genero la instruccion
                          
                            transaccion = new();
                            transaccion.max_retardo = max_retardo;
                            transaccion.randomize();
                            tpo_spec = envio;
                            transaccion.tipo = tpo_spec;
                          	transaccion.instruccion = instruccion;
                            transaccion.paquete = {transaccion.ID, transaccion.payload};
                            transaccion.destino = transaccion.ID;

                            for (int j = 0; j < drivers; j++) begin//En el segundo loop meto la instruccion dentro de los drivers que haran el envio excepto en el destino
                                transaccion.payload = $random % 256; //Randomizo solamente el payload
								transaccion.paquete = {transaccion.ID, transaccion.payload};
                            	transaccion.destino = transaccion.ID;
                              
                                if (transaccion.ID != j)begin //Mientras j sea diferente al driver de destino
                                    transaccion.driver = j + 1; //Seteo la fuente de envio.
                                    agente_driver[j].put(transaccion); //Meto la transaccion en el driver que no sea el destino
                                    agente_monitor[transaccion.ID].put(transaccion); //Meto la transaccion en el monitor destino con el cambio de driver para saber de donde provino
                              end 

                          end
                          
                        end

                    end
                  
                  

                    all_broadcast: begin //Nececito que todos hagan el broadcast al mismo tiempo, entonces el ID de todos sera el mismo, en este caso todos van a recibir un dato
                      					 //El numero de veces dependiento de la cantidad de drivers 
                                          //Entonces necesito meter en todos los monitores una cantidad de instrucciones iguales a la cantidad de drivers 
                                          //Cada driver tendra un payload distinto por lo tanto se tendra que hacer uno random por cada driver 
                        
                      for (int i = 0; i < num_transacciones; i++) begin //En el primer loop genero la instruccion
                          transaccion = new();
                          transaccion.max_retardo = max_retardo;
                          transaccion.randomize();
                          transaccion.ID = ID_spec; //Se asigno el ID de broadcast.
                          tpo_spec = broadcast;
                          transaccion.tipo = tpo_spec;
                          transaccion.instruccion = instruccion;
                          transaccion.paquete = {transaccion.ID, transaccion.payload};
                          transaccion.destino = transaccion.ID;

                          for (int j = 0; j < drivers; j++) begin

                              transaccion.payload = $random; //Randomizo solamente el payload
                              transaccion.paquete = {transaccion.ID, transaccion.payload};

                              transaccion.driver = j + 1; //Seteo la fuente de envio.
                              agente_driver[j].put(transaccion); //Meto la transaccion en el driver que no sea el destino
                              agente_monitor[j].put(transaccion); //Meto la transaccion en el monitor destino con el cambio de driver para saber de donde provino

                              //Para verificarlo en el checker reviso las queue de todos los monitores y tienen que concordar con los datos recibidos.
                            
                          end 

                      end
                          
					end

                    one_for_one: begin //Cada driver se enviara el dato a su mismo monitor, debo setear el driver como el mismo y el ID tambien pero el payload si es aleatorio
                    	for (int i = 0; i < num_transacciones; i++) begin //En el primer loop genero la instruccion
                          transaccion = new();
                          transaccion.max_retardo = max_retardo;
                          transaccion.randomize();
                          tpo_spec = envio;
                          transaccion.tipo = tpo_spec;
                          transaccion.instruccion = instruccion;
                          transaccion.paquete = {transaccion.ID, transaccion.payload};
                          transaccion.destino = transaccion.ID;

                          for (int j = 0; j < drivers; j++) begin//En el segundo loop meto la instruccion dentro de los drivers que haran el envio excepto en el destino

                            transaccion.payload = $random % 256; //Randomizo solamente el payload
                            transaccion.ID = j;				
                            transaccion.paquete = {transaccion.ID, transaccion.payload};
                    
                            transaccion.driver = j + 1; //Seteo la fuente de envio.
                            agente_driver[j].put(transaccion); //Meto la transaccion en el driver que no sea el destino
                            agente_monitor[j].put(transaccion); //Meto la transaccion en el monitor destino con el cambio de driver para saber de donde provino


                          end
                          
                        end
                      
                    end

                    unknown_ID: begin //Nececito que el ID este fuera de los limites por ende necesito un dato de ID especifico
                        for (int i = 0; i < num_transacciones; i++) begin
                            transaccion = new();
                            transaccion.max_retardo = max_retardo;
                            transaccion.randomize();
                            tpo_spec = envio;
                          	transaccion.tipo = tpo_spec;
                          	transaccion.instruccion = instruccion;
                          	transaccion.paquete = {transaccion.ID_unknown, transaccion.payload}; //Coloco el ID fuera de los rangos
                            transaccion.destino = transaccion.ID_unknown;
                          
                            agente_driver[transaccion.driver].put(transaccion); //Meto la transaccion en el driver especifico

                          	for (int j = 0; j < drivers; j++)begin //Meto una transaccion en todos los monitores para que esten listos para recibir un dato.
                              	agente_monitor[j].put(transaccion); //Meto la transaccion en el monitor destino, para este caso confirmo que el monitor debe estar
                                                                               //constantemente esperando por un dato 
                            end 
                            
                        end
                    end

                endcase
            end
                
        end
    endtask
    
endclass


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



class test#(parameter width = 16, parameter depth = 8, parameter drivers = 4, parameter bc ={8{1'b1}});

    //Mailboxes
    test_agente_mbx test_agente; //Envia la instruccion al agente
    test_agente_mbx test_checker; //Envia la instruccion al checker

    parameter num_transacciones = 50;
    parameter max_retardo = 10;
    instrucciones_agente instruccion;

    //Definicion del ambiente de la prueba
  	ambiente #(.width(width),  .depth(depth), .drivers(drivers), .broadcast(bc), .n_transacs(num_transacciones), .max_retardo(max_retardo)) ambiente_inst;

    //Definicion de la interfaz
    virtual FIFOS #(.width(width), .drivers(drivers), .bits(1)) _FIFOS;


    //Definicion de las condiciones iniciales del test
    function new;
        //instanciacion de los mailboxes
        test_agente = new();
        test_checker = new();
      	ambiente_inst = new();
      
      
        //Definicion y conexion del ambiente
        ambiente_inst.test_agente = test_agente;
        ambiente_inst.agente_inst.test_agente = test_agente;

        ambiente_inst.test_checker = test_checker;
        ambiente_inst.checker_inst.test_checker = test_checker;

        //Definino el retardo maximo y el numero de transacciones desde aqui
        ambiente_inst.agente_inst.num_transacciones = num_transacciones;
        ambiente_inst.agente_inst.max_retardo = max_retardo;


    endfunction

    task run;
        $display("[%g] El test fue inicializado", $time);

        fork
            ambiente_inst.run();
        join_none
		
        instruccion = envio_aleatorio;
       	test_agente.put(instruccion);
        test_checker.put(instruccion);
        $display("[%g] Test: Enviada primera instruccion al agente de envio aleatorio con num_transacciones %g", $time, num_transacciones);
      
      	//instruccion = all_for_one;
        //test_agente.put(instruccion);
        //test_checker.put(instruccion);
        //$display("[%g] Test: Enviada primera instruccion al agente de envio aleatorio con num_transacciones %g", $time, num_transacciones);
      
     

    endtask



endclass


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