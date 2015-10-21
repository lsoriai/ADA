with Chat_Messages;
with Lower_Layer_UDP;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with Ada.Exceptions;
with Ada.Calendar;
with Ada.Command_Line;
with Debug;
with Pantalla;
with Timed_Handlers;
with Chat_Handlers;
with Gnat.Ctrl_C;
with Manejador;

procedure chat_peer_2 is

	package LLU renames Lower_Layer_UDP;
        package ASU renames Ada.Strings.Unbounded;
        package ACL renames Ada.Command_Line;
	package TIO renames Ada.Text_IO;
	package CM renames Chat_Messages;
	package AC renames Ada.Calendar;
	package CH renames Chat_Handlers;
	
	use type CM.Message_Type;
	use type LLU.End_Point_Type;
	use type ASU.Unbounded_String;
	use type CH.Seq_N_T;
	use type Ada.Calendar.Time;

	
	procedure Crear_Init(EP_H: LLU.End_Point_Type;
			     EP_R: LLU.End_Point_Type;
			     Nick: ASU.Unbounded_String;
			     Seq_N: CH.Seq_N_T) is
		Tipo: CM.Message_Type := CM.Init;
		EP_H_Creat: LLU.End_Point_Type := EP_H;
		EP_R_Creat: LLU.End_Point_Type := EP_R;
		EP_H_Rsnd: LLU.End_Point_Type := EP_H;
   	    	Array_Vecinos: CH.Neighbors.Keys_Array_Type := CH.Neighbors.Get_Keys(CH.Vecinos);
   	   	Num_Vecinos: Natural := CH.Neighbors.Map_Length(CH.Vecinos);
		Mess: CH.Mess_Id_T; --Mensaje con ep y seq. Clave del Sender_Dests
		Array_Destinos: CH.Destinations_T;
		Tiempo: AC.Time;
		Datos_Pendientes: CH.Value_T; --Valor de la tabla Sender_Buffering --> Mensaje que tenemos que asentir 
	begin
		Debug.Put_Line ("Añadimos a Latest_Mesages " & CH.Direccion_Ip(EP_H) &
			  	" Seq: " & CH.Seq_N_T'Image(Seq_N));
		Debug.Put ("FLOOD Init ", Pantalla.Amarillo);
		Debug.Put_Line ("Creat: " & CH.Direccion_Ip(EP_H) & 
			  	" Seq: " & CH.Seq_N_T'Image(Seq_N) &
			  	" Rsnd: " & CH.Direccion_Ip(EP_H) &
			  	" ... " & ASU.To_String(Nick));

		
		--Creamos el buffer donde vamos a almacenar la informacion el mensaje
		--Que vamos a enviar por si caso tuvieramos que retransmitirlo
		--Introducimos directamente los datos en dicho buffer
		CM.P_Buffer_Main := new LLU.Buffer_Type(1024);
		CM.Message_Type'Output (CM.P_Buffer_Main, Tipo);
		LLU.End_Point_Type'Output (CM.P_Buffer_Main, EP_H_Creat);
		CH.Seq_N_T'Output (CM.P_Buffer_Main, Seq_N);
		LLU.End_Point_Type'Output (CM.P_Buffer_Main, EP_H_Rsnd);
		LLU.End_Point_Type'Output (CM.P_Buffer_Main, EP_R_Creat);
		ASU.Unbounded_String'Output (CM.P_Buffer_Main, Nick);
		
		for I in 1..Num_Vecinos loop
			Debug.Put("      Send to: ");
			Debug.Put_Line(CH.Direccion_IP(Array_Vecinos(I)));
			LLU.Send(Array_Vecinos(I), CM.P_Buffer_Main);
		end loop;

		--Una vez enviado el init tenemos que añadir a nuestras tablas los datos
		--de aquellos nodos a los que le hemos enviado el paquete y a que hora lo hemos 
		--hecho, ya que sino recibimos su ACK, tendremos que retransmitirselo
		--Tenemos que tener en cuenta tambien que lo retransmitiremos en caso de que 
		--no se haya superado el maximo de retransmisiones, 10.

		--Asociamos los datos a las variables
		--Comenzamos por el Sender_Buffering 
		Tiempo := AC.Clock + CH.Plazo_Retransmision; 	--Clave -> Tiempo
		Datos_Pendientes.EP_H_Creat := EP_H_Creat;	   	--Valor_Record.EP
		Datos_Pendientes.Seq_N := Seq_N;	   	--Valor_Record.Seq
		Datos_Pendientes.P_Buffer := CM.P_Buffer_Main;  --Valor_Record.Buffer
		
		--Lo introducimos en la tabla para que el nodo sepa que hay un mensaje que ha enviado
		--que todavía no ha sido asentido por el nodo al que se lo vas a reenviar.
		CH.Sender_Buffering.Put(CH.Buffer, Tiempo, Datos_Pendientes);

		--Con el Mess.EP y el Mess.Seq creamos el array de destinos 
		Mess.EP := EP_H_Creat;
		Mess.Seq := Seq_N;
		for I in 1..Num_Vecinos loop
			Array_Destinos(I).EP := Array_Vecinos(I); 
		end loop;

		--Lo introducimos en la tabla para que el nodo sepa todos los destinos a los que le
		--ha llegado este mensaje, de tal manera que cuando uno de ellos envie el ACK
		--este lo borre de la tabla, lo cual implica que a este vecino ya le ha llegado el
		--mensaje
		CH.Sender_Dests.Put(CH.Destinos, Mess, Array_Destinos);

		--Ejecutamos el paquete Timed_Handlers para que empiece a tener en cuenta el tiempo
		--Si se supera el tiempo al estimado tenemos que retransmitirlo. El tiempo estimado
		--va implicito en la misma llamada a traves de la variable Tiempo. Si este se supera 
		--se llama a la funcion y esta empieza a retransmitir el mismo mensaje ayudandose para
		--ello de las tablas de datos de Sender_Buffering y Sender_Dests
		Timed_Handlers.Set_Timed_Handler(Tiempo, CH.Retransmision'Access);
	end Crear_Init;
	

	procedure Enviar_Confirm (EP_H: LLU.End_Point_Type;
				  Nick: ASU.Unbounded_String;
				  Seq_N: CH.Seq_N_T) is
		Tipo: CM.Message_Type := CM.Confirm;
		EP_H_Creat: LLU.End_Point_Type := EP_H;
		EP_H_Rsnd: LLU.End_Point_Type := EP_H;
		Array_Vecinos: CH.Neighbors.Keys_Array_Type := CH.Neighbors.Get_Keys(CH.Vecinos);
   	   	Num_Vecinos: Natural := CH.Neighbors.Map_Length(CH.Vecinos);
		Mess: CH.Mess_Id_T; --Mensaje con ep y seq. Clave del Sender_Dests
		Array_Destinos: CH.Destinations_T;
		Tiempo: AC.Time;
		Datos_Pendientes: CH.Value_T;
	begin
		Debug.Put_Line("Añadimos a Latest_Mesages " & CH.Direccion_Ip(EP_H) &
			  " Seq: " & CH.Seq_N_T'Image(Seq_N));
	
		Debug.Put("FLOOD Confirm ", Pantalla.Amarillo);
		Debug.Put_Line ("Creat: " & CH.Direccion_IP(EP_H) &
			  	" Seq: " & CH.Seq_N_T'Image(Seq_N) &
			  	" Rsnd: " & CH.Direccion_IP(EP_H) &
			  	" " & ASU.To_String(Nick)); 

		--Creamos el buffer donde vamos a almacenar la informacion el mensaje
		--Que vamos a enviar por si caso tuvieramos que retransmitirlo
		--Introducimos directamente los datos en dicho buffer
		CM.P_Buffer_Main := new LLU.Buffer_Type(1024); 
		CM.Message_Type'Output (CM.P_Buffer_Main, Tipo);
		LLU.End_Point_Type'Output (CM.P_Buffer_Main, EP_H_Creat);
		CH.Seq_N_T'Output (CM.P_Buffer_Main, Seq_N);
		LLU.End_Point_Type'Output (CM.P_Buffer_Main, EP_H_Rsnd);
		ASU.Unbounded_String'Output (CM.P_Buffer_Main, Nick);
		
		for I in 1..Num_Vecinos loop
			Debug.Put("      Send to: ");
			Debug.Put_Line(CH.Direccion_IP(Array_Vecinos(I)));
			LLU.Send(Array_Vecinos(I), CM.P_Buffer_Main);
		end loop;
			--Una vez enviado el init tenemos que añadir a nuestras tablas los datos
		--de aquellos nodos a los que le hemos enviado el paquete y a que hora lo hemos 
		--hecho, ya que sino recibimos su ACK, tendremos que retransmitirselo
		--Tenemos que tener en cuenta tambien que lo retransmitiremos en caso de que 
		--no se haya superado el maximo de retransmisiones, 10.

		--Asociamos los datos a las variables
		--Comenzamos por el Sender_Buffering 
		Tiempo := AC.Clock + CH.Plazo_Retransmision; 	--Clave -> Tiempo
		Datos_Pendientes.EP_H_Creat := EP_H_Creat;	   	--Valor_Record.EP
		Datos_Pendientes.Seq_N := Seq_N;	   	--Valor_Record.Seq
		Datos_Pendientes.P_Buffer := CM.P_Buffer_Main;  --Valor_Record.Buffer
		
		--Lo introducimos en la tabla para que el nodo sepa que hay un mensaje que ha enviado
		--que todavía no ha sido asentido por el nodo al que se lo vas a reenviar.
		CH.Sender_Buffering.Put(CH.Buffer, Tiempo, Datos_Pendientes);

		--Finalizamos con la variables del Sender_Dests
		Mess.EP := EP_H_Creat;
		Mess.Seq := Seq_N;
		for I in 1..Num_Vecinos loop
			Array_Destinos(I).EP := Array_Vecinos(I); 
		end loop;

		--Lo introducimos en la tabla para que el nodo sepa todos los destinos a los que le
		--ha llegado este mensaje, de tal manera que cuando uno de ellos envie el ACK
		--este lo borre de la tabla, lo cual implica que a este vecino ya le ha llegado el
		--mensaje
		CH.Sender_Dests.Put(CH.Destinos, Mess, Array_Destinos);

		--Ejecutamos el paquete Timed_Handlers para que empiece a tener en cuenta el tiempo
		--Si se supera el tiempo al estimado tenemos que retransmitirlo. El tiempo estimado
		--va implicito en la misma llamada a traves de la variable Tiempo. Si este se supera 
		--se llama a la funcion y esta empieza a retransmitir el mismo mensaje ayudandose para
		--ello de las tablas de datos de Sender_Buffering y Sender_Dests
		Timed_Handlers.Set_Timed_Handler(Tiempo, CH.Retransmision'Access);
	end Enviar_Confirm;
		
	procedure Enviar_Logout (Confirm_Sent: Boolean;
				 Nick: ASU.Unbounded_String;
				 EP_H: LLU.End_Point_Type;
				 Seq_N: in out CH.Seq_N_T) is
		Tipo: CM.Message_Type := CM.Logout;
		EP_H_Creat: LLU.End_Point_Type := EP_H;
		EP_H_Rsnd: LLU.End_Point_Type := EP_H;
		Array_Vecinos: CH.Neighbors.Keys_Array_Type := CH.Neighbors.Get_Keys(CH.Vecinos);
   	   	Num_Vecinos: Natural := CH.Neighbors.Map_Length(CH.Vecinos);
		Mess: CH.Mess_Id_T; --Mensaje con ep y seq. Clave del Sender_Dests
		Array_Destinos: CH.Destinations_T;
		Tiempo: AC.Time;
		Datos_Pendientes: CH.Value_T;
		begin
			Debug.Put("FLOOD Logout ", Pantalla.Amarillo);
			Debug.Put_Line ("Creat " & CH.Direccion_Ip(EP_H) &
				  	"Seq: " & CH.Seq_N_T'Image(Seq_N) &
				  	" Rsnd " &CH.Direccion_Ip(EP_H) &
				  	" " & ASU.To_String(CH.Mi_Nick) &
				  	" " & Boolean'Image(Confirm_Sent));

			--Creamos el buffer donde vamos a almacenar la informacion el mensaje
			--Que vamos a enviar por si caso tuvieramos que retransmitirlo
			--Introducimos directamente los datos en dicho buffer
			CM.P_Buffer_Main := new LLU.Buffer_Type(1024);
			CM.Message_Type'Output (CM.P_Buffer_Main, Tipo);
			LLU.End_Point_Type'Output (CM.P_Buffer_Main, EP_H_Creat);
			CH.Seq_N_T'Output (CM.P_Buffer_Main, Seq_N);
			LLU.End_Point_Type'Output (CM.P_Buffer_Main, EP_H_Rsnd);
			ASU.Unbounded_String'Output (CM.P_Buffer_Main, Nick);
			Boolean'Output(CM.P_Buffer_Main, Confirm_Sent);
			
			for I in 1..Num_Vecinos loop
				Debug.Put("      Send to: ");
				Debug.Put_Line(CH.Direccion_IP(Array_Vecinos(I)));
				LLU.Send(Array_Vecinos(I), CM.P_Buffer_Main);
			end loop;
			
			--Una vez enviado el init tenemos que añadir a nuestras tablas los datos
			--de aquellos nodos a los que le hemos enviado el paquete y a que hora lo hemos 
			--hecho, ya que sino recibimos su ACK, tendremos que retransmitirselo
			--Tenemos que tener en cuenta tambien que lo retransmitiremos en caso de que 
			--no se haya superado el maximo de retransmisiones, 10.

			--Asociamos los datos a las variables
			--Comenzamos por el Sender_Buffering 
			Tiempo := AC.Clock + CH.Plazo_Retransmision; 	--Clave -> Tiempo
			Datos_Pendientes.EP_H_Creat := EP_H_Creat;	   	--Valor_Record.EP
			Datos_Pendientes.Seq_N := Seq_N;	   	--Valor_Record.Seq
			Datos_Pendientes.P_Buffer := CM.P_Buffer_Main;  --Valor_Record.Buffer
		
			--Lo introducimos en la tabla para que el nodo sepa que hay un mensaje que ha enviado
			--que todavía no ha sido asentido por el nodo al que se lo vas a reenviar.
			CH.Sender_Buffering.Put(CH.Buffer, Tiempo, Datos_Pendientes);

			--Finalizamos con la variables del Sender_Dests
			Mess.EP := EP_H_Creat;
			Mess.Seq := Seq_N;
			for I in 1..Num_Vecinos loop
				Array_Destinos(I).EP := Array_Vecinos(I); 
			end loop;

			--Lo introducimos en la tabla para que el nodo sepa todos los destinos a los que le
			--ha llegado este mensaje, de tal manera que cuando uno de ellos envie el ACK
			--este lo borre de la tabla, lo cual implica que a este vecino ya le ha llegado el
			--mensaje
			CH.Sender_Dests.Put(CH.Destinos, Mess, Array_Destinos);

			--Ejecutamos el paquete Timed_Handlers para que empiece a tener en cuenta el tiempo
			--Si se supera el tiempo al estimado tenemos que retransmitirlo. El tiempo estimado
			--va implicito en la misma llamada a traves de la variable Tiempo. Si este se supera 
			--se llama a la funcion y esta empieza a retransmitir el mismo mensaje ayudandose para
			--ello de las tablas de datos de Sender_Buffering y Sender_Dests
			Timed_Handlers.Set_Timed_Handler(Tiempo, CH.Retransmision'Access);
		end Enviar_Logout;

	procedure Enviar_Writer (EP_H: LLU.End_Point_Type;
				 Seq_N: in out CH.Seq_N_T;
				 Nick: ASU.Unbounded_String;
				 Text: ASU.Unbounded_String) is
		Tipo: CM.Message_Type := CM.Writer;
		EP_H_Creat: LLU.End_Point_Type := EP_H;
		EP_H_Rsnd: LLU.End_Point_Type := EP_H;
		Array_Vecinos: CH.Neighbors.Keys_Array_Type := CH.Neighbors.Get_Keys(CH.Vecinos);
   	   	Num_Vecinos: Natural := CH.Neighbors.Map_Length(CH.Vecinos);
		Mess: CH.Mess_Id_T; --Mensaje con ep y seq. Clave del Sender_Dests
		Array_Destinos: CH.Destinations_T;
		Tiempo: AC.Time;
		Datos_Pendientes: CH.Value_T;
		begin
			Debug.Put("Añadimos a Latest_Mesages ");
			Debug.Put_Line (CH.Direccion_Ip(EP_H) & 
				  	" Seq: " & CH.Seq_N_T'Image(Seq_N));
				  	
			Debug.Put("FLOOD Writer ", Pantalla.Amarillo);
			Debug.Put_Line (" Creat: " & CH.Direccion_IP(EP_H) &
				  	" Seq: " & CH.Seq_N_T'Image(Seq_N) &
				  	" Rsnd: " & CH.Direccion_IP(EP_H) &
			          	" " & ASU.To_String(Nick) & 
				  	" " & ASU.To_String(Text)); 

			--Creamos el buffer donde vamos a almacenar la informacion el mensaje
			--Que vamos a enviar por si caso tuvieramos que retransmitirlo
			--Introducimos directamente los datos en dicho buffer
			CM.P_Buffer_Main := new LLU.Buffer_Type(1024);
			CM.Message_Type'Output (CM.P_Buffer_Main, Tipo);
			LLU.End_Point_Type'Output (CM.P_Buffer_Main, EP_H_Creat);
			CH.Seq_N_T'Output (CM.P_Buffer_Main, Seq_N);
			LLU.End_Point_Type'Output (CM.P_Buffer_Main, EP_H_Rsnd);
			ASU.Unbounded_String'Output (CM.P_Buffer_Main, Nick);
			ASU.Unbounded_String'Output (CM.P_Buffer_Main, Text);
			
			for I in 1..Num_Vecinos loop
				Debug.Put("      Send to: ");
				Debug.Put_Line(CH.Direccion_IP(Array_Vecinos(I)));
				LLU.Send(Array_Vecinos(I), CM.P_Buffer_Main);
			end loop;
			--Una vez enviado el init tenemos que añadir a nuestras tablas los datos
			--de aquellos nodos a los que le hemos enviado el paquete y a que hora lo hemos 
			--hecho, ya que sino recibimos su ACK, tendremos que retransmitirselo
			--Tenemos que tener en cuenta tambien que lo retransmitiremos en caso de que 
			--no se haya superado el maximo de retransmisiones, 10.

			--Asociamos los datos a las variables
			--Comenzamos por el Sender_Buffering 
			Tiempo := AC.Clock + CH.Plazo_Retransmision; 	--Clave -> Tiempo
			Datos_Pendientes.EP_H_Creat := EP_H_Creat;	   	--Valor_Record.EP
			Datos_Pendientes.Seq_N := Seq_N;	   	--Valor_Record.Seq
			Datos_Pendientes.P_Buffer := CM.P_Buffer_Main;  --Valor_Record.Buffer
		
			--Lo introducimos en la tabla para que el nodo sepa que hay un mensaje que ha enviado
			--que todavía no ha sido asentido por el nodo al que se lo vas a reenviar.
			CH.Sender_Buffering.Put(CH.Buffer, Tiempo, Datos_Pendientes);

			--Finalizamos con la variables del Sender_Dests
			Mess.EP := EP_H_Creat;
			Mess.Seq := Seq_N;
			for I in 1..Num_Vecinos loop
				Array_Destinos(I).EP := Array_Vecinos(I); 
			end loop;

			--Lo introducimos en la tabla para que el nodo sepa todos los destinos a los que le
			--ha llegado este mensaje, de tal manera que cuando uno de ellos envie el ACK
			--este lo borre de la tabla, lo cual implica que a este vecino ya le ha llegado el
			--mensaje
			CH.Sender_Dests.Put(CH.Destinos, Mess, Array_Destinos);

			--Ejecutamos el paquete Timed_Handlers para que empiece a tener en cuenta el tiempo
			--Si se supera el tiempo al estimado tenemos que retransmitirlo. El tiempo estimado
			--va implicito en la misma llamada a traves de la variable Tiempo. Si este se supera 
			--se llama a la funcion y esta empieza a retransmitir el mismo mensaje ayudandose para
			--ello de las tablas de datos de Sender_Buffering y Sender_Dests
			Timed_Handlers.Set_Timed_Handler(Tiempo, CH.Retransmision'Access);
			
		end Enviar_Writer;
			
	Usage_Error: exception;
	EP_R: LLU.End_Point_Type;
	EP_H: LLU.End_Point_Type;
	EP_Vecino1: LLU.End_Point_Type;
	EP_Vecino2: LLU.End_Point_Type;
	Hora: AC.Time := AC.Clock;
	Success: Boolean;
	Confirm_Sent: Boolean;
	Expired: Boolean := False;
	Prompt: Boolean := False;
	Vecinos: CH.Neighbors.Prot_Map;
	Seq_N: CH.Seq_N_T := 0;
	Mensajes: CH.Latest_Msgs.Prot_Map;
	Buffer: aliased LLU.Buffer_Type(1024);
	Comentario: ASU.Unbounded_String;
	Array_Vecinos: CH.Neighbors.Keys_Array_Type := CH.Neighbors.Get_Keys(CH.Vecinos);
   	Num_Vecinos: Natural := CH.Neighbors.Map_Length(CH.Vecinos);
	Nick: ASU.Unbounded_String;
	Tipo: CM.Message_Type;
	EP_H_Reject: LLU.End_Point_Type;
	Max_Delay : Integer := 0;
	Min_Delay : Integer := 0;
	Fault_Pct : Natural := 0;
	Delay_Error : exception;
	Range_Error : exception;
	Fault_Pct_Error : exception;


----------------------------------------------------COMIENZO DEL PROGRAMA-------------------------------------------------------
begin

	Gnat.Ctrl_C.Install_Handler(Manejador.Ctrl_C_Handler'Access);
	if ACL.Argument_Count /= 5 and
	   ACL.Argument_Count /= 7 and
	   ACL.Argument_Count /= 9 then
		raise Usage_Error;
	end if;


--                                  EXTRACCION DE LOS DATOS DE LOS 5 ARGUMENTOS

	--Una vez que hemos visto si los argumentos son correctos, sabemos que como mínimo
	--nos pasarán 5 argumentos:
	--	Port
	--	Nick
	--	Min_Delay
	--	Max_Delay
	--	Fault_Pct
	--Como queremos que este programa se ejecute teniendo en cuenta posibles perdidas
	--y posibles retardos, tenemos que ejecutar una serie de ordenes para que el paquete
	--UDP admita este uso. Además tambien tenemos que tener en cuenta que trabajaremos
	--con plazos de retransmisiones por lo que deberemos añadir una nueva orden
	--Por tanto comenzamos a extraerlos poco a poco y añadimos las ordenes
	

	CH.Mi_Nick := ASU.To_Unbounded_String(ACL.Argument(2));
	EP_H := LLU.Build(LLU.To_IP(LLU.Get_Host_Name), Natural'Value(ACL.Argument(1)));
	Min_Delay := Integer'Value(ACL.Argument(3)); --Retardo mínimo
	Max_Delay := Integer'Value(ACL.Argument(4)); --Retardo máximo
	Fault_Pct := Natural'Value(ACL.Argument(5)); --Porcentaje de pérdidas
	LLU.Set_Faults_Percent (Fault_Pct);
	LLU.Set_Random_Propagation_Delay (Min_Delay, Max_Delay);
	CH.Plazo_Retransmision := 2 * Duration(Max_Delay) / 1000;
	
	--Construimos el end_point ya que tenemos la ip y el puerto al que se ata
	LLU.Bind (EP_H, CH.Handler'Access);
	LLU.Bind_Any(EP_R);
	

	--EXCEPCIONES
	-------------
		--Como por obliagación Max_Delay tiene que ser >= que Min_Delay podemos
		--encontrarnos con una excepcion si los argumentos que nos pasan no cumplen esta
		--condición. Por tanto:
			if Max_Delay < Min_Delay then
				raise Delay_Error;
			end if;

		--Podemos tener tambien tres excepciones mas si en el campo de los ultimos tres argumentos
		--3, 4, 5 no nos dan un número, sino un texto
			--if Max_Delay /= Integer or 
			  -- Min_Delay /= Integer or 
			  -- Fault_Pct /= Natural then
			--	raise Range_Error;
			--end if;

		--Tambien tenemos otra excepcion causada por el 5 elemento pues este no puede ser mayor de 100
		--pues es un porcentaje
			if Fault_Pct > 100 then
				raise Fault_Pct_Error;
			end if;


	if ACL.Argument_Count = 5 then
		Debug.Put_Line("No hacemos protocolo de admision pues no tenemos contactos iniciales...");
		CH.Latest_Msgs.Put(CH.Mensajes, EP_H, Seq_N, Success);
		Debug.Put_Line("Peer-Chat v1.0", Pantalla.Amarillo);
		Debug.Put_Line("==============", Pantalla.Amarillo);
		TIO.Put_Line("Entramos en el chat con el Nick: " & ASU.To_String(CH.Mi_Nick));
		TIO.Put_Line(".h para help");

--                                    FIN DE EXTRACIÓN DE LOS 5 ARGUMENTOS 
-------------------------------------------------------------------------------------------------------------------------------




--                                   EXTRACION DE LOS 2 ARGUMENTOS RESTANTES (7) 

	--Como tenemos siete argumentos sabemos que los dos restantes hacen referencia a:
	--	Nombre de la maquina vecina
	--	Puerto destinatario de la maquina vecina
	--Por tanto extraemos los dos argumentos restantes y construimos el end point

	--En este apartado tenemos que tener en cuenta que como estamos arrancando el
	--chat pasandole un nodo vecino tenemos que añadirle a nuestra tabla de vecinos
	--y a nuestra tabla de ultimos mensajes con numero de secuencia 1 (init)
	--Finalmente tendremos que enviar el init para que el nodo vecino nuestro tenga
	--consciencia de que nuestra maquina quiere comunicarse con ella
		
	elsif ACL.Argument_Count = 7 then			
		EP_Vecino1 := LLU.Build(LLU.To_IP(ACL.Argument(6)), Natural'Value(ACL.Argument(7)));
		CH.Neighbors.Put(CH.Vecinos, EP_Vecino1, Hora, Success);
		Debug.Put_Line("Añadimos a neightbors " & CH.Direccion_IP(EP_Vecino1));
		Debug.Put_Line("Iniciamos protocolo de admision...");
		Seq_N := Seq_N + 1;
		CH.Latest_Msgs.Put(CH.Mensajes, EP_H, Seq_N, Success);
		Crear_Init(EP_H, EP_R, CH.Mi_Nick, Seq_N);

--                                    FIN DE LA EXTRACCION DE LOS 2 ARGUMENTOS RESTANTES (7) 
---------------------------------------------------------------------------------------------------------------------------------




--                                    EXTRACION DE LOS 2 ARGUMENTOS RESTANTES (9)

	--Como tenemos nueve argumentos sabemos que los cuatro restantes hacen referencia a:
	--	Nombre de la maquina vecina 1
	--	Puerto destinatario de la maquina vecina 1
	--	Nombre de la maquina vecina 1
	--	Puerto destinatario de la maquina vecina 1
	--Por tanto extraemos los cuatro argumentos restantes y construimos los end points

	--En este apartado tenemos que tener en cuenta que como estamos arrancando el
	--chat pasandole dos nodos vecinos tenemos que añadirlos a nuestra tabla de vecinos
	--y a nuestra tabla de ultimos mensajes con numeros de secuencias 1 (Init)
	--Finalmente tendremos que enviar el init para que los nodos vecinos nuestros tengan
	--consciencia de que nuestra maquina quiere comunicarse con ellos

	else
		EP_Vecino1 := LLU.Build(LLU.To_IP(ACL.Argument(6)), Natural'Value(ACL.Argument(7)));
		EP_Vecino2 := LLU.Build(LLU.To_IP(ACL.Argument(8)), Natural'Value(ACL.Argument(9)));
		CH.Neighbors.Put(CH.Vecinos, EP_Vecino1, Hora, Success);
		CH.Neighbors.Put(CH.Vecinos, EP_Vecino2, Hora, Success);
		Debug.Put_Line("Añadimos a neightbors " & CH.Direccion_Ip(EP_Vecino1));
		Debug.Put_Line("Añadimos a neightbors " & CH.Direccion_Ip(EP_Vecino2));
		Debug.Put_Line("Iniciamos protocolo de admision...");
		Seq_N := Seq_N + 1;
		CH.Latest_Msgs.Put(CH.Mensajes, EP_H, Seq_N, Success);
		Crear_Init(EP_H, EP_R, CH.Mi_Nick, Seq_N);
	end if;

--                                      FIN DE LA EXTRACCION DE LOS 2 ARGUMENTOS RESTANTES (9)
------------------------------------------------------------------------------------------------------------------------------





	if ACL.Argument_Count = 7 or ACL.Argument_Count = 9 then
		LLU.Reset(Buffer);
		LLU.Receive(EP_R, Buffer'Access, 2.0, Expired);
		--Si no expira el tiempo es porque no nos "han rechazado" por tanto enviamos el confirm
		Seq_N := Seq_N + 1;
		if Expired then
			Enviar_Confirm (EP_H, CH.Mi_Nick, Seq_N);
			Debug.Put_Line("Fin del protocolo de admisión");
			Debug.Put_Line("Peer-Chat v1.0", Pantalla.Amarillo);
			Debug.Put_Line("==============", Pantalla.Amarillo);
			TIO.Put_Line("Entramos en el chat con el Nick: " & ASU.To_String(CH.Mi_Nick));
			TIO.Put_Line(".h para help");
		else
			Confirm_Sent := False;
			Tipo := CM.Message_Type'Input (Buffer'Access);
			EP_H_Reject := LLU.End_Point_Type'Input (Buffer'Access);
			Nick := ASU.Unbounded_String'Input (Buffer'Access);
			Debug.Put_Line("RCV Reject " & CH.Direccion_IP(EP_H));
			Debug.Put_Line("Usuario rechazado porque " & CH.Direccion_Ip(EP_H) &
				       " está usando el mismo nick", Pantalla.Blanco);
			Enviar_Logout (Confirm_Sent, CH.Mi_Nick, EP_H, Seq_N);
			Debug.Put_Line("Fin del protocolo de Admisión");
			
			--Como el nodo tiene que esperar a que su mensaje de Logout
			--se retransmita debera esperar un tiempo determinado teniendo
			--en cuenta el plazo de transmision maximo.

			delay 10*CH.Plazo_Retransmision;
			LLU.Finalize;
			Timed_Handlers.Finalize;
		end if;
	end if;

	loop 
		if Prompt = True then
			TIO.Put(ASU.To_String(CH.Mi_Nick) & ">> ");
		end if;

		Comentario := ASU.To_Unbounded_String(TIO.Get_Line);


	--                                         TABLA DE COMANDOS
	-- ====================================================================================================
		if Comentario = ".h" or Comentario = ".help" then
			Debug.Put_Line("        Comandos                 Efectos", Pantalla.Rojo);
			Debug.Put_Line("        =================        =======", Pantalla.Rojo);
			Debug.Put_Line("        .salir                   termina" &
				       				         " el programa", Pantalla.Rojo);
			Debug.Put_line("        .debug                   toggle para info de debug", Pantalla.Rojo);
			Debug.Put_Line("        .prompt                  toggle para mostrar prompt", Pantalla.Rojo);
			Debug.Put_Line("        .h .help                 muestra esta información " &
				       				         "de ayuda", Pantalla.Rojo);
			Debug.Put_Line("        .wai .whoami             muestra en pantalla: " &
				       				         "Nick / EP_H / EP_R", Pantalla.Rojo);
			Debug.Put_Line("        .nb .neighbors           lista de vecinos", Pantalla.Rojo);
			Debug.Put_Line("        .lm .latest_msgs         lista de los " &
				       				         "últimos mensajes recibidos", Pantalla.Rojo);
			Debug.Put_Line("        .sd .sender_dests        tabla Sender_Duffering", Pantalla.Rojo);
			Debug.Put_Line("        .sb .sender_buffering    tabla Sender_Buffering", Pantalla.Rojo);
		
		-----------------------------------------------------------------------------------------------
		elsif Comentario = ".nb" or Comentario = ".neighbors" then
			Debug.Put_Line("        Neighbors", Pantalla.Rojo);
			Debug.Put_Line("        ------------------------", Pantalla.Rojo);
			CH.Neighbors.Print_Map(CH.Vecinos);

		-----------------------------------------------------------------------------------------------
		elsif Comentario = ".lm" or Comentario = ".latest_msgs" then
			Debug.Put_Line("        Latest_Msgs", Pantalla.Rojo);
			Debug.Put_Line("        ------------------------", Pantalla.Rojo);
			CH.Latest_Msgs.Print_Map(CH.Mensajes);

		-----------------------------------------------------------------------------------------------
		elsif Comentario = ".debug" then
			CH.Debug_Status := not CH.Debug_Status;
			Debug.Set_Status (CH.Debug_Status);
			if CH.Debug_Status = True then
				Debug.Put_Line("Activada información de debug", Pantalla.Rojo);
			end if;
			if CH.Debug_Status = False then
				Debug.Put_Line("Desactivada información de debug", Pantalla.Rojo);
			end if;

		-----------------------------------------------------------------------------------------------
		elsif Comentario = ".wai" or Comentario = ".whoami" then
			Debug.Put_Line("Nick: " & ASU.To_String(CH.Mi_Nick) & " / " &
				       "EP_H: " & CH.Direccion_IP(EP_H) & " / " &
				       "EP_R: " & CH.Direccion_IP(EP_R), Pantalla.Rojo);

		-----------------------------------------------------------------------------------------------
		elsif Comentario = ".prompt" then
			Prompt := not Prompt;
			Debug.Set_Status (Prompt);
			if Prompt = True then
				Debug.Put_Line("Prompt activado. Si quiere " &
					       "desactivarlo escriba otra vez prompt", Pantalla.Rojo);
			end if;
			if Prompt = False then
				Debug.Put_Line("Prompt desactivado. Si quiere " &
					       "activarlo escriba otra vez prompt", Pantalla.Rojo);
			end if;

		------------------------------------------------------------------------------------------------
		elsif Comentario = ".sd" or Comentario = "sender_dests" then
			Debug.Put_Line("Sender_Dests", Pantalla.Rojo);
			Debug.Put_Line("-------------------", Pantalla.Rojo);
			CH.Sender_Dests.Print_Map(CH.Destinos);

		------------------------------------------------------------------------------------------------
		elsif Comentario = ".sb" or Comentario = "sender_buffering" then
			Debug.Put_Line("Sender_Buffering", Pantalla.Rojo);
			Debug.Put_Line("-------------------", Pantalla.Rojo);
			CH.Sender_Buffering.Print_Map(CH.Buffer);

	--                                   FIN DE LA TABLA DE COMANDOS
	-- =====================================================================================================
		
		elsif Comentario = "clear" then
			for I in 1..50 loop
				TIO.New_Line;
			end loop;
		elsif Comentario /= ".salir" then
			Seq_N := Seq_N + 1;
			Enviar_Writer (EP_H, Seq_N, CH.Mi_Nick, Comentario);
		else
			Confirm_Sent := True;
			Seq_N := Seq_N + 1;
			Enviar_Logout (Confirm_Sent, CH.Mi_Nick, EP_H, Seq_N);
			delay 10*CH.Plazo_Retransmision;
			LLU.Finalize;
			Timed_Handlers.Finalize;
		end if;

	exit when Comentario = ".salir";
	end loop;


exception	
	when Program_Error => 
		Confirm_Sent := True;
		Seq_N := Seq_N + 1;
		Enviar_Logout (Confirm_Sent, CH.Mi_Nick, EP_H, Seq_N);
		delay 10*CH.Plazo_Retransmision;
		LLU.Finalize;
		Timed_Handlers.Finalize;
			
	when Usage_Error =>
		Ada.Text_IO.Put_Line ("Argumentos no validos" & " <Puerto> <Nick>");

	when Delay_Error =>
		TIO.Put_Line ("Argumentos de retardo mínimo (3) y retardo máximo no validos (4)." &
			      "El cuarto argumento debe de ser mayor o igual el tercero");
	
	when Range_Error =>
		TIO.Put_line ("Los argumentos 3 y 4 deben de ser un número entero" &
			      " y el 5 un número natural");
	
	when Fault_Pct_Error =>
		TIO.Put_Line ("El quinto argumento no puede superar el 100. Son porcentajes");

	when Ex:others =>
		TIO.Put_Line("Excepcion improvista: " &
			     Ada.Exceptions.Exception_Name(Ex) & " en: " &
		             Ada.Exceptions.Exception_Message(Ex));
	LLU.Finalize;	
	Timed_Handlers.Finalize;
	
end chat_peer_2;

