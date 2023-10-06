`include "interface_transactions.sv"
class check #(parameter width = 16, parameter depth = 8, parameter drivers = 4, parameter bc = {8{1'b1}}, parameter n_transacs = 100);

trans_bus #(.width(width), .max_drivers(drivers)) transaccion;

test_agente_mbx    test_checker;  //Me necesito comunicar con el agente
trans_bus_mbx      monitor_checker[drivers]; //Me necesito comunicar con todos los monitores

  
trans_bus		   transaccion;
instrucciones_agente instruccion;

int monitor_checker_vacio;   //Determina si ya todos los mailboxes estan vacios para finalizar con el ciclo.
int i;

function new();
    this.monitor_checker_vacio = 0;
endfunction


task run;
    $display("El checker fue inicializado",$time);

    forever begin
        //test_checker.get(instruccion);
      	i = 0;
      	while(monitor_checker[i].num() > 0) begin
          if(i == drivers - 1)
            i=0;
          else
            i++;
        end
      
      	monitor_checker[i].get(transaccion);
      	$display("[%g]Checker: se recibe la transaccion del monitor %d con instruccion %s",$time, transaccion.destino, transaccion.instruccion);

      	case(transaccion.instruccion)
            envio_aleatorio:	begin //Necesito ver que en la instruccion del monitor que el paquete recibido sea igual que el ID y el payload
              
              if(transaccion.paquete == transaccion.dato_recibido && transaccion.monitor_receptor == transaccion.ID)begin
                $display("Checker: Transaccion ejecutada correctamente");
              end else begin
                $display("Checker: La transaccion no se ejecuto como se esperaba, dato recibido %b y dato enviado %b", transaccion.dato_recibido,transaccion.paquete);
              end
            end
   

       
        endcase
    end 
endtask



endclass
