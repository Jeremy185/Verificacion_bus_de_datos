 /////////////////////////////////////////////////////////////////////////////////////////////////////////////
 // Driver/Monitor: este objeto es responsable de la interacción entre el ambiente y el la fifo bajo prueba //
 /////////////////////////////////////////////////////////////////////////////////////////////////////////////
include "driver.sv"

  class driver_padre #(parameter depth=16, width=16, driver = 4, bits=1, pkg=16, broadcast={8{1'b1}});
    trans_bus_mbx agnt_drv_mbx; 
    trans_bus_mbx drv_pdr_mbx[driver];
    trans_bus instruccion;
    driver_hijo #(.depth(depth), .width(width), .driver(driver) .bits(bits), .pkg(pkg), .broadcast=(broadcast)) hijo[driver];
    
    function new();
      for (int i = 0; i < driver ; i++ ) begin
        hijo[i] = new(i);
      end  
    endfunction
    
    task run();
      fork
        automatic j = 1;
        foreach (hijo[j])
          hijo.run();      
      join_none

      int driver_inst;
      agnt_drv_mbx.get(instruccion);
      driver_inst = instruccion.driver;
      drv_pdr_mbx[driver_inst].put(instruccion)
    



    endtask
           
	
endclass

