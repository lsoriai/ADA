--Leire Soria Indiano

with Ada.Text_IO;

package body Users is
   package TIO renames Ada.Text_IO;

   use type AC.Time;

	--procedure Inicializar (Lista
 	
 	procedure Buscar_Cliente (Lista: Clientes;
 				  Nick: ASU.Unbounded_String;
 				  Tope: Natural;
 				  Cliente: Natural;
 				  Repetido:  out Boolean) is
 		N: Natural := 1;
		Encontrado : Boolean := False;
 		begin
 			while N <= Tope and not Encontrado loop
				if Lista(N).Nick = Nick then
					Encontrado := True;
					Repetido := True;
				else
					Encontrado := False;
					Repetido := False;
					N := N + 1;
				end if;
			end loop;
			
 		end Buscar_Cliente;
 		
	procedure Calcular_Tiempo (Lista: Clientes; Tope: Natural; Tiempo: in out AC.Time) is
		begin
			for N in 1..Tope loop
				if N = 1 then
					Tiempo := Lista(N).Tiempo;
				else
					if Tiempo < Lista(N).Tiempo then
						Tiempo := Tiempo;
					else 
						Tiempo := Lista(N).Tiempo;
					end if;
				end if;
			end loop;
		end Calcular_Tiempo;

 	
 	procedure Aniadir_Cliente (Lista: in out Clientes;
 				   Nick: ASU.Unbounded_String;
 				   Tope: Natural;
 				   Client_EP_Handler: LLU.End_Point_Type;
 				   Cliente: in out Natural) is
		Tiempo_Menor: AC.Time;
		Tiempo_Ahora: AC.Time;
		Guardado: Boolean := False;
		Tipo: CM.Message_Type;
		Nick_Servidor: ASU.Unbounded_String;
		Comentario: ASU.Unbounded_String;
		Buffer: aliased LLU.Buffer_Type(1024);
		EP: LLU.End_Point_Type;
		Nick_Expulsado: ASU.Unbounded_String;
 		begin
 			for I in 1..Tope loop
 				if Lista(I).Existe = False and Tope <= 50 and Guardado = False then
	 				Lista(I).Nick := Nick;
		 			Lista(I).EP_Handler := Client_EP_Handler;
		 			Lista(I).Existe := True;
		 			Lista(I).Tiempo := AC.Clock;
		 			Guardado := True;
		 			Cliente := Cliente + 1;
		 			--Construimos el mensaje que informa de la llegada del nuevo cliente
		 			Tipo := CM.Server;
			 		Nick_Servidor := ASU.To_Unbounded_String("Servidor");
					Comentario := Nick & ASU.To_Unbounded_String(" ha entrado en el chat");
					LLU.Reset(Buffer);
					CM.Message_Type'Output(Buffer'Access, Tipo);
					ASU.Unbounded_String'Output(Buffer'Access, Nick_Servidor);
					ASU.Unbounded_String'Output(Buffer'Access, Comentario);
					--Se lo enviamos a todos los clientes excepto al que acaba de llegar
					for I in 1..Tope loop
						if Lista(I).EP_Handler /= Client_EP_Handler and Lista(I).Existe  = True then
							EP := Lista(I).EP_Handler;
							LLU.Send(EP, Buffer'Access);
						end if;
					end loop;
	 			end if;
	 		end loop;
	 		if Guardado = False then
				Calcular_Tiempo(Lista, Tope, Tiempo_Menor);
				Tiempo_Ahora := AC.Clock;
				for N in 1..Tope loop
					--Descubrimos cual es el cliente a expulsar
					if Tiempo_Menor = Lista(N).Tiempo and Lista(N).Existe = True then
						Nick_Expulsado := Lista(N).Nick;
						--Construimos el mensaje que informa de la expulsion de ese cliente
						Tipo := CM.Server;
						Nick_Servidor := ASU.To_Unbounded_String("Servidor");
						Comentario := Nick_Expulsado & ASU.To_Unbounded_String(" ha sido expulsado del chat");
						LLU.Reset(Buffer);
						CM.Message_Type'Output(Buffer'Access, Tipo);
						ASU.Unbounded_String'Output(Buffer'Access, Nick_Servidor);
						ASU.Unbounded_String'Output(Buffer'Access, Comentario);
						--Mandamos el mensaje-expulsion a todos los clientes
						for I in 1..Tope loop
							if Lista(I).Existe = True then
								EP := Lista(I).EP_Handler;
								LLU.Send(EP, Buffer'Access);
							end if;
						end loop;
						Cliente := Cliente - 1;
						--Añadimos el nuevo cliente en un campos com valor existente = False
						Lista(N).Nick := Nick;
						Lista(N).EP_Handler := Client_EP_Handler;
			 			Lista(N).Existe := True;
			 			Lista(N).Tiempo := Tiempo_Ahora;
			 			Cliente := Cliente + 1;
			 			--Construimos el mensaje que informa de la llegada del nuevo cliente
			 			Tipo := CM.Server;
			 			Nick_Servidor := ASU.To_Unbounded_String("Servidor");
						Comentario := Nick & ASU.To_Unbounded_String(" ha entrado en el chat");
						LLU.Reset(Buffer);
						CM.Message_Type'Output(Buffer'Access, Tipo);
						ASU.Unbounded_String'Output(Buffer'Access, Nick_Servidor);
						ASU.Unbounded_String'Output(Buffer'Access, Comentario);
						--Se lo enviamos a todos los clientes excepto al que acaba de llegar
						for I in 1..Tope loop
							if Lista(I).EP_Handler /= Client_EP_Handler and Lista(I).Existe = True then
								EP := Lista(I).EP_Handler;
								LLU.Send(EP, Buffer'Access);
							end if;
						end loop;
					end if;
				end loop;
				
			end if;
	 	end Aniadir_Cliente;
	 	
--	procedure Mostrar_Lista (Lista: in Clientes; Tope: Natural) is
--	 	begin
--		TIO.Put_Line("LISTA DE CLIENTES:");
--			for I in 1..Tope loop
--				if Lista(I).Existe then
--					TIO.Put_Line(LLU.Image(Lista(I).EP_Handler) & " - " & ASU.To_String(Lista(I).Nick));
--				else
--					TIO.Put_Line("*** vacío ***");
--				end if;
--			end loop;
--			TIO.Put_Line("FIN DE LA LISTA");
--		end Mostrar_Lista;
	 	   
	procedure Buscar_Nick (Client_EP_Handler: LLU.End_Point_Type;
			      Lista: Clientes;
			      Nick: in out ASU.Unbounded_String;
			      Tope: Natural;
			      Cliente: Natural) is
		begin
			for N in 1..Tope loop
				if Client_EP_Handler = Lista(N).EP_Handler and Lista(N).Existe = True then
					Nick := Lista(N).Nick;
				end if;
			end loop;
		end Buscar_Nick;
		
	procedure Actualizar (Lista: in out Clientes;
			      Nick: ASU.Unbounded_String;
			      Tope: Natural;
			      Cliente: Natural) is
		begin
			for I in 1..Tope loop
				if Nick = Lista(I).Nick and Lista(I).Existe = True then
					Lista(I).Tiempo := AC.Clock;
				end if;
			end loop;
		end Actualizar;


	procedure Enviar_Clientes (Lista: Clientes;
				   Nick: ASU.Unbounded_String;
				   Comentario: ASU.Unbounded_String;
				   P_Buffer: access LLU.Buffer_Type;
				   Tope: Natural;
				   Cliente: Natural) is
		Client_EP_Handler : LLU.End_Point_Type;
		Tipo: CM.Message_Type;
		begin
			Tipo := CM.Server;
			LLU.Reset(P_Buffer.all);
			CM.Message_Type'Output (P_Buffer, Tipo);
			ASU.Unbounded_String'Output (P_Buffer, Nick);
			ASU.Unbounded_String'Output (P_Buffer, Comentario);
			for N in 1..Tope loop
				if Nick /= Lista(N).Nick and Lista(N).Existe = True then
					Client_EP_Handler := Lista(N).EP_Handler;
					LLU.Send(Client_EP_Handler, P_Buffer);
				end if;
			end loop;
		end Enviar_Clientes;
		
		
	procedure Borrar_Cliente (Lista: in out Clientes;
				  Client_EP_Handler: LLU.End_Point_Type;
				  Tope: Natural;
				  Cliente: Natural) is
		begin
			for I in 1..Tope loop
				if Client_EP_Handler = Lista(I).EP_Handler and Lista(I).Existe = True then
					Lista(I).Nick := ASU.Null_Unbounded_String;
			 		Lista(I).EP_Handler := null;
			 		Lista(I).Existe := False;
			 		Lista(I).Tiempo := AC.Clock;
			 	end if;
			 end loop;
		end Borrar_Cliente;

	procedure Enviar_Salida (Lista: Clientes;
				Nick: ASU.Unbounded_String;
		  		P_Buffer: access LLU.Buffer_Type;
				Tope: Natural;
				EP_Handler: LLU.End_Point_Type;
				Cliente: Natural) is
		Tipo: CM.Message_Type;
		Nick_Servidor: ASU.Unbounded_String;
		Comentario: ASU.Unbounded_String;
		Client_EP_Handler : LLU.End_Point_Type;
		begin
			Tipo := CM.Server;
			Nick_Servidor := ASU.To_Unbounded_String("Servidor");
			Comentario := Nick & ASU.To_Unbounded_String(" ha abandonado el chat");
			LLU.Reset(P_Buffer.all);
			CM.Message_Type'Output (P_Buffer, Tipo);
			ASU.Unbounded_String'Output (P_Buffer, Nick_Servidor);
			ASU.Unbounded_String'Output (P_Buffer, Comentario);
			for N in 1..Tope loop
				if Client_EP_Handler /= Lista(N).EP_Handler and Lista(N).Existe = True then
					Client_EP_Handler := Lista(N).EP_Handler;
					LLU.Send(Client_EP_Handler, P_Buffer);
				end if;
			end loop;
		end Enviar_Salida;
			
			
 
 end Users;
