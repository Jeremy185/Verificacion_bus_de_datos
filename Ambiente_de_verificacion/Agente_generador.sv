`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////////////////////
// Agente/Generador: Este bloque se encarga de generar las secuencias de eventos para el driver //
// 
//////////////////////////////////////////////////////////////////////////////////////////////////


class agente #(parameter width = 16, depth = 8);
    test_agente_mbx test_agente_mailbox;        //Mailbox para comunicar al agente con el test
    trans_bux_mbx trans_bus_mailbox ;           //Comunica al agente con el driver (son varios drivers)
    
    int max_transacciones;                      //Numero de transacciones a realizar.(en total)
    
    
    int max_retardo;                            //Retardo maximo (para todas las transaccion
    instrucciones_agente instruccion;
    
 
    function new;
        max_transacciones = 200;
        max_retardo = 10;
    endfunction
    
    
    task run();
        $display ("[%g] Agente fue inicializado", $time);
        
        forever begin
            #1
            if(test_agente_mailbox.num() > 0)begin
                $display ("[%g] Agente: se recibe instruccion", $time);
                test_agente_mailbox.get(instruccion);
                
                
                case(instruccion)
                    envio_aleatorio:
                        
                    broadcast_aleatorio: 
                    reset_half_sent: 
                    all_for_one: 
                    all_broadcast: 
                    one_for_one: 
                    unknown_ID:                
                endcase
            end
                
        end
    
    
    
    endtask
    
endclass

