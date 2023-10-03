`timescale 1ns / 1ps



class agente #(parameter width = 16, parameter depth = 8, parameter drivers = 4);
  
  	//Mailboxes
  	test_agente_mbx                           test_agente_mailbox;        //Mailbox para comunicar al agente con el test
  	trans_bux_mbx                             agente_driver[drivers];   	//Mailbox del agente driver
    trans_bux_mbx                             agente_monitor[drivers]; 		//Mailbox del agente monitor
    
    int                                       num_transacciones;          //Numero de transacciones
    int                                       max_retardo;                //Retardo maximo (para todas las transaccion
    
  	tipo_trans                                tpo_spec;
    logic [7:0]                               ID_spec;                    //ID especifico (para el caso de solo broadcast)
    
  	instrucciones_agente                      instruccion;
    trans_bus #(.width(width), .depth(depth)) transaccion;                //Es un ente tipo trans bus que se envia por el mailbox al driver
                                                                          //Tiene el tamaño del paquete que se va a enviar
    function new;
        num_transacciones = 100;
        max_retardo = 10;
      	ID_spec     = {8{1'b1}};
    endfunction
    
    
    task run;
        $display ("[%g] Agente fue inicializado", $time);
        
        forever begin
            #1
            if(test_agente_mailbox.num() > 0)begin
                $display ("[%g] Agente: se recibe instruccion", $time);
                test_agente_mailbox.get(instruccion);
                
        
                case(instruccion)
                    envio_aleatorio: begin  //Necesito que por cada transaccion se genere 
                        for (int i = 0; i < num_transacciones; i++) begin
                            transaccion = new();
                            transaccion.max_retardo = max_retardo;
                            transaccion.randomize();
                            tipo_spec = envio;
                            transaccion.tipo = tipo_spec;
                            transaccion.paquete = {transaccion.ID, transaccion.payload};
                            transaccion.destino = transaccion.ID;
                          
                            agente_driver[transaccion.driver - 1].put(transaccion); //Meto la transaccion en el driver especifi
                            agente_monitor[transaccion.ID].put(transaccion); //Meto la transaccion en el monitor destino 

                        end
                    end

                    broadcast_aleatorio: begin  //En este caso ya el broadcast no sera aleatorio
                                                //Porque se esta verificando que solo se haga broadcast
                        for (int i = 0; i < num_transacciones; i++) begin
                            transaccion = new();
                            transaccion.max_retardo = max_retardo;
                            transaccion.randomize();
                          	transaccion.ID = ID_spec; //Se asigno el ID de broadcast.
                            tipo_spec = broadcast;
                            transaccion.tipo = tipo_spec;
                            transaccion.paquete = {transaccion.ID, transaccion.payload};
                            transaccion.destino = transaccion.ID;
                          
                            agente_driver[transaccion.driver - 1].put(transaccion); //Meto la transaccion en el driver especifi
                          
                          	//No se mete la instruccion en el monitor.OJOOOOOOOO
                            //agente_monitor[transaccion.ID].put(transaccion); //Meto la transaccion en el monitor destino 
                        end

                    end

                    reset_half_sent: begin
                        for (int i = 0; i < num_transacciones; i++) begin
                            transaccion = new();
                            transaccion.max_retardo = max_retardo;
                            transaccion.randomize();
                            tipo_spec = reset;
                            transaccion.tipo = tipo_spec;
                            transaccion.paquete = {transaccion.ID, transaccion.payload};
                            transaccion.destino = transaccion.ID;
                          
                            agente_driver[transaccion.driver - 1].put(transaccion); //Meto la transaccion en el driver especifi
                            agente_monitor[transaccion.ID].put(transaccion); //Meto la transaccion en el monitor destino 
                        end
                    end

                    all_for_one: begin //driver, solo se pone la direccion ID como destino en todos los drivers
                        for (int i = 0; i < num_transacciones; i++) begin
                            for (int j = 0; j < drivers; j++)begin
                              transaccion = new();
                              transaccion.max_retardo = max_retardo;
                              transaccion.randomize();
                              tipo_spec = envio;
                              transaccion.tipo = tipo_spec;
                              transaccion.paquete = {transaccion.ID, transaccion.payload};
                              transaccion.destino = transaccion.ID;

                              agente_driver[transaccion.driver - 1].put(transaccion); //Meto la transaccion en el driver especifi
                              agente_monitor[transaccion.ID].put(transaccion); //Meto la transaccion en el monitor destino 
                            end 
                        end

                    end

                    all_broadcast: begin //Broadcast constante, hacer que todos hagan broadcast
                        for (int i = 0; i < num_transacciones; i++) begin
                            transaccion = new;
                            transaccion.max_retardo = max_retardo;
                            transaccion.randomize();
                            transaccion.ID  = ID_spec;   //ID = broadcast
                            tpo_spec = todos_envio;
                            transaccion.tipo = tpo_spec;
                            transaccion.print("Agente: transaccion creada");
                            agente_driver_mbx.put(transaccion);
                        end
                    end

                    one_for_one: begin //ID para uno mismo.Esto se logra con el ID aleatorio, solo se envia el dato desde ese mismo driver con su ID.
                        for (int i = 0; i < num_transacciones; i++) begin
                            transaccion = new;
                            transaccion.max_retardo = max_retardo;
                            transaccion.randomize();
                            tpo_spec = envio;   //Solo uno va a enviar por transaccion.
                            transaccion.tipo = tpo_spec;
                            transaccion.print("Agente: transaccion creada");
                            agente_driver_mbx.put(transaccion);
                        end
                    end

                    unknown_ID: begin //Nececito que el ID este fuera de los limites por ende necesito un dato de ID especifico
                        for (int i = 0; i < num_transacciones; i++) begin
                            transaccion = new;
                            transaccion.max_retardo = max_retardo;
                            transaccion.randomize(); //Ya con esto el ID desconocido es random.
                            tpo_spec = envio;        //Solo envion con un (posteriormente con todos).
                            transaccion.tipo = tpo_spec;
                            transaccion.print("Agente: transaccion creada");
                            agente_driver_mbx.put(transaccion);
                        end
                    end

                endcase
            end
                
        end
    endtask
    
endclass