--Leire Soria Indiano

--                                     ÍNDICE
--======================================================================================

--	Direccion_IP (Extrae la IP y el Puerto de un end-Point)..................27
--      Enviar_Reject (Envia expulsión por nick igual)...........................58
--	Reenviar_Init (Reenvia el init excepto al que lo mandó)..................76
--	Es_Un_Vecino_Nuevo (Examina si es nuevo. Devuelve Boolean)...............134
--	Reenviar_Confirm (Reenvia el confirm excepto al que lo mandó)............151
--	Reenviar_Logout (Reenvia el logout excepto al que lo mandó)..............197
--	Reenviar_Writer (Reenvia el writer excepto al que lo mandó)..............246
--	Handler (Procedure principal)............................................293

--======================================================================================


package body Chat_Handlers is
	 
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
   			Posicion := ASU.Index(Frase, "1");
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
   		
   		
   	--Procedure que reenvia el init a todos los vecinos excepto al que te lo envió.
	--Envio por inundación	
   	procedure Reenviar_Init (Seq_N: Seq_N_T;
   	                         EP_H_Rsnd: LLU.End_Point_Type;
   	                         EP_H_Creat: LLU.End_Point_Type;
   	                         Mi_Nick: ASU.Unbounded_String;
   	                         EP_H_Rsnd1: LLU.End_Point_Type;
				 EP_R_Creat: LLU.End_Point_Type;
				 Nick: ASU.Unbounded_String) is
   	    Buffer: aliased LLU.Buffer_Type(1024);
   	    Array_Vecinos: Neighbors.Keys_Array_Type := Neighbors.Get_Keys(Vecinos);
   	    Num_Vecinos: Natural := Neighbors.Map_Length(Vecinos);
   	    Tipo: CM.Message_Type := CM.Init;
   		begin
			Debug.Put("RCV Init ", Pantalla.Amarillo);
			Debug.Put ("Creat: ", Pantalla.Azul);
			Debug.Put(Direccion_IP(EP_H_Creat));
			Debug.Put(" Seq: " & Seq_N_T'Image(Seq_N));
			Debug.Put(" Rsnd: ", Pantalla.Azul);
			Debug.Put(Direccion_IP(EP_H_Rsnd1)); 
			Debug.Put_Line(" ... " & ASU.To_String(Nick)); 
			if Mi_Nick = Nick then
				Debug.Put("      SEND Reject ", Pantalla.Amarillo);
				Debug.Put(Direccion_Ip(EP_H_Rsnd));
				Debug.Put_Line(" " & ASU.To_String(Nick));
				Enviar_Reject(Nick, EP_H_Rsnd, EP_R_Creat);
				Debug.Put_Line("      Añadimos a latest_messages: " & Direccion_IP(EP_H_Creat) 
					       & " Seq: " & Seq_N_T'Image(Seq_N));
			elsif Mi_Nick /= Nick and EP_H_Creat = EP_H_Rsnd1 then
				Debug.Put_Line("      Añadimos a neighbors: " & Direccion_IP(EP_H_Creat));
				Neighbors.Print_Map(Vecinos);
				Debug.Put_Line("      Añadimos a latest_messages: " & Direccion_IP(EP_H_Creat) 
						& " Seq: " & Seq_N_T'Image(Seq_N));
				Latest_Msgs.Print_Map(Mensajes);
			end if;
   			LLU.Reset(Buffer);
			CM.Message_Type'Output (Buffer'Access, Tipo);
			LLU.End_Point_Type'Output (Buffer'Access, EP_H_Creat);
			Seq_N_T'Output (Buffer'Access, Seq_N);
			LLU.End_Point_Type'Output (Buffer'Access, EP_H_Rsnd);
			LLU.End_Point_Type'Output (Buffer'Access, EP_R_Creat);
			ASU.Unbounded_String'Output (Buffer'Access, Nick);
			Debug.Put("      FLOOD Init ", Pantalla.Amarillo);
			Debug.Put(" Creat: ", Pantalla.Azul);
			Debug.Put(Direccion_IP(EP_H_Creat));
			Debug.Put(" Seq: " & Seq_N_T'Image(Seq_N));
			Debug.Put(" Rsnd: ", Pantalla.Azul);
			Debug.Put(Direccion_IP(EP_H_Rsnd));
			Debug.Put_Line(" ... " & ASU.To_String(Nick)); 
			for I in 1..Num_Vecinos loop
				if Array_Vecinos(I) /= EP_H_Rsnd1 then
					Debug.Put("      Send to: ", Pantalla.Rojo);
					Debug.Put_Line(Direccion_IP(Array_Vecinos(I)), Pantalla.Rojo);
					LLU.Send(Array_Vecinos(I), Buffer'Access);
				end if;
				TIO.New_Line;

			end loop;
		end Reenviar_Init;
		
		
	--Procedure que nos dice si un EP es nuevo o no
	--procedure Es_Un_Vecino_Nuevo (EP_H_Creat: LLU.End_Point_Type;
	--			      Nuevo: out Boolean) is
	--	Array_Vecinos: Neighbors.Keys_Array_Type := Neighbors.Get_Keys(Vecinos);
	--	Num_Vecinos: Natural := Neighbors.Map_Length(Vecinos);
	--	begin
	--		for I in 1..Num_Vecinos loop
	--			if EP_H_Creat = Array_Vecinos(I) then
	--				Nuevo := False;
	--			else
	--				Nuevo := True;
	--			end if;
	--		end loop;
	--	end Es_Un_Vecino_Nuevo;

	--Procedure que reenviar la confirmacion de un nuevo nodo a todos aquellos vecinos
	--exceptuando a aquel que se lo mandó. Envía este mensaje ya que este nodo no tiene
	--ningun problema con el nick del nuevo modo y el suyo
	procedure Reenviar_Confirm (Seq_N: Seq_N_T;
   	                            EP_H_Rsnd: LLU.End_Point_Type;
   	                            EP_H_Creat: LLU.End_Point_Type;
   	                            Nick: ASU.Unbounded_String;
   	                            EP_H_Rsnd1: LLU.End_Point_Type) is
   	    Buffer: aliased LLU.Buffer_Type(1024);
   	    Array_Vecinos: Neighbors.Keys_Array_Type := Neighbors.Get_Keys(Vecinos);
   	    Num_Vecinos: Natural := Neighbors.Map_Length(Vecinos);
   	    Tipo: CM.Message_Type := CM.Confirm;
   		begin
			Debug.Put("RCV Confirm ", Pantalla.Amarillo);
			Debug.Put ("Creat: ", Pantalla.Azul);
			Debug.Put(Direccion_IP(EP_H_Creat));
			Debug.Put(" Seq: " & Seq_N_T'Image(Seq_N));
			Debug.Put(" Rsnd: ", Pantalla.Azul);
			Debug.Put(Direccion_IP(EP_H_Rsnd1)); 
			Debug.Put_Line(" " & ASU.To_String(Nick)); 
			Debug.Put_Line(ASU.To_String(Nick) & " ha entrado en el chat", Pantalla.Blanco);
			Debug.Put_Line("      Añadimos a latest_messages: " & Direccion_IP(EP_H_Creat) 
					& " Seq: " & Seq_N_T'Image(Seq_N));
   			LLU.Reset(Buffer);
			CM.Message_Type'Output (Buffer'Access, Tipo);
			LLU.End_Point_Type'Output (Buffer'Access, EP_H_Creat);
			Seq_N_T'Output (Buffer'Access, Seq_N);
			LLU.End_Point_Type'Output (Buffer'Access, EP_H_Rsnd);
			ASU.Unbounded_String'Output (Buffer'Access, Nick);
			Debug.Put("      FLOOD Confirm ", Pantalla.Amarillo);
			Debug.Put(" Creat: ", Pantalla.Azul);
			Debug.Put(Direccion_IP(EP_H_Creat));
			Debug.Put(" Seq: " & Seq_N_T'Image(Seq_N));
			Debug.Put(" Rsnd: ", Pantalla.Azul);
			Debug.Put(Direccion_IP(EP_H_Rsnd));
			Debug.Put_Line(" " & ASU.To_String(Nick)); 
			for I in 1..Num_Vecinos loop
				if Array_Vecinos(I) /= EP_H_Rsnd1 then
					Debug.Put("      Send to: ", Pantalla.Rojo);
					Debug.Put_Line(Direccion_IP(Array_Vecinos(I)), Pantalla.Rojo);
					LLU.Send(Array_Vecinos(I), Buffer'Access);
				end if;
				TIO.New_Line;
			end loop;
		end Reenviar_Confirm;

			
	--Procedure que envia a todos los vecino, excepto a aquel que te lo envió, que un 
	--nodo ha sido rechazado por tener el mismo nick que uno de los existentes
	procedure Reenviar_Logout(Seq_N: Seq_N_T;
				  EP_H_Rsnd: LLU.End_Point_Type;
				  EP_H_Creat: LLu.End_Point_Type;
				  Nick: ASU.Unbounded_String;
				  EP_H_Rsnd1: LLu.End_Point_Type;
				  Confirm_Sent: Boolean) is
		Buffer: aliased LLU.Buffer_Type(1024);
	   	Array_Vecinos: Neighbors.Keys_Array_Type := Neighbors.Get_Keys(Vecinos);
		Array_Mensajes: Latest_Msgs.Keys_Array_Type := Latest_Msgs.Get_Keys(Mensajes);
	   	Num_Vecinos: Natural := Neighbors.Map_Length(Vecinos);
	   	Tipo: CM.Message_Type := CM.Logout;
		Success: Boolean;
		Value: AC.Time;
		begin
			Neighbors.Print_Map(Vecinos);
			Debug.Put("RCV Logout ", Pantalla.Amarillo);
			Debug.Put ("Creat: ", Pantalla.Azul);
			Debug.Put(Direccion_IP(EP_H_Creat));
			Debug.Put_Line(" Seq: " & Seq_N_T'Image(Seq_N));
			Debug.Put(" Rsnd: ", Pantalla.Azul);
			Debug.Put(Direccion_IP(EP_H_Rsnd1));
			Debug.Put_Line((" ") & ASU.To_String(Nick) & (" ") & Boolean'Image(Confirm_Sent));
			LLU.Reset(Buffer);
			CM.Message_Type'Output (Buffer'Access, Tipo);
			LLU.End_Point_Type'Output (Buffer'Access, EP_H_Creat);
			Seq_N_T'Output (Buffer'Access, Seq_N);
			LLU.End_Point_Type'Output (Buffer'Access, EP_H_Rsnd);
			ASU.Unbounded_String'Output (Buffer'Access, Nick);
			Boolean'Output (Buffer'Access, Confirm_Sent);
			Neighbors.Get(Vecinos, EP_H_Creat, Value, Success);
			if Success = True then
				Neighbors.Delete(Vecinos, EP_H_Creat, Success);
				Debug.Put_Line("Borramos de neighbors a " & Direccion_IP(EP_H_Creat));
				TIO.Put_Line("Borrado en caso de ser vecino");
				Neighbors.Print_Map(Vecinos);
			end if;
			TIO.Put_Line("Antes de borrar en latest_msgs");
			Latest_Msgs.Print_Map(Mensajes);
			Latest_Msgs.Delete(Mensajes, EP_H_Creat, Success);
			Debug.Put_Line("Borramos de latest_msgs a " & Direccion_IP(EP_H_Creat));
			TIO.Put_Line("Borrado en cualquiera de los casos");
			Latest_Msgs.Print_Map(Mensajes);
			if Confirm_Sent = True then
				Debug.Put_Line(ASU.To_String(Nick) & " ha abandonado el chat");
			end if;
			for I in 1..Num_Vecinos loop
				if Array_Vecinos(I) /= EP_H_Rsnd1 then
					Debug.Put("      Send to: ", Pantalla.Rojo);
					Debug.Put_Line(Direccion_IP(Array_Vecinos(I)), Pantalla.Rojo);
					LLU.Send(Array_Vecinos(I), Buffer'Access);
				end if;
			end loop;
			Debug.Put("      FLOOD Logout ", Pantalla.Amarillo);
			Debug.Put(" Creat: ", Pantalla.Azul);
			Debug.Put(Direccion_IP(EP_H_Creat));
			Debug.Put_Line(" Seq: " & Seq_N_T'Image(Seq_N));
			Debug.Put(" Rsnd: ", Pantalla.Azul);
			Debug.Put(Direccion_IP(EP_H_Rsnd));
			Debug.Put_Line(" " & ASU.To_String(Nick) & " " & Boolean'Image(Confirm_Sent));
		end Reenviar_Logout;

	--Procedure que reenvia a todos los nodos, excepto a aquel que lo mandó
	--un mensaje writer
	procedure Reenviar_Writer(Seq_N: Seq_N_T;
				  EP_H_Rsnd: LLU.End_Point_Type;
				  EP_H_Creat: LLU.End_Point_Type;
				  Nick: ASU.Unbounded_String;
				  EP_H_Rsnd1: LLU.End_Point_Type;
				  Text: ASU.Unbounded_String) is
		Buffer: aliased LLU.Buffer_Type(1024);
   	    	Array_Vecinos: Neighbors.Keys_Array_Type := Neighbors.Get_Keys(Vecinos);
   	   	Num_Vecinos: Natural := Neighbors.Map_Length(Vecinos);
   	    	Tipo: CM.Message_Type := CM.Writer;
		begin
			Debug.Put("RCV Writer ", Pantalla.Amarillo);
			Debug.Put ("Creat: ", Pantalla.Azul);
			Debug.Put(Direccion_IP(EP_H_Creat));
			Debug.Put(" Seq: " & Seq_N_T'Image(Seq_N));
			Debug.Put(" Rsnd: ", Pantalla.Azul);
			Debug.Put(Direccion_IP(EP_H_Rsnd1)); 
			Debug.Put_Line(" " & ASU.To_String(Nick) & " " &  ASU.To_String(Text));
			TIO.Put_Line(ASU.To_String(Nick) & ": " &  ASU.To_String(Text));
			Debug.Put_Line("      Añadimos a latest_messages: " & Direccion_IP(EP_H_Creat) 
					& " Seq: " & Seq_N_T'Image(Seq_N));
			LLU.Reset(Buffer);
			CM.Message_Type'Output (Buffer'Access, Tipo);
			LLU.End_Point_Type'Output (Buffer'Access, EP_H_Creat);
			Seq_N_T'Output (Buffer'Access, Seq_N);
			LLU.End_Point_Type'Output (Buffer'Access, EP_H_Rsnd);
			ASU.Unbounded_String'Output (Buffer'Access, Nick);
			ASU.Unbounded_String'Output (Buffer'Access, Text);
			for I in 1..Num_Vecinos loop
				if Array_Vecinos(I) /= EP_H_Rsnd1 then
					Debug.Put("      Send to: ", Pantalla.Rojo);
					Debug.Put_Line(Direccion_IP(Array_Vecinos(I)), Pantalla.Rojo);
					LLU.Send(Array_Vecinos(I), Buffer'Access);
				end if;
				TIO.New_Line;
			end loop;
			Debug.Put("      FLOOD Writer ", Pantalla.Amarillo);
			Debug.Put(" Creat: ", Pantalla.Azul);
			Debug.Put(Direccion_IP(EP_H_Creat));
			Debug.Put(" Seq: " & Seq_N_T'Image(Seq_N));
			Debug.Put(" Rsnd: ", Pantalla.Azul);
			Debug.Put(Direccion_IP(EP_H_Rsnd));
			Debug.Put_Line(" " & ASU.To_String(Nick) & " " &  ASU.To_String(Text));
			TIO.New_Line;
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
	Seq_N: Seq_N_T;
	Hora: AC.Time := AC.Clock;
	Success: Boolean;
	Success_Get: Boolean;
	Seq_Anterior: Seq_N_T;
	Confirm_Sent : Boolean;
	Text: ASU.Unbounded_String;
		begin
			Tipo := CM.Message_Type'Input(P_Buffer);
			EP_H_Creat := LLU.End_Point_Type'Input (P_Buffer);
			Seq_N := Seq_N_T'Input (P_Buffer);
			EP_H_Rsnd1 := LLU.End_Point_Type'Input (P_Buffer);
			if EP_H_Creat = EP_H_Rsnd1 then
				Neighbors.Put(Vecinos, EP_H_Creat, Hora, Success);
				Neighbors.Print_Map(Vecinos);
			end if;
			Latest_Msgs.Get(Mensajes, EP_H_Creat, Seq_Anterior, Success_Get);
			--Este booleano sirve para avisar al Logout que ya no existe ese vecino por 
			--lo tanto eso quiere decir que se ha formado un ciclo y ha llegado un mensaje
			--de tipo logout repetido, por lo que lo tenemos que obviar.
			--El siguiente Success nos servira para simplemente para ejecutar los demás tipos
			if Seq_Anterior < Seq_N or Success_Get = False then
				Latest_Msgs.Put(Mensajes, EP_H_Creat, Seq_N, Success);
				if Tipo = CM.Init then
					EP_R_Creat := LLU.End_Point_Type'Input (P_Buffer);
					Nick := ASU.Unbounded_String'Input (P_Buffer);
					EP_H_Rsnd := To;
					Reenviar_Init (Seq_N, EP_H_Rsnd, EP_H_Creat, Mi_Nick, EP_H_Rsnd1, EP_R_Creat, Nick);
				elsif Tipo = CM.Confirm then
					Nick := ASU.Unbounded_String'Input (P_Buffer);
					EP_H_Rsnd := To;
					Reenviar_Confirm(Seq_N, EP_H_Rsnd, EP_H_Creat, Nick, EP_H_Rsnd1);
				elsif Tipo = CM.Logout then
					if Success_Get = True then
						Nick := ASU.Unbounded_String'Input (P_Buffer);
						Confirm_Sent := Boolean'Input (P_Buffer);
						EP_H_Rsnd := To;
						Reenviar_Logout(Seq_N, EP_H_Rsnd, EP_H_Creat, Nick, EP_H_Rsnd1, Confirm_Sent);
					else 
						Nick := ASU.Unbounded_String'Input (P_Buffer);
						Confirm_Sent := Boolean'Input (P_Buffer);
						Debug.Put("RCV Logout ", Pantalla.Amarillo);
						Debug.Put ("Creat: ", Pantalla.Azul);
						Debug.Put(Direccion_IP(EP_H_Creat));
						Debug.Put_Line(" Seq: " & Seq_N_T'Image(Seq_N));
						Debug.Put(" Rsnd: ", Pantalla.Azul);
						Debug.Put(Direccion_IP(EP_H_Rsnd1));
						Debug.Put_Line((" ") & ASU.To_String(Nick) & (" ") & Boolean'Image(Confirm_Sent));
						Debug.Put("      FLOOD Logout ", Pantalla.Amarillo);
						Debug.Put(" Creat: ", Pantalla.Azul);
						Debug.Put(Direccion_IP(EP_H_Creat));
						Debug.Put_Line(" Seq: " & Seq_N_T'Image(Seq_N));
						Debug.Put(" Rsnd: ", Pantalla.Azul);
						Debug.Put(Direccion_IP(EP_H_Rsnd1));
						Debug.Put_Line(" " & ASU.To_String(Nick) & " " & Boolean'Image(Confirm_Sent));
					end if;
				elsif Tipo = CM.Writer then
					Nick := ASU.Unbounded_String'Input (P_Buffer);
					Text := ASU.Unbounded_String'Input (P_Buffer);
					EP_H_Rsnd := To;
					Reenviar_Writer(Seq_N, EP_H_Rsnd, EP_H_Creat, Nick, EP_H_Rsnd1, Text);
				else
					TIO.Put_Line("Ha cascao");
					LLU.Finalize;
				end if;
			elsif Seq_Anterior = Seq_N then
				if Tipo = CM.Init then
					EP_H_Rsnd := To;
					EP_R_Creat := LLU.End_Point_Type'Input (P_Buffer);
					Nick := ASU.Unbounded_String'Input (P_Buffer);
					Debug.Put("RCV Init ", Pantalla.Amarillo);
					Debug.Put ("Creat: ", Pantalla.Azul);
					Debug.Put(Direccion_IP(EP_H_Creat));
					Debug.Put(" Seq: " & Seq_N_T'Image(Seq_N));
					Debug.Put(" Rsnd: ", Pantalla.Azul);
					Debug.Put(Direccion_IP(EP_H_Rsnd1)); 
					Debug.Put_Line(" ... " & ASU.To_String(Nick)); 
					Debug.Put("NOFLOOD Init", Pantalla.Amarillo);
					Debug.Put(" Creat: ", Pantalla.Azul);
					Debug.Put(Direccion_IP(EP_H_Creat));
					Debug.Put(" Seq: " & Seq_N_T'Image(Seq_N));
					Debug.Put(" Rsnd: ", Pantalla.Azul);
					Debug.Put(Direccion_IP(EP_H_Rsnd));
					Debug.Put_Line(" ... " & ASU.To_String(Nick));
				elsif Tipo = CM.Writer then
					Nick := ASU.Unbounded_String'Input (P_Buffer);
					Text := ASU.Unbounded_String'Input (P_Buffer);
					Debug.Put("RCV Writer ", Pantalla.Amarillo);
					Debug.Put ("Creat: ", Pantalla.Azul);
					Debug.Put(Direccion_IP(EP_H_Creat));
					Debug.Put(" Seq: " & Seq_N_T'Image(Seq_N));
					Debug.Put(" Rsnd: ", Pantalla.Azul);
					Debug.Put(Direccion_IP(EP_H_Rsnd1)); 
					Debug.Put_Line(" " & ASU.To_String(Nick) & " " &  ASU.To_String(Text));
					TIO.Put_Line(ASU.To_String(Nick) & ": " &  ASU.To_String(Text));
					Debug.Put("      NOFLOOD Writer ", Pantalla.Amarillo);
					Debug.Put(" Creat: ", Pantalla.Azul);
					Debug.Put(Direccion_IP(EP_H_Creat));
					Debug.Put(" Seq: " & Seq_N_T'Image(Seq_N));
					Debug.Put(" Rsnd: ", Pantalla.Azul);
					Debug.Put(Direccion_IP(EP_H_Rsnd1));
					Debug.Put_Line(" " & ASU.To_String(Nick) & " " &  ASU.To_String(Text));
				elsif Tipo = CM.Confirm then
					Nick := ASU.Unbounded_String'Input (P_Buffer);
					Debug.Put("RCV Confirm ", Pantalla.Amarillo);
					Debug.Put ("Creat: ", Pantalla.Azul);
					Debug.Put(Direccion_IP(EP_H_Creat));
					Debug.Put(" Seq: " & Seq_N_T'Image(Seq_N));
					Debug.Put(" Rsnd: ", Pantalla.Azul);
					Debug.Put(Direccion_IP(EP_H_Rsnd1)); 
					Debug.Put_Line(" " & ASU.To_String(Nick)); 
					Debug.Put("      NOFLOOD Confirm ", Pantalla.Amarillo);
					Debug.Put(" Creat: ", Pantalla.Azul);
					Debug.Put(Direccion_IP(EP_H_Creat));
					Debug.Put(" Seq: " & Seq_N_T'Image(Seq_N));
					Debug.Put(" Rsnd: ", Pantalla.Azul);
					Debug.Put(Direccion_IP(EP_H_Rsnd1));
					Debug.Put_Line(" " & ASU.To_String(Nick)); 
				end if;
			end if;

		end Handler;
   
end Chat_Handlers;
