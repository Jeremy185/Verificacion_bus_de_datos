`timescale 1ns/1ps
`include "fifo.sv"

/////////////////////////////////////////////////////////////////////////////////////////
//Transacción: este objeto representa las transacciones que entran y salen de la fifo. //
/////////////////////////////////////////////////////////////////////////////////////////
class trans_fifo #(parameter width = 16);
  int retardo; // tiempo de retardo en ciclos de reloj que se debe esperar antes de ejecutar la transacción
  bit[width-1:0] dato; // este es el dato de la transacción
  int tiempo; //Representa el tiempo  de la simulación en el que se ejecutó la transacción 
  string tipo; // lectura, escritura, reset;
  
  function new(int ret =0,bit[width-1:0] dto=0,int tmp = 0, string tpo = "lectura");
    this.retardo = ret;
    this.dato = dto;
    this.tiempo = tmp;
    this.tipo = tpo;
  endfunction

  function void print(string tag = "");
    $display("[%g] %s Tiempo=%g Tipo=%s Retardo=%g dato=0x%h",$time,tag,tiempo,this.tipo,this.retardo,this.dato);
  endfunction
endclass
////////////////////////////////////////////////////////////////
// Interface: Esta es la interface que se conecta con la FIFO //
////////////////////////////////////////////////////////////////

interface fifo_if #(parameter width =16) (
  input bit clk
);
  logic rst;
  logic pndng;
  logic full;
  logic push;
  logic pop;
  logic [width-1:0] dato_in; 
  logic [width-1:0] dato_out;

  endinterface

  /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  // Driver/Monitor: este objeto es responsable de la interacción entre el ambiente y el la fifo bajo prueba //
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  class driver #(parameter width =16);
  virtual fifo_if #(.width(width))vif;
  mailbox agnt_drv_mbx;
  mailbox drv_sb_mbx;
  int espera;
  trans_fifo #(.width(width)) transaction; //# revisar si hay que inicializarla

  task run();
  @(posedge vif.clk);
  vif.rst=1;
  @(posedge vif.clk);
  forever begin
  vif.push = 0;
  vif.rst = 0;
  vif.pop = 0;
  vif.dato_in = 0;
  $display("T=%g el Driver espera por una transacción",$time);
  espera = 0;
  @(posedge vif.clk);
  agnt_drv_mbx.get(transaction);
  transaction.print("Transaccion recibida en el Driver");

  while(espera < transaction.retardo)begin
  @(posedge vif.clk);
  espera = espera+1;
  vif.dato_in = transaction.dato;
	end
case(transaction.tipo)
	"lectura": begin
	transaction.dato = vif.dato_out;
	transaction.tiempo = $time;
	@(posedge vif.clk);
	vif.pop = 1;
	drv_sb_mbx.put(transaction);
	transaction.print("Transaccion ejecutada en el Driver");
	end
	"escritura": begin
	vif.push = 1;
	transaction.tiempo = $time;
	drv_sb_mbx.put(transaction); 
	transaction.print("Transaccion ejecutada en el Driver");
	end
	"reset": begin
	vif.rst =1;
	transaction.tiempo = $time;
	drv_sb_mbx.put(transaction); 
	transaction.print("Transaccion ejecutada en el Driver");
	end
	"default": begin
	$display("Error: la transacción recibida en el driver no tiene tipo valido");
	$finish;
	end 
	endcase    
	@(posedge vif.clk);

	end
	endtask
	endclass

	//////////////////////////////////////////////////////////////////////////////////////////////////
	//  Transacción Test: este objeto representa las instruccines que se envían del Test al agente  // 
	//////////////////////////////////////////////////////////////////////////////////////////////////
	class trans_test;
	  string tipo_secuencia; //solo hay 2 tipos de secuencia validas: aleaoria o especifica
	  int num_eventos; //usado en la generación de secuencias especificas
	  int datos_val[]; //usado en la generación de secuencias especificas
	  int retardo_val[]; //usado en la generación de secuencias especificas
	  string tipo_val[]; //usado en la generación de secuencias especificas
	  int max_num_eventos; //usado en la generación de secuencias aleatorias
	  int max_retardo; //usado en la generación de secuencias aleatorias

	function new(
			string tipo_sec ="aleatoria",
			int num_event = 8,
			int dts_val[],
			int rtrd_val[],
			string tpo_val[],
			int max_num_evnts = 16,
			int max_rtrd = 16
		    );
	this.tipo_secuencia= tipo_sec;
	this.num_eventos = num_eventos;
	this.datos_val = dts_val;
	this.retardo_val= rtrd_val;
	this.tipo_val = tpo_val;
	this.max_num_eventos = max_num_evnts;
	this.max_retardo = max_rtrd;
 endfunction

	endclass
	//////////////////////////////////////////////////////////////////////////////////////////////////
	// Agente/Generador: Este bloque se encarga de generar las secuencias de eventos para el driver //
	// En este ejemplo se generarán 2 tipos de secuencias:                                          //
	//    Aleatoria: En esta se generarán transacciones totalmente aleatorias                       //
	//    Específica: en este tipo se generan trasacciones semi específicas para casos esquina      // 
	//////////////////////////////////////////////////////////////////////////////////////////////////
      class agent #(parameter width = 16);
	rand bit [7:0] retardo; // El retardo aleatorio por transacción tendrá un valor máximo de 255 ciclos de reloj
	rand bit [width-1:0] dato; // El valor del dato estará limitado por su largo en bits
	rand bit [1:0] tipo;
	string tipo_s[3];
	mailbox agnt_drv_mbx;
	mailbox tst_agnt_mbx;
	int num_val_datos = 3; 
	int num_val_size = 3;  
	int num_val_retardo = 3;

	rand int dat_select_e;
	constraint const_dat_select_e{ dat_select_e < num_val_datos;} 
	rand int tipo_select_e;
	constraint const_tipo_select_e{tipo_select_e<num_val_size;}
	rand int retardo_select_e;
	constraint const_ret_select_e{retardo_select_e<num_val_retardo;}
	trans_fifo transaccion;

	int mx_nm_eventos = 3;
	int mx_retardo = 3;

	rand int num_eventos;
	constraint const_num_eventos {num_eventos <mx_nm_eventos;}
	rand bit [width-1:0] rand_data;
	rand int rand_retardo;
	constraint const_retardo{rand_retardo<mx_retardo;}
	rand int tipo_select_a;
	constraint const_tipo_select_a{tipo_select_a<3;}

	constraint tipos_validos {tipo <=2;}


	function new();
	  this.retardo = 0;
	  this.tipo_s[0] = "lectura";
	  this.tipo_s[1] = "escritura";
	  this.tipo_s[2] = "reset";
	  this.dato = 0;
	  this.tipo = 1;
	endfunction

	// para generar secuencias específicas
	task sec_especifica (
	  int num_eventos = 8, 
	  int datos_val[],
	  int retardo_val[],
	  string tipo_val[]
        );
          num_val_datos = datos_val.size();
          num_val_size = tipo_val.size(); 
          num_val_retardo = retardo_val.size();

          for(int i=0; i< num_eventos; i++) begin
            this.randomize();
            //   dat_select_e.randomize();
            //   tipo_select_e.randomize();
            //   retardo_select_e.randomize();

            transaccion = new(.dto(datos_val[dat_select_e]),.ret(retardo_val[retardo_select_e]),.tpo(tipo_val[tipo_select_e]));
            agnt_drv_mbx.put(transaccion);
            $display("[%g] El agente envía una transaccion al driver de tipo %s  con dato %h y retardo %g",$time,transaccion.tipo,transaccion.dato,transaccion.retardo); 
          end 
        endtask
        ////////////////////////////////////////
        // para generar secuencias aleatorias //
        ////////////////////////////////////////
        task sec_aleatoria (
	  int max_num_eventos, 
	  int max_retardo
	);
          mx_nm_eventos = max_num_eventos;
          mx_retardo = max_retardo;

          for(int i=0; i< max_num_eventos; i++) begin
            this.randomize();
            //    rand_data.randomize();
            //    tipo_select_a.randomize();
            //    rand_retardo.randomize();
            transaccion = new(.dto(rand_data),.ret(rand_retardo),.tpo(tipo_s[tipo_select_a]));
            agnt_drv_mbx.put(transaccion);
            $display("[%g] El agente envía una transaccion al driver de tipo %s  con dato %h y retardo %g",$time,transaccion.tipo,transaccion.dato,transaccion.retardo); 
          end
        endtask

        task run();
          forever begin
            trans_test instruccion_test;
            tst_agnt_mbx.get(instruccion_test);
            $display("[%g] El agente recibe una instruccion del test de tipo %s",$time,instruccion_test.tipo_secuencia );

            case(instruccion_test.tipo_secuencia)
	      "aleatorio":begin
	         this.sec_aleatoria(
	           .max_num_eventos(instruccion_test.max_num_eventos),
	           .max_retardo(instruccion_test.max_retardo)
	         ); 
	      end
	      "especifico":begin 
	        this.sec_especifica(
	  	  .num_eventos(instruccion_test.num_eventos),
		  .datos_val(instruccion_test.datos_val),
		  .retardo_val(instruccion_test.retardo_val),
		  .tipo_val(instruccion_test.tipo_val)
	        ); 
	      end
	      default: begin
	        $display("[%g] ERROR: El agente recive una instrucción del test de tipo inválido",$time);
	        $finish;
	      end
	    endcase 
	  end
	endtask
      endclass

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Ambiente: este módulo es el encargado de conectar todos los elementos del ambiente para que puedan ser usados por el test //
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
      class ambiente #(parameter width);
	driver #(.width(width)) driver_inst;
	agent  #(.width(width)) agent_inst;

	virtual fifo_if interface_fifo; //interface entre el DUT y el driver

	mailbox agnt_drv_mbx; //mailbox del agente al driver
	mailbox drv_sb_mbx; //mailbox del driver al score board
	mailbox tst_agnt_mbx; //mailbox del test al agente

	function new();
	  driver_inst = new();
	  agent_inst = new();

 	  agnt_drv_mbx = new();
	  drv_sb_mbx = new(); 

	  driver_inst.agnt_drv_mbx = agnt_drv_mbx;
	  driver_inst.drv_sb_mbx = drv_sb_mbx;
	  driver_inst.vif = interface_fifo;
	  agent_inst.agnt_drv_mbx = agnt_drv_mbx;

	endfunction

	virtual task run();
	  fork
	    driver_inst.run();
	    agent_inst.run();
	  join_any
	endtask 
      endclass

	//////////////////////////////////////////////////////////////////////////////////////////
	// Test: esta entidad instancia el ambiente y genera los parámetros del test específico //
	//////////////////////////////////////////////////////////////////////////////////////////
      class test;
	// test parameters
	parameter width_p = 16;
	parameter depth_p = 8;
	parameter tipo_sec_p ="especifica";
	parameter num_event_p = 8;
	parameter max_num_evnts_p = 16;
	parameter max_rtrd_p = 16;

	int  dts_val_p[];
	int rtrd_val_p[];
	string tpo_val_p[];

	mailbox tst_agnt_mbx;
	trans_test transaccion; 
        ambiente #(.width(width_p)) ambiente_inst;

     function new();
       dts_val_p = new[4];
       rtrd_val_p = new[3];
       tpo_val_p = new[3];
    
       dts_val_p = { 'hffff, 'h0000,'h5555,'haaaa};
       rtrd_val_p = {2,3,1};
       tpo_val_p = {"reset", "lectura", "escritura"};
  
       tst_agnt_mbx = new();
       transaccion = new(.tipo_sec(tipo_sec_p),
                         .num_event(num_event_p),
                         .dts_val(dts_val_p),
                         .rtrd_val(rtrd_val_p),
                         .tpo_val(tpo_val_p),
                         .max_num_evnts(max_num_evnts_p),
                         .max_rtrd(max_rtrd_p)
       );
       ambiente_inst = new();
       ambiente_inst.tst_agnt_mbx = tst_agnt_mbx; 
     endfunction
  
     task run();
       tst_agnt_mbx.put(transaccion);
       ambiente_inst.run();
     endtask
   endclass

///////////////////////////////////
// Módulo para correr la prueba  //
///////////////////////////////////
module test_bench; 
  reg clk;
  test t0;
  parameter width = 16;
  parameter depth = 8;

  virtual fifo_if  #(.width(width)) _if(clk);
  always #5 clk = ~clk;

  fifo_flops #(.depth(depth),.bits(width)) uut(
    .Din(_if.dato_in),
    .Dout(_if.dato_out),
    .push(_if.push),
    .pop(_if.pop),
    .clk(_if.clk),
    .full(_if.full),
    .pndng(_if.pndng),
    .rst(_if.rst)
  );

  initial begin
    clk = 0;
    t0 = new();
    t0.ambiente_inst.interface_fifo = _if;
    t0.run();

    #10000
    $finish;
  end

endmodule






