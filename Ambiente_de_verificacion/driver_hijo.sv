 /////////////////////////////////////////////////////////////////////////////////////////////////////////////
 // Driver/Monitor: este objeto es responsable de la interacción entre el ambiente y el la fifo bajo prueba //
 /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  class driver_hijo #(parameter depth=16, width=16, driver = 4, bits=1, pkg=16, broadcast={8{1'b1}});
    virtual bus #(.drivers(driver), .bits(bits), .pkg(pkg), .broadcast(broadcast)) vif;     // Interfacevirtual del bus
    trans_bus_mbx drv_pdr_mbx; 
    trans_bus fifo_entrada[depth];      // Fifo de entrada para el bus   
    int espera;                     // Espero por transaccion 
    int id;

    function new(int terminal);
      begin
        vif.pnding[terminal];
        vif.push[terminal];
        vif.pop[terminal];
        vif.D_pop[terminal];
        vif.D_push[terminal];
        this.id = terminal;
      end;

      
    endfunction
    task run();
      $display("[%g]  El driver fue inicializado",$time);
      @(posedge vif.clk);
      vif.rst=1;
      @(posedge vif.clk);
      forever begin
        trans_bus #(.width(width)) transaction; // Crea el objeto transaccion
        vif.pnding = 0;             // Inicializa las variables
        vif.rst = 0;
        vif.D_pop = 0;
        $display("[%g] el Driver espera por una transacción",$time);
        espera = 0;
        @(posedge vif.clk);
        drv_pdr_mbx.get(transaction);                      // Pide la transaccion al mailbox que comunica con el driver padre
        while (transaction.driver =! id) begin             // Compara si le corresponde el paquete 
            @(posedge vif.clk);  
            drv_pdr_mbx.get(transaction);
        end
        fifo_entrada.push_back(transaction)                 // EN DUDA
        transaction.print("Driver: Transaccion recibida");
        $display("Transacciones pendientes en el mbx agnt_drv = %g",drv_pdr_mbx.num());  

        while(espera < transaction.retardo)begin          // Espera el tiempo de retardo definido en la transaccion
          @(posedge vif.clk);
          espera = espera+1;
          //vif.D_pop = transaction.dato;                // Creo que no va 
	end
        case(transaction.tipo)    
	  envio: begin  
      trans_bus pkg1;
	     @(posedge vif.clk);
	     vif.pnding = 1;                // Para que el DUT sepa que hay datos por enviar
       if(vif.pop == 1) begin
          pkg1 = fifo_entrada.pop_front;
          vif.D_pop = pkg1.paquete;
          transaction.tiempo = $time;
       end
	     transaction.print("Driver: Transaccion ejecutada");
	   end
	   reset: begin               // Nada más resetea el dispositivo
	     vif.rst =1;
	     transaction.tiempo = $time; 
	     transaction.print("Driver: Transaccion ejecutada");
	   end
     broadcast: begin
      trans_bus pkg1;
	     @(posedge vif.clk);
	     vif.pnding = 1;                // Para que el DUT sepa que hay datos por enviar
       if(vif.pop == 1) begin
          pkg1 = fifo_entrada.pop_front;
          vif.D_pop = pkg1.paquete;
          transaction.tiempo = $time;
       end
	     transaction.print("Driver: Transaccion ejecutada");
     end
	  default: begin
	    $display("[%g] Driver Error: la transacción recibida no tiene tipo valido",$time);
	    $finish;
	  end 
	endcase    
	@(posedge vif.clk);
      end
    endtask
  endclass

