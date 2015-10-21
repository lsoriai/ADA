with Lower_Layer_UDP;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with Ada.Exceptions;
with Ada.Calendar;
with Ada.Command_Line;
with chat_messages;
with Chat_Handlers;
with debug;
with Pantalla;

procedure chat_peer is

	package LLU renames Lower_Layer_UDP;
        package ASU renames Ada.Strings.Unbounded;
        package ACL renames Ada.Command_Line;
	package TIO renames Ada.Text_IO;
	package CM renames Chat_messages;
	package AC renames Ada.Calendar;
	package CH renames Chat_Handlers;
	
	use type CM.Message_Type;
	use type LLU.End_Point_Type;
	use type ASU.Unbounded_String;
	use type CH.Seq_N_T;
	
	procedure Crear_Init(EP_H: LLU.End_Point_Type;
			     EP_R: LLU.End_Point_Type;
			     Nick: ASU.Unbounded_String;
			     Seq_N: CH.Seq_N_T) is
		Tipo: CM.Message_Type := CM.Init;
		EP_H_Creat: LLU.End_Point_Type := EP_H;
		EP_R_Creat: LLU.End_Point_Type := EP_R;
		EP_H_Rsnd: LLU.End_Point_Type := EP_H;
		Buffer: aliased LLU.Buffer_Type(1024);
   	    	Array_Vecinos: CH.Neighbors.Keys_Array_Type := CH.Neighbors.Get_Keys(CH.Vecinos);
   	   	Num_Vecinos: Natural := CH.Neighbors.Map_Length(CH.Vecinos);
	begin
		Debug.Put("Añadimos a Latest_Mesages ");
		Debug.Put(CH.Direccion_Ip(EP_H));
		Debug.Put_Line(" Seq: " & CH.Seq_N_T'Image(Seq_N));
		Debug.Put("FLOOD Init ", Pantalla.Amarillo);
		Debug.Put("Creat ", Pantalla.Azul);
		Debug.Put(CH.Direccion_Ip(EP_H));
		Debug.Put(" Rsnd ", Pantalla.Azul);
		Debug.Put(CH.Direccion_Ip(EP_H));
		Debug.Put_Line(" ... " & ASU.To_String(Nick));
		LLU.Reset(Buffer);
		CM.Message_Type'Output (Buffer'access, Tipo);
		LLU.End_Point_Type'Output (Buffer'access, EP_H_Creat);
		CH.Seq_N_T'Output (Buffer'access, Seq_N);
		LLU.End_Point_Type'Output (Buffer'access, EP_H_Rsnd);
		LLU.End_Point_Type'Output (Buffer'access, EP_R_Creat);
		ASU.Unbounded_String'Output (Buffer'access, Nick);
		for I in 1..Num_Vecinos loop
			Debug.Put("      Send to: ", Pantalla.Rojo);
			Debug.Put_Line(CH.Direccion_IP(Array_Vecinos(I)), Pantalla.Rojo);
			LLU.Send(Array_Vecinos(I), Buffer'Access);
		end loop;
		TIO.New_Line;
	end Crear_Init;
	
	procedure Enviar_Confirm (EP_H: LLU.End_Point_Type;
				  Nick: ASU.Unbounded_String;
				  Seq_N: CH.Seq_N_T) is
		Tipo: CM.Message_Type := CM.Confirm;
		EP_H_Creat: LLU.End_Point_Type := EP_H;
		EP_H_Rsnd: LLU.End_Point_Type := EP_H;
		Buffer: aliased LLU.Buffer_Type(1024);
		Array_Vecinos: CH.Neighbors.Keys_Array_Type := CH.Neighbors.Get_Keys(CH.Vecinos);
   	   	Num_Vecinos: Natural := CH.Neighbors.Map_Length(CH.Vecinos);
		begin
			Debug.Put("Añadimos a Latest_Mesages ");
			Debug.Put(CH.Direccion_Ip(EP_H));
			Debug.Put_Line(" Seq: " & CH.Seq_N_T'Image(Seq_N));
			Debug.Put("FLOOD Confirm ", Pantalla.Amarillo);
			Debug.Put("Creat: ", Pantalla.Azul);
			Debug.Put(CH.Direccion_IP(EP_H));
			Debug.Put(" Seq: " & CH.Seq_N_T'Image(Seq_N));
			Debug.Put(" Rsnd: ", Pantalla.Azul);
			Debug.Put(CH.Direccion_IP(EP_H));
			Debug.Put_Line(" " & ASU.To_String(Nick)); 
			LLU.Reset(Buffer);
			CM.Message_Type'Output (Buffer'access, Tipo);
			LLU.End_Point_Type'Output (Buffer'access, EP_H_Creat);
			CH.Seq_N_T'Output (Buffer'access, Seq_N);
			LLU.End_Point_Type'Output (Buffer'access, EP_H_Rsnd);
			ASU.Unbounded_String'Output (Buffer'access, Nick);
			for I in 1..Num_Vecinos loop
				Debug.Put("      Send to: ", Pantalla.Rojo);
				Debug.Put_Line(CH.Direccion_IP(Array_Vecinos(I)), Pantalla.Rojo);
				LLU.Send(Array_Vecinos(I), Buffer'Access);
			end loop;
			TIO.New_Line;
		end Enviar_Confirm;
		
	procedure Enviar_Logout (Confirm_Sent: Boolean;
				 Nick: ASU.Unbounded_String;
				 EP_H: LLU.End_Point_Type;
				 Seq_N: in out CH.Seq_N_T) is
		Tipo: CM.Message_Type := CM.Logout;
		EP_H_Creat: LLU.End_Point_Type := EP_H;
		Buffer: aliased LLU.Buffer_Type(1024);
		EP_H_Rsnd: LLU.End_Point_Type := EP_H;
		Array_Vecinos: CH.Neighbors.Keys_Array_Type := CH.Neighbors.Get_Keys(CH.Vecinos);
   	   	Num_Vecinos: Natural := CH.Neighbors.Map_Length(CH.Vecinos);
		begin
			Debug.Put("FLOOD Logout ", Pantalla.Amarillo);
			Debug.Put("Creat ", Pantalla.Azul);
			Debug.Put(CH.Direccion_Ip(EP_H));
			Debug.Put("Seq: " & CH.Seq_N_T'Image(Seq_N));
			Debug.Put(" Rsnd ", Pantalla.Azul);
			Debug.Put(CH.Direccion_Ip(EP_H));
			Debug.Put(" " & ASU.To_String(CH.Mi_Nick));
			Debug.Put_Line(" " & Boolean'Image(Confirm_Sent));
			LLU.Reset(Buffer);
			CM.Message_Type'Output (Buffer'Access, Tipo);
			LLU.End_Point_Type'Output (Buffer'Access, EP_H_Creat);
			CH.Seq_N_T'Output (Buffer'Access, Seq_N);
			LLU.End_Point_Type'Output (Buffer'Access, EP_H_Rsnd);
			ASU.Unbounded_String'Output (Buffer'Access, Nick);
			Boolean'Output(Buffer'Access, Confirm_Sent);
			for I in 1..Num_Vecinos loop
				Debug.Put("      Send to: ", Pantalla.Rojo);
				Debug.Put_Line(CH.Direccion_IP(Array_Vecinos(I)), Pantalla.Rojo);
				LLU.Send(Array_Vecinos(I), Buffer'Access);
			end loop;
		end Enviar_Logout;

	procedure Enviar_Writer (EP_H: LLU.End_Point_Type;
				 Seq_N: in out CH.Seq_N_T;
				 Nick: ASU.Unbounded_String;
				 Text: ASU.Unbounded_String) is
		Tipo: CM.Message_Type := CM.Writer;
		EP_H_Creat: LLU.End_Point_Type := EP_H;
		Buffer: aliased LLU.Buffer_Type(1024);
		EP_H_Rsnd: LLU.End_Point_Type := EP_H;
		Array_Vecinos: CH.Neighbors.Keys_Array_Type := CH.Neighbors.Get_Keys(CH.Vecinos);
   	   	Num_Vecinos: Natural := CH.Neighbors.Map_Length(CH.Vecinos);
		begin
			Debug.Put("Añadimos a Latest_Mesages ");
			Debug.Put(CH.Direccion_Ip(EP_H));
			Debug.Put_Line(" Seq: " & CH.Seq_N_T'Image(Seq_N));
			Debug.Put("FLOOD Writer ", Pantalla.Amarillo);
			Debug.Put(" Creat: ", Pantalla.Azul);
			Debug.Put(CH.Direccion_IP(EP_H));
			Debug.Put_Line(" Seq: " & CH.Seq_N_T'Image(Seq_N));
			Debug.Put(" Rsnd: ", Pantalla.Azul);
			Debug.Put(CH.Direccion_IP(EP_H));
			Debug.Put_Line(" " & ASU.To_String(Nick) & " " & ASU.To_String(Text)); 
			LLU.Reset(Buffer);
			CM.Message_Type'Output (Buffer'access, Tipo);
			LLU.End_Point_Type'Output (Buffer'access, EP_H_Creat);
			CH.Seq_N_T'Output (Buffer'access, Seq_N);
			LLU.End_Point_Type'Output (Buffer'access, EP_H_Rsnd);
			ASU.Unbounded_String'Output (Buffer'access, Nick);
			ASU.Unbounded_String'Output (Buffer'access, Text);
			for I in 1..Num_Vecinos loop
				Debug.Put("      Send to: ", Pantalla.Rojo);
				Debug.Put_Line(CH.Direccion_IP(Array_Vecinos(I)), Pantalla.Rojo);
				LLU.Send(Array_Vecinos(I), Buffer'Access);
			end loop;
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
	Vecinos: CH.Neighbors.Prot_Map;
	Seq_N: CH.Seq_N_T := 0;
	Mensajes: CH.Latest_Msgs.Prot_Map;
	Buffer: aliased LLU.Buffer_Type(1024);
	Comentario: ASU.Unbounded_String;
	Array_Vecinos: CH.Neighbors.Keys_Array_Type := CH.Neighbors.Get_Keys(CH.Vecinos);
   	Num_Vecinos: Natural := CH.Neighbors.Map_Length(CH.Vecinos);
	EP: LLU.End_Point_Type;
	Nick: ASU.Unbounded_String;
	Tipo: CM.Message_Type;
	EP_H_Reject: LLU.End_Point_Type;
	
begin
	if ACL.Argument_Count /= 2 and
	   ACL.Argument_Count /= 4 and
	   ACL.Argument_Count /= 6 then
		raise Usage_Error;
	end if;
	CH.Mi_Nick := ASU.To_Unbounded_String(ACL.Argument(2));
	--Construcción del end point y atarse a un puerto
	EP_H := LLU.Build(LLU.To_IP(LLU.Get_Host_Name), Natural'Value(ACL.Argument(1)));
	LLU.Bind (EP_H, CH.Handler'Access);
	LLU.Bind_Any(EP_R);
	--Analizamos los casos
	if ACL.Argument_Count = 2 then
		--No tenemos que enviar el init porque no tenemos vecinos
		TIO.New_Line;
		Debug.Put_Line("No hacemos protocolo de admision pues no tenemos contactos iniciales...");
		CH.Latest_Msgs.Put(CH.Mensajes, EP_H, Seq_N, Success);
		Debug.Put_Line("Peer-Chat v1.0", Pantalla.Amarillo);
		Debug.Put_Line("==============", Pantalla.Amarillo);
		TIO.Put_Line("Entramos en el chat con el Nick: " & ASU.To_String(CH.Mi_Nick));
		TIO.Put_Line(".h para help");

	elsif ACL.Argument_Count = 4 then
		--Construimos el end point del vecino y lo añadimos a la tabla de vecinos
		EP_Vecino1 := LLU.Build(LLU.To_IP(ACL.Argument(3)), Natural'Value(ACL.Argument(4)));
		CH.Neighbors.Put(CH.Vecinos, EP_Vecino1, Hora, Success);
		Debug.Put_Line("Añadimos a neightbors " & CH.Direccion_Ip(EP_Vecino1));
		TIO.New_Line;
		Debug.Put_Line("Iniciamos protocolo de admision...");
		--Añadimos a la tabla de secuncia el end point de la propia máquina
		--Y su campo de numero de sequencia es 1 porque envia el init
		Seq_N := Seq_N + 1;
		CH.Latest_Msgs.Put(CH.Mensajes, EP_H, Seq_N, Success);
		Crear_Init(EP_H, EP_R, CH.Mi_Nick, Seq_N);
	else
		--Construimos los end points de los vecinos y los añadimos a la tabla como vecinos
		EP_Vecino1 := LLU.Build(LLU.To_IP(ACL.Argument(3)), Natural'Value(ACL.Argument(4)));
		EP_Vecino2 := LLU.Build(LLU.To_IP(ACL.Argument(5)), Natural'Value(ACL.Argument(6)));
		CH.Neighbors.Put(CH.Vecinos, EP_Vecino1, Hora, Success);
		CH.Neighbors.Put(CH.Vecinos, EP_Vecino2, Hora, Success);
		Debug.Put_Line("Añadimos a neightbors " & CH.Direccion_Ip(EP_Vecino1));
		Debug.Put_Line("Añadimos a neightbors " & CH.Direccion_Ip(EP_Vecino2));
		TIO.New_Line;
		Debug.Put_Line("Iniciamos protocolo de admision...");
		--Añadimos a la tabla de secuncia el end point de la propia máquina
		--Y su campo de numero de sequencia es 1 porque envia el init
		Seq_N := Seq_N + 1;
		CH.Latest_Msgs.Put(CH.Mensajes, EP_H, Seq_N, Success);
		Crear_Init(EP_H, EP_R, CH.Mi_Nick, Seq_N);
	end if;
	if ACL.Argument_Count = 4 or ACL.Argument_Count = 6 then
		LLU.Reset(Buffer);
		LLU.Receive(EP_R, Buffer'Access, 2.0, Expired);
		--Si no expira el tiempo es porque no nos "han rechazado" por tanto enviamos el confirm
		Seq_N := Seq_N + 1;
		if Expired then
			Enviar_Confirm (EP_H, CH.Mi_Nick, Seq_N);
			Debug.Put_Line("Fin del protocolo de admisión");
			TIO.New_Line;
			Debug.Put_Line("Peer-Chat v1.0", Pantalla.Amarillo);
			Debug.Put_Line("==============", Pantalla.Amarillo);
			TIO.Put_Line("Entramos en el chat con el Nick: " & ASU.To_String(CH.Mi_Nick));
			TIO.Put_Line(".h para help");
		else
			Confirm_Sent := False;
			Tipo := CM.Message_Type'Input (Buffer'Access);
			EP_H_Reject := LLU.End_Point_Type'Input (Buffer'Access);
			Nick := ASU.Unbounded_String'Input (Buffer'Access);
			Debug.Put_Line("RCV Reject " & CH.Direccion_IP(EP_H), Pantalla.Rojo);
			Debug.Put_Line("Usuario rechazado porque " & CH.Direccion_Ip(EP_H) &
				       " está usando el mismo nick", Pantalla.Blanco);
			TIO.New_Line;
			Enviar_Logout (Confirm_Sent, CH.Mi_Nick, EP_H, Seq_N);
			TIO.New_Line;
			Debug.Put_Line("Fin del protocolo de Admisión");
			LLU.Finalize;
		end if;
	end if;

	loop 
		Comentario := ASU.To_Unbounded_String(TIO.Get_Line);

--                                         TABLA DE COMANDOS
-- ====================================================================================================
		if Comentario = ".h" or Comentario = ".help" then
			Debug.Put_Line("        Comandos            Efectos", Pantalla.Rojo);
			Debug.Put_Line("        =================   =======", Pantalla.Rojo);
			Debug.Put_Line("        .nb .neighbors      lista de vecinos", Pantalla.Rojo);
			Debug.Put_Line("        .lm .latest_msgs    lista de los "
				       & "últimos mensajes recibidos", Pantalla.Rojo);
			Debug.Put_line("        .debug              toggle para info de debug", Pantalla.Rojo);
			Debug.Put_Line("        .wai .whoami        muestra en pantalla: "
				       & "Nick / EP_H / EP_R", Pantalla.Rojo);
			Debug.Put_Line("        .prompt             toggle para mostrar prompt", Pantalla.Rojo);
			Debug.Put_Line("        .h .help            muestra esta información "
				       & "de ayuda", Pantalla.Rojo);
			Debug.Put_Line("        .salir              termina" &
				       " el programa", Pantalla.Rojo);
		end if;

		if Comentario = ".nb" or Comentario = ".neighbors" then
			Debug.Put_Line("        Neighbors", Pantalla.Rojo);
			Debug.Put_Line("        ------------------------", Pantalla.Rojo);
			for I in 1..Num_Vecinos loop
				Debug.Put_Line("[ (" & CH.Direccion_IP(Array_Vecinos(I)) & ")", Pantalla.Rojo);
				--FALTA LA HORA, FHECA, AÑO
			end loop;
		end if;

		if Comentario = ".lm" or Comentario = ".latest_msgs" then
			Debug.Put_Line("        Latest_Msgs", Pantalla.Rojo);
			Debug.Put_Line("        ------------------------", Pantalla.Rojo);
			Debug.Put_Line("[ (" & CH.Direccion_IP(EP_H) & "), " & CH.Seq_N_T'Image(Seq_N) & "]", Pantalla.Rojo);
			for I in 1..Num_Vecinos loop
				TIO.Put("JHOM·");
				EP := Array_Vecinos(I);
				CH.Latest_Msgs.Get(CH.Mensajes, EP, Seq_N, Success);
				Debug.Put_Line("        [ (" & CH.Direccion_IP(EP) & "), " & CH.Seq_N_T'Image(Seq_N)
					       & "]", Pantalla.Rojo);
			end loop;
		end if;

		if Comentario = ".debug" then
			Debug.Put_Line("Descativada información de debug", Pantalla.Rojo);
		end if;

		if Comentario = ".wai" or Comentario = ".whoami" then
			Debug.Put_Line("Nick: " & ASU.To_String(CH.Mi_Nick) & " / " &
				       "EP_H: " & CH.Direccion_IP(EP_H) & " / " &
				       "EP_R: " & CH.Direccion_IP(EP_R), Pantalla.Rojo);
		end if;

		if Comentario = ".prompt" then
		--QUE HACER?
			TIO.Put("NK");
		end if;
--                                   FIN DE LA TABLA DE COMANDOS
-- =====================================================================================================

		if Comentario /= ".salir" then
			Seq_N := Seq_N + 1;
			Enviar_Writer (EP_H, Seq_N, CH.Mi_Nick, Comentario);
		else
			Confirm_Sent := True;
			Seq_N := Seq_N + 1;
			Enviar_Logout (Confirm_Sent, CH.Mi_Nick, EP_H, Seq_N);
			TIO.New_Line;
			LLU.Finalize;
		end if;
		exit when Comentario = ".salir";
	end loop;
exception		
	when Usage_Error =>
		Ada.Text_IO.Put_Line ("Argumentos no validos" & " <Puerto> <Nick>");
	when Ex:others =>
		TIO.Put_Line("Excepcion improvista: " &
			     Ada.Exceptions.Exception_Name(Ex) & " en: " &
		             Ada.Exceptions.Exception_Message(Ex));
	LLU.Finalize;	
	
end chat_peer;

