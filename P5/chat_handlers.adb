--Leire Soria Indiano

--                                     ÍNDICE
--======================================================================================

--	Direccion_IP (Extrae la IP y el Puerto de un end-Point)..................27
--      Enviar_Reject (Envia expulsión por nick igual)...........................58
--	Reenviar_Init (Reenvia el init excepto al que lo mandó)..................76
--	Reenviar_Confirm (Reenvia el confirm excepto al que lo mandó)............151
--	Reenviar_Logout (Reenvia el logout excepto al que lo mandó)..............197
--	Reenviar_Writer (Reenvia el writer excepto al que lo mandó)..............246
--	Handler (Procedure principal)............................................293

--======================================================================================

with Ada.Strings.Unbounded;
with Maps_G;
with Timed_Handlers;
with Ada.Calendar;
with Maps_Protector_G;
with Gnat.Calendar.Time_IO;

package body Chat_Handlers is

	 use type ASU.Unbounded_String;
	 use type CM.Message_Type;
	 use type LLU.End_Point_Type; 
	 use type Ada.Calendar.Time;

	 function Image_Hora (T: Ada.Calendar.Time) return String is
   		begin
     			return C_IO.Image(T, "%T.%i");
   		end Image_Hora;
   	
	--Función que nos propociona un end point, suprimiendo todos los campos 
	--exceptuando la direccion ip y el puerto
   	function Direccion_IP (EP: LLU.End_Point_Type) return String is
   		Frase: ASU.Unbounded_String;
		Posicion : Natural;
		IP : ASU.Unbounded_String;
		Puerto: ASU.Unbounded_String;
   		begin
   			Frase := ASU.To_Unbounded_String(LLU.Image(EP));
   			Posicion := ASU.Index(Frase, ":");
   			Frase := ASU.Tail(Frase, ASU.Length(Frase) - Posicion + 1);
   			Posicion := ASU.Index(Frase, ",");
   			IP := ASU.Head(Frase, Posicion - 1);
   			Posicion := ASU.Index(Frase, ":");
   			Frase := ASU.Tail(Frase, ASU.Length(Frase) - Posicion);
   			while Posicion /= 0 loop
				Posicion := ASU.Index(Frase, " ");
					if Posicion = 1 then
						Frase := ASU.Tail(Frase, ASU.Length(Frase) - Posicion);
					elsif Posicion = 0 then
						if ASU.Length(Frase) /= 0 then
						Puerto := Frase;
						end if;
					else 
						Puerto := ASU.Head (Frase, Posicion - 1);
						Frase := ASU.Tail (Frase, ASU.Length (Frase) - Posicion);
					end if;
			end loop;
   			return ASU.To_String(IP) & ": " & ASU.To_String(Puerto);
   		end Direccion_IP;
   		
   		
  	function Menor (M1: Mess_Id_T; M2: Mess_Id_T) return boolean is
	   	begin
	   		if LLU.Image(M1.EP) < LLU.Image(M2.EP) or
			   (LLU.Image(M1.EP) = LLU.Image(M2.EP) and M1.Seq < M2.Seq) then
	   			return True;
	   		else 
	   			return False;
	   		end if;
	   	end Menor;
   	
   	function Mayor (M1: Mess_Id_T; M2: Mess_Id_T) return boolean is
	   	begin
	   		if LLU.Image(M1.EP) > LLU.Image(M2.EP) or
			   (LLU.Image(M1.EP) = LLU.Image(M2.EP) and M1.Seq > M2.Seq) then
	   			return True;
	   		else 
	   			return False;
	   		end if;
	   	end Mayor;
   
   	function Igual (M1: Mess_Id_T; M2: Mess_Id_T) return boolean is
	   	begin
	   		if LLU.Image(M1.EP) = LLU.Image(M2.EP) and M1.Seq = M2.Seq then
	   			return True;
	   		else 
	   			return False;
	   		end if;
	   	end Igual;
   	
   	function Image_Mess (M: Mess_Id_T) return String is
	   	begin
	   		return LLU.Image(M.EP) & " - " & Seq_N_T'Image(M.Seq);
	   	end Image_Mess;
   	
   	function Array_Destinos (D: Destinations_T) return String is
		Destinos : ASU.Unbounded_String := ASU.To_Unbounded_String(" ");
		Destino_Nuevo : ASU.Unbounded_String;
	   	begin
	   		for I in 1..10 loop
	   			if D(I).EP /= null then
	   				Destino_Nuevo := ASU.To_Unbounded_String(Direccion_IP(D(I).EP) & " " & 
					Natural'Image(D	(I).Retries));
					Destinos := ASU.To_Unbounded_String(ASU.To_String(Destinos) & ASU.To_String(Destino_Nuevo));
	   			end if;
	   		end loop;
			return ASU.To_String(Destinos);
	   	end Array_Destinos;

   	function Value_Image (V: Value_T) return String is
		begin
			return LLU.Image(V.EP_H_Creat) & " - " & Seq_N_T'Image(v.Seq_N);
		end Value_Image;
	   		
   		
	procedure Retransmision (Tiempo: in AC.Time) is
		Value: Value_T;
		Success: Boolean;
		Array_Destinos: Destinations_T;
		Tiempo_Nuevo: AC.Time;
		Reenviar: Boolean := False;
		Mess: Mess_Id_T;
		begin
			--Obtenemos el valor a traves de su clave Tiempo, obteniendo así una variable
			--de record que tiene los campos EP_H_creat, Seq_N y P_Buffer para la posible
			--retransmision que podamos hacer a continuacion
			Sender_Buffering.Get(Buffer, Tiempo, Value, Success);
			--Una vez que lo hemos conseguido necesitamos igualar los campos a nuestra variable
			--del Sender_Dests Mess, ya que necesitamos encontrar en nuestro array de destinos 
			--la posicion del vecino para ver si tenemos que retransmitirlo o si por el contrario
			--a sobrepasado los intentos de retransmision y el proceso de retransmision debe 
			--cancelarse
			Mess.EP := Value.EP_H_Creat;
			Mess.Seq := Value.Seq_N;
			--Una vez hecho esto borramos la entrada porque el tiempo de retransmision ya no es 
			--correcto
			Sender_Buffering.Delete(Buffer, Tiempo, Success);
			--Conseguimos nuestro array de destinos del mensaje concreto para trabajar con el
			Sender_Dests.Get (Destinos, Mess, Array_Destinos, Success);
			--A partir de ahora tenemos que mirar si:
			--	1: El campo EP esta null, lo que implicaria que ya ha sido asentido
			--	   o el campo tiene una EP lo que implica que aun no fue asentido
			--	2: Si el campo es null debemos mirar el campo retire:
			--		+Si es superior a 10 no lo reenviamos
			--		+Si es menor que 10 lo enviamos
			if Success = True then			
				for I in 1..10 loop
					if Array_Destinos(I).EP /= null then
						Reenviar := True;
						if Array_Destinos(I).Retries < 10 then
							LLU.Send(Array_Destinos(I).EP, Value.P_Buffer);
							Array_Destinos(I).Retries := Array_Destinos(I).Retries + 1;
							Debug.Put ("    RESENDED", Pantalla.Rojo);
							Debug.Put_Line ( " To: " & Direccion_IP(Array_Destinos(I).EP) &
								    	" Creat " & Direccion_IP(Mess.EP) &
								    	" Seq: " & Seq_N_T'Image(Mess.Seq) &
								    	" Retries: " & Natural'Image(Array_Destinos(I).Retries), 									    	Pantalla.Azul);
						end if;
					end if;
				end loop;
				if Reenviar = True then
					--Si lo hemos reenviado tenemos que actualizar las tablas 
					--porque aunmentamos otra vez el tiempo de retransmision y
					--aumentan tb los retries
					Sender_Dests.Put (Destinos, Mess, Array_Destinos); --> Retries
					Tiempo_Nuevo := AC.Clock + Plazo_Retransmision;
					Sender_Buffering.Put (Buffer, Tiempo_Nuevo, Value); --> T.Transmision
					Timed_Handlers.Set_Timed_Handler (Tiempo_Nuevo, Retransmision'Access);
				else
					Sender_Dests.Delete (Destinos, Mess, Success);
				end if;
			end if;	
				
				
		end Retransmision;
	
	procedure Preparar_Retransmitir (EP_H_Creat: LLU.End_Point_Type;
					 Seq_N: Seq_N_T;
				 	 Buffer_Datos: CM.Buffer_A_T;
					 EP_H_Rsnd1: LLU.End_Point_Type) is
		Array_Vecinos: Neighbors.Keys_Array_Type := Neighbors.Get_Keys(Vecinos);
   	    	Num_Vecinos: Natural := Neighbors.Map_Length(Vecinos);
		Mess: Mess_Id_T; --Mensaje con ep y seq. Clave del Sender_Dests
		Array_Destinos: Destinations_T;
		Tiempo: AC.Time;
		Datos_Pendientes: Value_T; --Valor de la tabla Sender_Buffering
		begin
			--Una vez enviado el init tenemos que añadir a nuestras tablas los datos
			--de aquellos nodos a los que le hemos enviado el paquete y a que hora lo hemos 
			--hecho, ya que sino recibimos su ACK, tendremos que retransmitirselo
			--Tenemos que tener en cuenta tambien que lo retransmitiremos en caso de que 
			--no se haya superado el maximo de retransmisiones, 10.

			--En la tabla de sender_Buffering guardaremos el mensaje en si
			--La clave de este record será el tiempo de retransmisión que nos servirá
			--para buscar el mensaje en concreto que tenemos que retransmitir cuando
			--se cumpla el plazo de retransmision que es justamente el tiempo que guardamos 
			--en el campo de la clave del sender_buffering
			--El valor que nos devolverá cuando metamos la clave en nuestra práctica será el mensaje en sí
			--el cual estará compuesto por la EP del nodo que lo creó, el número de secuencia de dicho 
			--mensaje y el buffer que contiene el comentario que tenemos que reenviar.
			 
			Tiempo := AC.Clock + Plazo_Retransmision; 		--Clave -> Sender_Buffering
			Datos_Pendientes.EP_H_Creat := EP_H_Creat;	   	--Valor_Record.EP
			Datos_Pendientes.Seq_N := Seq_N;	   		--Valor_Record.Seq
			Datos_Pendientes.P_Buffer := Buffer_Datos;  		--Valor_Record.Buffer
		
			--Lo introducimos en la tabla para que el nodo sepa que hay un mensaje que ha enviado
			--que todavía no ha sido asentido por el nodo al que se lo vas a reenviar.
			Sender_Buffering.Put(Buffer, Tiempo, Datos_Pendientes);

			--A continuación lo que tenemos que tener en cuenta es que con el valor que
			--obtenemos de la otra tabla (Seq, EP), buscamos en nuestra tabla de Sender_Dests el array
			--de los destinos a los que tenemos que asentir este mensaje (Ej: ALba, Carol y Jorge)
			Mess.EP := EP_H_Creat;
			Mess.Seq := Seq_N;
			for I in 1..Num_Vecinos loop
				if Array_Vecinos(I) /= EP_H_Rsnd1 then
					Array_Destinos(I).EP := Array_Vecinos(I); 
				end if;
			end loop;

			--Lo introducimos en la tabla para que el nodo sepa todos los destinos a los que le
			--ha llegado este mensaje, de tal manera que cuando uno de ellos envie el ACK
			--este lo borre de la tabla, lo cual implica que a este vecino ya le ha llegado el
			--mensaje
			Sender_Dests.Put(Destinos, Mess, Array_Destinos);

			--Ejecutamos el paquete Timed_Handlers para que empiece a tener en cuenta el tiempo
			--Si se supera el tiempo al estimado tenemos que retransmitirlo. El tiempo estimado
			--va implicito en la misma llamada a traves de la variable Tiempo. Si este se supera 
			--se llama a la funcion y esta empieza a retransmitir el mismo mensaje ayudandose para
			--ello de las tablas de datos de Sender_Buffering y Sender_Dests
			Timed_Handlers.Set_Timed_Handler(Tiempo, Retransmision'Access);

		end Preparar_Retransmitir;

	procedure Enviar_ACK (EP_H_Creat: LLU.End_Point_Type;
			      Seq_N: Seq_N_T;
			      EP_H_Acker: LLU.End_Point_Type;
			      EP_H_Rsnd: LLU.End_Point_Type) is
		Buffer: aliased LLU.Buffer_Type(1024);	
		Tipo: CM.Message_Type := CM.Ack;	
		begin
			LLU.Reset(Buffer);
			CM.Message_Type'Output (Buffer'Access, Tipo);
			LLU.End_Point_Type'Output (Buffer'Access, EP_H_Acker);
			LLU.End_Point_Type'Output (Buffer'Access, EP_H_Creat);
			Seq_N_T'Output (Buffer'Access, Seq_N);
			LLU.Send(EP_H_Rsnd, Buffer'Access);
			Debug.Put("ACK Sent ", Pantalla.Rojo);
			Debug.Put_Line ("Acker_Creat: " & Direccion_IP(EP_H_Acker) &
			   	   	" Seq: " & Seq_N_T'Image(Seq_N) &
				   	" Destination: " & Direccion_IP(EP_H_Rsnd), Pantalla.Rojo); 
		end Enviar_ACK;
	
	procedure Recibir_ACK (EP_H_Acker: LLU.End_Point_Type;
			       EP_H_Creat: LLU.End_Point_Type;
			       Seq_N: Seq_N_T) is
		Mess: Mess_Id_T; --Mensaje con ep y seq. Clave del Sender_Dests
		Array_Destinos: Destinations_T;
		Success: Boolean;
		Num_Vecinos: Natural := Neighbors.Map_Length(Vecinos);
		Borrar_Array: Boolean := True;
		K: Natural := 0;
		begin
			Debug.Put ("RCV ACK ", Pantalla.Rojo);
			Debug.Put_Line ("Acker_Creat: " & Direccion_IP(EP_H_Acker) &
			   	   	" Seq: " & Seq_N_T'Image(Seq_N), Pantalla.Rojo); 
			--Ahora tenemos que examinar en nuestro array vecinos donde esta	
			--la entrada a dicho end point (EP_H_Acker) para borrarlo de la
			--lista de vecinos que tienen que mandarnos un asentimiento.
			--Si la lista de vecinos que nos deben de asentir un mensaje 
			--esta toda a null, eso significa que todos los vecinos a los que
			--les ha llegado el mensaje nos lo han asentido por lo que no debemos
			--de preocuparnos ya por el mensaje, puediendo asi borrar la lista de
			--vecinos.
			
			Mess.EP := EP_H_Creat;
			Mess.Seq := Seq_N;
			--Obtenemos el Array_Destinos con el EP_H_Creat ya que hemos
			--guardado el mensaje con su EP_H_Creat  y su Seq_N
			Sender_Dests.Get(Destinos, Mess, Array_Destinos, Success);

			for I in 1..Num_Vecinos loop
				if Array_Destinos(I).EP = EP_H_Acker then
					Array_Destinos(I).EP := null;
					Array_Destinos(I).Retries := 0;
				end if;
			end loop;

			loop
				K := K + 1;
				if Array_Destinos(K).EP /= null then
					Borrar_Array := False;
				end if;
			exit when K = 10 or Borrar_Array = False;
			end loop;

			if Borrar_Array = False then
				Sender_Dests.Put(Destinos, Mess, Array_Destinos);
			else
				Sender_Dests.Delete(Destinos, Mess, Success);
			end if;
			
		end Recibir_ACK;

	--Procedure que envia la expulsion a un nodo que ha pedido la solicitud de entrada
	--pero como tiene el mismo nick ha sido expulsado
	procedure Enviar_Reject(Nick: ASU.Unbounded_String;
				EP_H_Rsnd: LLU.End_Point_Type;
				EP_R_Creat: LLU.End_Point_Type) is
		Buffer: aliased LLU.Buffer_Type(1024);
		Tipo: CM.Message_Type := CM.Reject;
		EP_H: LLU.End_Point_Type := EP_H_Rsnd;
		begin
			LLU.Reset(Buffer);
			CM.Message_Type'Output (Buffer'Access, Tipo);
			LLU.End_Point_Type'Output (Buffer'Access, EP_H);
			ASU.Unbounded_String'Output (Buffer'Access, Nick);
			LLU.Send(EP_R_Creat, Buffer'Access);
		end Enviar_Reject;
   		
   		
   
   	procedure Vecino_Nuevo (Nick: ASU.Unbounded_String;
   				Mi_Nick: ASU.Unbounded_String;
   				EP_H_Rsnd: LLU.End_Point_Type;
   				EP_R_Creat: LLU.End_Point_Type;
   				Seq_N: Seq_N_T;
   				EP_H_Rsnd1: LLU.End_Point_Type;
   				EP_H_Creat: LLU.End_Point_Type) is
   		begin
   			if Mi_Nick = Nick then
				Debug.Put_Line("      SEND Reject " & Direccion_Ip(EP_H_Rsnd) &
					  " " & ASU.To_String(Nick));

				Enviar_Reject(Nick, EP_H_Rsnd, EP_R_Creat);
				Debug.Put_Line("      Añadimos a latest_messages: " & 
					       Direccion_IP(EP_H_Creat) &
					       " Seq: " & Seq_N_T'Image(Seq_N));

			elsif Mi_Nick /= Nick and EP_H_Creat = EP_H_Rsnd1 then
				Debug.Put_Line("      Añadimos a neighbors: " & Direccion_IP(EP_H_Creat));
				Debug.Put_Line("      Añadimos a latest_messages: " & 
					       Direccion_IP(EP_H_Creat) &
					       " Seq: " & Seq_N_T'Image(Seq_N));
			end if;
		end Vecino_Nuevo;
   	--Procedure que reenvia el init a todos los vecinos excepto al que te lo envió.
	--Envio por inundación	
   	procedure Reenviar_Init (Seq_N: Seq_N_T;
   	                         EP_H_Rsnd: LLU.End_Point_Type;
   	                         EP_H_Creat: LLU.End_Point_Type;
   	                         Mi_Nick: ASU.Unbounded_String;
   	                         EP_H_Rsnd1: LLU.End_Point_Type;
				 EP_R_Creat: LLU.End_Point_Type;
				 Nick: ASU.Unbounded_String) is
   	    	Array_Vecinos: Neighbors.Keys_Array_Type := Neighbors.Get_Keys(Vecinos);
   	    	Num_Vecinos: Natural := Neighbors.Map_Length(Vecinos);
   	    	Tipo: CM.Message_Type := CM.Init;
   		begin
			CM.P_Buffer_Handler := new LLU.Buffer_Type(1024);
			CM.Message_Type'Output (CM.P_Buffer_Handler, Tipo);
			LLU.End_Point_Type'Output (CM.P_Buffer_Handler, EP_H_Creat);
			Seq_N_T'Output (CM.P_Buffer_Handler, Seq_N);
			LLU.End_Point_Type'Output (CM.P_Buffer_Handler, EP_H_Rsnd);
			LLU.End_Point_Type'Output (CM.P_Buffer_Handler, EP_R_Creat);
			ASU.Unbounded_String'Output (CM.P_Buffer_Handler, Nick);
			Debug.Put ("      FLOOD Init ", Pantalla.Amarillo);
			Debug.Put_Line (" Creat: " & Direccion_IP(EP_H_Creat) &
			  	 	" Seq: " & Seq_N_T'Image(Seq_N)  &
			  		" Rsnd: " & Direccion_IP(EP_H_Rsnd) &
			 		" ... " & ASU.To_String(Nick));
 
			for I in 1..Num_Vecinos loop
				if Array_Vecinos(I) /= EP_H_Rsnd1 then
					Debug.Put("      Send to: ");
					Debug.Put_Line(Direccion_IP(Array_Vecinos(I)));
					LLU.Send(Array_Vecinos(I), CM.P_Buffer_Handler);
				end if;
			end loop;
			Preparar_Retransmitir (EP_H_Creat, Seq_N, CM.P_Buffer_Handler, EP_H_Rsnd1);
		end Reenviar_Init;
		

	procedure Reenviar_Confirm (Seq_N: Seq_N_T;
   	                            EP_H_Rsnd: LLU.End_Point_Type;
   	                            EP_H_Creat: LLU.End_Point_Type;
   	                            Nick: ASU.Unbounded_String;
   	                            EP_H_Rsnd1: LLU.End_Point_Type) is
   	    	Array_Vecinos: Neighbors.Keys_Array_Type := Neighbors.Get_Keys(Vecinos);
   	   	Num_Vecinos: Natural := Neighbors.Map_Length(Vecinos);
   	   	Tipo: CM.Message_Type := CM.Confirm;
   		begin
			CM.P_Buffer_Handler := new LLU.Buffer_Type(1024);
			CM.Message_Type'Output (CM.P_Buffer_Handler, Tipo);
			LLU.End_Point_Type'Output (CM.P_Buffer_Handler, EP_H_Creat);
			Seq_N_T'Output (CM.P_Buffer_Handler, Seq_N);
			LLU.End_Point_Type'Output (CM.P_Buffer_Handler, EP_H_Rsnd);
			ASU.Unbounded_String'Output (CM.P_Buffer_Handler, Nick);
			Debug.Put("      FLOOD Confirm ", Pantalla.Amarillo);
			Debug.Put_Line (" Creat: " & Direccion_IP(EP_H_Creat) &
				  	" Seq: " & Seq_N_T'Image(Seq_N) &
				  	" Rsnd: " & Direccion_IP(EP_H_Rsnd) &
				  	" " & ASU.To_String(Nick)); 

			for I in 1..Num_Vecinos loop
				if Array_Vecinos(I) /= EP_H_Rsnd1 then
					Debug.Put("      Send to: ");
					Debug.Put_Line(Direccion_IP(Array_Vecinos(I)));
					LLU.Send(Array_Vecinos(I), CM.P_Buffer_Handler);
				end if;
			end loop;
			Preparar_Retransmitir (EP_H_Creat, Seq_N, CM.P_Buffer_Handler, EP_H_Rsnd1);
		
		end Reenviar_Confirm;

			
	--Procedure que envia a todos los vecino, excepto a aquel que te lo envió, que un 
	--nodo ha sido rechazado por tener el mismo nick que uno de los existentes
	procedure Reenviar_Logout(Seq_N: Seq_N_T;
				  EP_H_Rsnd: LLU.End_Point_Type;
				  EP_H_Creat: LLu.End_Point_Type;
				  Nick: ASU.Unbounded_String;
				  EP_H_Rsnd1: LLu.End_Point_Type;
				  Confirm_Sent: Boolean) is
	   	Array_Vecinos: Neighbors.Keys_Array_Type := Neighbors.Get_Keys(Vecinos);
		Array_Mensajes: Latest_Msgs.Keys_Array_Type := Latest_Msgs.Get_Keys(Mensajes);
	   	Num_Vecinos: Natural := Neighbors.Map_Length(Vecinos);
	   	Tipo: CM.Message_Type := CM.Logout;
		Success: Boolean;
		Value: AC.Time;
		begin
			CM.P_Buffer_Handler := new LLU.Buffer_Type(1024); 
			CM.Message_Type'Output (CM.P_Buffer_Handler, Tipo);
			LLU.End_Point_Type'Output (CM.P_Buffer_Handler, EP_H_Creat);
			Seq_N_T'Output (CM.P_Buffer_Handler, Seq_N);
			LLU.End_Point_Type'Output (CM.P_Buffer_Handler, EP_H_Rsnd);
			ASU.Unbounded_String'Output (CM.P_Buffer_Handler, Nick);
			Boolean'Output (CM.P_Buffer_Handler, Confirm_Sent);
			Neighbors.Get(Vecinos, EP_H_Creat, Value, Success);
			
			--En este apartado vemos si le tenemos como vecinos. Si le tenemos, lo borramos
			if Success = True then
				Neighbors.Delete(Vecinos, EP_H_Creat, Success);
			end if;
			Latest_Msgs.Delete(Mensajes, EP_H_Creat, Success);
			Debug.Put_Line ("Borramos de latest_msgs a " & Direccion_IP(EP_H_Creat));
		
			--Si el confirm es igual a True eso significa que el nodo
			--ha abandonado el chat
			if Confirm_Sent = True then
				TIO.Put_Line(ASU.To_String(Nick) & " ha abandonado el chat");
			end if;

			for I in 1..Num_Vecinos loop
				if Array_Vecinos(I) /= EP_H_Rsnd1 then
					Debug.Put("      Send to: ");
					Debug.Put_Line(Direccion_IP(Array_Vecinos(I)));
					LLU.Send(Array_Vecinos(I), CM.P_Buffer_Handler);
				end if;
			end loop;

			Debug.Put("      FLOOD Logout ", Pantalla.Amarillo);
			Debug.Put_Line (" Creat: " & Direccion_IP(EP_H_Creat) &
				  	" Seq: " & Seq_N_T'Image(Seq_N) &
				  	" Rsnd: " & Direccion_IP(EP_H_Rsnd) &
				  	" " & ASU.To_String(Nick) &
				  	" " & Boolean'Image(Confirm_Sent));
			Preparar_Retransmitir (EP_H_Creat, Seq_N, CM.P_Buffer_Handler, EP_H_Rsnd1);
			
		end Reenviar_Logout;

	--Procedure que reenvia a todos los nodos, excepto a aquel que lo mandó
	--un mensaje writer
	procedure Reenviar_Writer(Seq_N: Seq_N_T;
				  Seq_Anterior: Seq_N_T;
				  EP_H_Rsnd: LLU.End_Point_Type;
				  EP_H_Creat: LLU.End_Point_Type;
				  Nick: ASU.Unbounded_String;
				  EP_H_Rsnd1: LLU.End_Point_Type;
				  Text: ASU.Unbounded_String) is
   	    	Array_Vecinos: Neighbors.Keys_Array_Type := Neighbors.Get_Keys(Vecinos);
   	   	Num_Vecinos: Natural := Neighbors.Map_Length(Vecinos);
   	    	Tipo: CM.Message_Type := CM.Writer;
		begin
			CM.P_Buffer_Handler := new LLU.Buffer_Type(1024); 
			CM.Message_Type'Output (CM.P_Buffer_Handler, Tipo);
			LLU.End_Point_Type'Output (CM.P_Buffer_Handler, EP_H_Creat);
			Seq_N_T'Output (CM.P_Buffer_Handler, Seq_N);
			LLU.End_Point_Type'Output (CM.P_Buffer_Handler, EP_H_Rsnd);
			ASU.Unbounded_String'Output (CM.P_Buffer_Handler, Nick);
			ASU.Unbounded_String'Output (CM.P_Buffer_Handler, Text);

			for I in 1..Num_Vecinos loop
				if Array_Vecinos(I) /= EP_H_Rsnd1 then
					Debug.Put("      Send to: ");
					Debug.Put_Line(Direccion_IP(Array_Vecinos(I)));
					LLU.Send(Array_Vecinos(I), CM.P_Buffer_Handler);
				end if;
			end loop;
			
			if Seq_Anterior + 1 = Seq_N then
				Debug.Put ("      FLOOD Writer ", Pantalla.Amarillo);
				Debug.Put_Line (" Creat: " & Direccion_IP(EP_H_Creat) &
					  	" Seq: " & Seq_N_T'Image(Seq_N) &
					  	" Rsnd: " & Direccion_IP(EP_H_Rsnd) &
					  	" " & ASU.To_String(Nick) & 
					  	" " &  ASU.To_String(Text));
			end if;
 			Preparar_Retransmitir (EP_H_Creat, Seq_N, CM.P_Buffer_Handler, EP_H_Rsnd1);
 			
		end Reenviar_Writer;
		
		
   	--Procedure principal		
   	procedure Handler (From: in LLU.End_Point_Type;
                           To: in LLU.End_Point_Type;
                           P_Buffer: access LLU.Buffer_Type) is 
                             
	Nick: ASU.Unbounded_String;
	Tipo: CM.Message_Type;
	EP_H_Creat: LLU.End_Point_Type;
	EP_R_Creat: LLU.End_Point_Type;
	EP_H_Rsnd: LLU.End_Point_Type;
	EP_H_Rsnd1: LLU.End_Point_Type;
	EP_H_Acker: LLU.End_Point_Type;
	Seq_N: Seq_N_T;
	Hora: AC.Time := AC.Clock;
	Success: Boolean;
	Success_Get: Boolean;
	Seq_Anterior: Seq_N_T;
	Confirm_Sent : Boolean;
	Text: ASU.Unbounded_String;
		begin
			Tipo := CM.Message_Type'Input(P_Buffer);
			-- Sacamos el tipo de cada mensaje y vemos que este puede ser de varios tipos
			--	+Init
			--	+Reject
			--	+Confirm
			--	+Writer
			--	+Logout
			--	+Ack
			--Los 5 primeros tipos comparten varios campos en su mensaje (EP_H_Creat,
			--Seq_N, EP_H_Rsnd1) y luego dependiendo de cada uno existen o no mas campos
			--Para ahorrar espacio sacamos esos tres campos que comparten a la vez
			
			--Hay que tener en cuenta que el mensaje de tipo Ack no comparte ningun
			--campo con el resto de los mensajes, por tanto necesitamos sacar sus 
			--valores del buffer al margen de los demas.
			if Tipo = CM.Ack then
				EP_H_Acker := LLU.End_Point_Type'Input (P_Buffer);
				EP_H_Creat := LLU.End_Point_Type'Input (P_Buffer);
				Seq_N := Seq_N_T'Input (P_Buffer);
			else
				EP_H_Creat := LLU.End_Point_Type'Input (P_Buffer);
				Seq_N := Seq_N_T'Input (P_Buffer);
				EP_H_Rsnd1 := LLU.End_Point_Type'Input (P_Buffer);
				--EP_H_Rsnd1 es el nodo que ha retransmitido este mensaje

				if EP_H_Creat = EP_H_Rsnd1 then
					Neighbors.Put(Vecinos, EP_H_Creat, Hora, Success);
					--Si el mensaje que te llega tiene tanto en el campo del 
					--creat como en el campo del Rsnd eso significa que fue
					--el mismo nodo el que creo el mensaje y que no lo creo
					--ningun otro. Es la primera vez que ha debido de llegar
					--dicho mensaje por tanto debemos guardar al creador
					--como vecino.
				end if;
			end if;

			Latest_Msgs.Get(Mensajes, EP_H_Creat, Seq_Anterior, Success_Get);
			--Este booleano sirve para avisar al Logout que ya no existe ese vecino por 
			--lo tanto eso quiere decir que se ha formado un ciclo y ha llegado un mensaje
			--de tipo logout repetido, por lo que lo tenemos que obviar. Ya que el Success_Get
			--sera False.
			--El siguiente Success nos servira simplemente para ejecutar los demás tipos


			if Seq_Anterior + 1 = Seq_N or Success_Get = False then
			--Debug.Put_Line ("MENSAJE DEL PRESENTE --> Asentimos, retransmitimos y procesamos", Pantalla.Blanco);

			--Esta condicion se cumple siempre y cuando una de las dos afirmaciones se
			--cumpla, siendo estas las siguientes:
			--	+Que el numero de secuencia del mensaje nuevo sea menor
			--	 al numero de secuencia del mensaje anterior del mismo nodo
			--	+Que no exista ningun mensaje de este end_point por lo que
			--	 tenemos que reenviar dicho mensaje y guardarlo en nuestras tablas.
				
				
				if Tipo = CM.Init then
					Latest_Msgs.Put(Mensajes, EP_H_Creat, Seq_N, Success);
					EP_R_Creat := LLU.End_Point_Type'Input (P_Buffer);
					Nick := ASU.Unbounded_String'Input (P_Buffer);
					Debug.Put("RCV Init ", Pantalla.Amarillo);
					Debug.Put_Line ("Creat: " & Direccion_IP(EP_H_Creat) &
					   	   	" Seq: " & Seq_N_T'Image(Seq_N) &
						   	" Rsnd: " & Direccion_IP(EP_H_Rsnd1) &
						   	" ... " & ASU.To_String(Nick)); 
					EP_H_Acker := To;
					Enviar_ACK (EP_H_Creat, Seq_N, EP_H_Acker, EP_H_Rsnd1);
					EP_H_Rsnd := To; --Ahora el Rsnd es el nodo al que llega el mensaje a retransmitir
					Vecino_Nuevo (Nick, Mi_Nick, EP_H_Rsnd, EP_R_Creat, Seq_N, EP_H_Rsnd1, EP_H_Creat);
					Reenviar_Init (Seq_N, EP_H_Rsnd, EP_H_Creat, Mi_Nick, EP_H_Rsnd1, EP_R_Creat, Nick);
					
				elsif Tipo = CM.Confirm then
					Latest_Msgs.Put(Mensajes, EP_H_Creat, Seq_N, Success);
					Nick := ASU.Unbounded_String'Input (P_Buffer);
					Debug.Put("RCV Confirm ", Pantalla.Amarillo);
					Debug.Put_Line ("Creat: " & Direccion_IP(EP_H_Creat) &
						   	" Seq: " & Seq_N_T'Image(Seq_N) &
						   	" Rsnd: " & Direccion_IP(EP_H_Rsnd1) &
						   	" " & ASU.To_String(Nick)); 
					EP_H_Acker := To;
					Enviar_ACK (EP_H_Creat, Seq_N, EP_H_Acker, EP_H_Rsnd1);
					EP_H_Rsnd := To;
					Debug.Put_Line (ASU.To_String(Nick) & " ha entrado en el chat", Pantalla.Blanco);
					Debug.Put_Line ("      Añadimos a latest_messages: " & 
				        		Direccion_IP(EP_H_Creat) &
				        		" Seq: " & Seq_N_T'Image(Seq_N));
					Reenviar_Confirm(Seq_N, EP_H_Rsnd, EP_H_Creat, Nick, EP_H_Rsnd1);
					
				elsif Tipo = CM.Logout then
					Latest_Msgs.Put(Mensajes, EP_H_Creat, Seq_N, Success);
					if Success_Get = True then
						Nick := ASU.Unbounded_String'Input (P_Buffer);
						Confirm_Sent := Boolean'Input (P_Buffer);
						Debug.Put("RCV Logout ", Pantalla.Amarillo);
						Debug.Put_Line ("Creat: " & Direccion_IP(EP_H_Creat) &
							   	" Seq: " & Seq_N_T'Image(Seq_N) &
							   	" Rsnd: " & Direccion_IP(EP_H_Rsnd1) &
							   	" " & ASU.To_String(Nick) & 
							   	" " & Boolean'Image(Confirm_Sent));
						EP_H_Acker := To;
						Enviar_ACK (EP_H_Creat, Seq_N, EP_H_Acker, EP_H_Rsnd1);
						EP_H_Rsnd := To;
						Reenviar_Logout(Seq_N, EP_H_Rsnd, EP_H_Creat, Nick, EP_H_Rsnd1, Confirm_Sent);
					else 
						Nick := ASU.Unbounded_String'Input (P_Buffer);
						Confirm_Sent := Boolean'Input (P_Buffer);
						Debug.Put("RCV Logout ", Pantalla.Amarillo);
						Debug.Put_Line ("Creat: " & Direccion_IP(EP_H_Creat) &
							   	" Seq: " & Seq_N_T'Image(Seq_N) &
							   	" Rsnd: " & Direccion_IP(EP_H_Rsnd1) &
							   	" " & ASU.To_String(Nick) & 
							   	" " & Boolean'Image(Confirm_Sent));
						Debug.Put("      NOFLOOD Logout ", Pantalla.Amarillo);
						Debug.Put_Line(" Creat: " & Direccion_IP(EP_H_Creat) &
							  	" Seq: " & Seq_N_T'Image(Seq_N) &
							  	" Rsnd: " & Direccion_IP(EP_H_Rsnd1) &
							  	" " & ASU.To_String(Nick) & 
							  	" " & Boolean'Image(Confirm_Sent));
						EP_H_Acker := To;
						Enviar_ACK (EP_H_Creat, Seq_N, EP_H_Acker, EP_H_Rsnd1);	
					end if;

				elsif Tipo = CM.Writer then
					Latest_Msgs.Put(Mensajes, EP_H_Creat, Seq_N, Success);
					Nick := ASU.Unbounded_String'Input (P_Buffer);
					Text := ASU.Unbounded_String'Input (P_Buffer);
					Debug.Put("RCV Writer ", Pantalla.Amarillo);
					Debug.Put_Line ("Creat: " & Direccion_IP(EP_H_Creat) &
						   	" Seq: " & Seq_N_T'Image(Seq_N) &
						   	" Rsnd: " & Direccion_IP(EP_H_Rsnd1) &
						   	" " & ASU.To_String(Nick) & 
						   	" " &  ASU.To_String(Text));
					EP_H_Acker := To;
					Enviar_ACK (EP_H_Creat, Seq_N, EP_H_Acker, EP_H_Rsnd1);
					EP_H_Rsnd := To;
					Debug.Put_Line("      Añadimos a latest_messages: " & 
				       			Direccion_IP(EP_H_Creat) 
				       			& " Seq: " & Seq_N_T'Image(Seq_N));
					Reenviar_Writer(Seq_N, Seq_Anterior, EP_H_Rsnd, EP_H_Creat, Nick, EP_H_Rsnd1, Text);
					TIO.Put_Line(ASU.To_String(Nick) & ": " &  ASU.To_String(Text));

				elsif Tipo = CM.Ack then
					Recibir_ACK(EP_H_Acker, EP_H_Creat, Seq_N);
				else
					TIO.Put_Line("Ha cascao");
					LLU.Finalize;
				end if;
			elsif Seq_Anterior >= Seq_N then
				--Debug.Put_Line ("MENSAJE DEL PASADO --> Solamente Asentimos", Pantalla.Azul_Claro);
				if Tipo = CM.Init then
					EP_R_Creat := LLU.End_Point_Type'Input (P_Buffer);
					Nick := ASU.Unbounded_String'Input (P_Buffer);
					Debug.Put ("RCV Init", Pantalla.Azul_Claro);
					Debug.Put_Line (" Creat: " & Direccion_IP(EP_H_Creat) &
						   	" Seq: " & Seq_N_T'Image(Seq_N) &
						   	" Rsnd: " & Direccion_IP(EP_H_Rsnd1) &
						   	" ... " & ASU.To_String(Nick), Pantalla.Azul_Claro); 
					Debug.Put ("      NOFLOOD Init", Pantalla.Azul_Claro);
					Debug.Put_Line (" Creat: " & Direccion_IP(EP_H_Creat) &
						  	" Seq: " & Seq_N_T'Image(Seq_N) &
						  	" Rsnd: " & Direccion_IP(EP_H_Rsnd1) &
						  	" ... " & ASU.To_String(Nick), Pantalla.Azul_Claro);
					EP_H_Acker := To;
					Enviar_ACK (EP_H_Creat, Seq_N, EP_H_Acker, EP_H_Rsnd1);

				elsif Tipo = CM.Writer then
					Nick := ASU.Unbounded_String'Input (P_Buffer);
					Text := ASU.Unbounded_String'Input (P_Buffer);
					Debug.Put ("RCV Writer", Pantalla.Azul_Claro);
					Debug.Put_Line (" Creat: " & Direccion_IP(EP_H_Creat) &
						  	" Seq: " & Seq_N_T'Image(Seq_N) &
						   	" Rsnd: " & Direccion_IP(EP_H_Rsnd1) &
						   	" " & ASU.To_String(Nick) & 
						  	" " &  ASU.To_String(Text), Pantalla.Azul_Claro);
					Debug.Put ("      NOFLOOD Writer", Pantalla.Azul_Claro);
					Debug.Put_Line (" Creat: " & Direccion_IP(EP_H_Creat) &
						  	" Seq: " & Seq_N_T'Image(Seq_N) &
						  	" Rsnd: " & Direccion_IP(EP_H_Rsnd1) &
						  	" " & ASU.To_String(Nick) & 
						  	" " &  ASU.To_String(Text), Pantalla.Azul_Claro);
					EP_H_Acker := To;
					Enviar_ACK (EP_H_Creat, Seq_N, EP_H_Acker, EP_H_Rsnd1);

				elsif Tipo = CM.Confirm then
					Nick := ASU.Unbounded_String'Input (P_Buffer);
					Debug.Put ("RCV Confirm", Pantalla.Azul_Claro);
					Debug.Put_Line (" Creat: " & Direccion_IP(EP_H_Creat) &
						   	" Seq: " & Seq_N_T'Image(Seq_N) &
						   	" Rsnd: " & Direccion_IP(EP_H_Rsnd1) &
						  	" " & ASU.To_String(Nick), Pantalla.Azul_Claro); 
					Debug.Put ("      NOFLOOD Confirm ", Pantalla.Azul_Claro);
					Debug.Put_Line (" Creat: " & Direccion_IP(EP_H_Creat) &
						  	" Seq: " & Seq_N_T'Image(Seq_N) &
						  	" Rsnd: " & Direccion_IP(EP_H_Rsnd1) &
						  	" " & ASU.To_String(Nick), Pantalla.Azul_Claro); 
					EP_H_Acker := To;
					Enviar_ACK (EP_H_Creat, Seq_N, EP_H_Acker, EP_H_Rsnd1);
					
				elsif Tipo = CM.Ack then
					Recibir_ACK (EP_H_Acker, EP_H_Creat, Seq_N);
				end if;
				
			elsif Seq_Anterior + 2 <= Seq_N then
				--Debug.Put_Line ("MENSAJE DEL FUTURO --> Solamente Retransmitimos por inundación", Pantalla.Magenta);
				
				if Tipo = CM.Init then
					EP_R_Creat := LLU.End_Point_Type'Input (P_Buffer);
					Nick := ASU.Unbounded_String'Input (P_Buffer);
					Debug.Put ("RCV Init", Pantalla.Magenta);
					Debug.Put_Line (" Creat: " & Direccion_IP(EP_H_Creat) &
					   	   	" Seq: " & Seq_N_T'Image(Seq_N) &
						   	" Rsnd: " & Direccion_IP(EP_H_Rsnd1) &
						   	" ... " & ASU.To_String(Nick), Pantalla.Magenta); 
					EP_H_Rsnd := To; --Ahora el Rsnd es el nodo al que llega el mensaje a retransmitir
					Reenviar_Init (Seq_N, EP_H_Rsnd, EP_H_Creat, Mi_Nick, EP_H_Rsnd1, EP_R_Creat, Nick);
					
				elsif Tipo = CM.Confirm then
					Nick := ASU.Unbounded_String'Input (P_Buffer);
					Debug.Put ("RCV Confirm", Pantalla.Magenta);
					Debug.Put_Line (" Creat: " & Direccion_IP(EP_H_Creat) &
						   	" Seq: " & Seq_N_T'Image(Seq_N) &
						   	" Rsnd: " & Direccion_IP(EP_H_Rsnd1) &
						   	" " & ASU.To_String(Nick), Pantalla.Magenta); 
					EP_H_Rsnd := To;
					Reenviar_Confirm(Seq_N, EP_H_Rsnd, EP_H_Creat, Nick, EP_H_Rsnd1);
					
				elsif Tipo = CM.Writer then
					Nick := ASU.Unbounded_String'Input (P_Buffer);
					Text := ASU.Unbounded_String'Input (P_Buffer);
					Debug.Put ("RCV Writer", Pantalla.Magenta);
					Debug.Put_Line (" Creat: " & Direccion_IP(EP_H_Creat) &
						   	" Seq: " & Seq_N_T'Image(Seq_N) &
						   	" Rsnd: " & Direccion_IP(EP_H_Rsnd1) &
						   	" " & ASU.To_String(Nick) & 
						   	" " &  ASU.To_String(Text), Pantalla.Magenta);
					EP_H_Rsnd := To;
					Reenviar_Writer(Seq_N, Seq_Anterior, EP_H_Rsnd, EP_H_Creat, Nick, EP_H_Rsnd1, Text);
					
				elsif Tipo = CM.Logout then
					Nick := ASU.Unbounded_String'Input (P_Buffer);
					Confirm_Sent := Boolean'Input (P_Buffer);
					Debug.Put ("RCV Logout", Pantalla.Magenta);
					Debug.Put_Line (" Creat: " & Direccion_IP(EP_H_Creat) &
						   	" Seq: " & Seq_N_T'Image(Seq_N) &
						   	" Rsnd: " & Direccion_IP(EP_H_Rsnd1) &
						   	" " & ASU.To_String(Nick) & 
						   	" " & Boolean'Image(Confirm_Sent), Pantalla.Magenta);
					EP_H_Rsnd := To;
					Reenviar_Logout(Seq_N, EP_H_Rsnd, EP_H_Creat, Nick, EP_H_Rsnd1, Confirm_Sent);
					
				elsif Tipo = CM.Ack then
					Recibir_ACK(EP_H_Acker, EP_H_Creat, Seq_N);
				end if;
			end if;

		end Handler;
   
end Chat_Handlers;
