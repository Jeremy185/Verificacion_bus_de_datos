
//Driver/monitor

class monitor #(parameter width = 16, parameter depth = 8, parameter drivers = 4);
    trans_bus_mbx agente_monitor;
    virtual FIFO #(.width(width)) fifo_out;

    trans_bus cola_out[$]; //Declaracion del queue del monitor
    int id;

    function new(int terminal);
        this.id = terminal;
        cola_out.delete();
    endfunction

    task run();
        $display("[%g] La FIFO de salida %d fue inicializada",$time, id );
        
    endtask
endclass

class driver #(parameter width = 16, parameter depth = 8, parameter drivers = 4);
    trans_bus_mbx agente_driver;
    virtual FIFO #(.width(width)) fifo_in;  //declaracion del queue del driver    
    trans_bus cola_in[$];
    
    
    int espera;                     //Variable que hace el retardo
    int id;                         //Valor del id
    function new(int terminal);
        this.id = terminal;         //Da el valor correspondiente a la terminal
        cola_in.delete();           //Inicializa la cola
    endfunction 

    task run();
        $display("[%g] El driver %d fue inicializado",$time, id );
        @(posedge fifo_in.clk);
        fifo_in.rst = 1;
        @(posedge fifo_in.clk);

        forever begin 
            trans_fifo #(.width(width), .max_drivers(drivers)) transaccion;
            fifo_in.pnding = 0;   //Pongo la señal de pending que va a la entrada del dut en 0
            fifo_in.D_pop  ='0;  //Pongo todos los bits del paquete en 0 bits 

            $display("[%g]El driver %d espera por transaccion", $time, id);
            espera = 0;

            @(posedge fifo_in.clk);
            agente_driver.get(transaccion); //obtengo la transaccion del mailbox
            transaccion.print("Driver: Transaccion recibida");
            $display("Transacciones pendientes en el mailbox agente_driver %d = %g",agente_driver.num());
            
            while(espera < transaccion.retardo)begin //Hago un retardo
                @(posedge fifo_in.clk);
                espera = espera + 1;
            end

            cola_in.push_back(transaccion); //Meto el dato dentro del queue

            case(transaccion.tipo)
                envio: begin
                    fifo_in.D_pop = cola_in.pop_front;
                    @(posedge fifo_in.clk);
                    fifo_in.pnding = 1;             //Ya el dut puede tomar el dato
                end
            endcase
            @(posedge fifo_in.clk);
        end

    endtask

endclass

class driver_monitor #(parameter width = 16, parameter depth = 8);

endclass