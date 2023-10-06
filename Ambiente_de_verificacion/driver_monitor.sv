
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
