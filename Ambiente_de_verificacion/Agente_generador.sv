`include "driver_monitor.sv"

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
