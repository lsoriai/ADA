--Leire Soria Indiano
with Ada.Unchecked_Deallocation;
with Ada.Calendar;

package body Users is
	use type Ada.Calendar.Time;
	use type CM.Message_Type;
	use type LLU.End_Point_Type;
	use type ASU.Unbounded_String;

	procedure Free is new Ada.Unchecked_Deallocation (Datos_Cliente, Clientes);
 	
 	procedure Buscar_Cliente (Lista: Clientes;
 				  Nick: ASU.Unbounded_String;
 				  Tope: Natural;
 				  Cliente: Natural;
 				  Repetido: in out Boolean) is
 		N: Natural := 1;
		Encontrado : Boolean := False;
		P_Aux : Clientes;
 		begin
			P_Aux := Lista;
 			while N <= Cliente and not Encontrado and P_Aux /= null loop --Posicion indica cuantas celdas hay
				if P_Aux.Nick = Nick then
					Encontrado := True;
					Repetido := True;
				else
					Encontrado := False;
					Repetido := False;
					P_Aux := P_Aux.Next;
				end if;
				N := N + 1;
			end loop;

 		end Buscar_Cliente;
 		
 	procedure Calcular_Tiempo (Lista: Clientes;
 				   Cliente: Natural;
 				   Tiempo: in out AC.Time) is
 		P_Aux: Clientes := Lista;
 		P_Anterior: Clientes;
 		N: Natural := 1;
 		begin
 			while N <= Cliente loop
 				if N = 1 then
 					Tiempo := P_Aux. Tiempo;
 					P_Anterior := P_Aux;
 					P_Aux := P_Aux.Next;
 				else
 					if P_Aux.Tiempo < Tiempo then
 						Tiempo := P_Aux.Tiempo;
 					else
 						Tiempo := Tiempo;
 					end if;
 				end if;
 				N := N + 1;
 			end loop;
 		end Calcular_Tiempo;
 		
 	procedure Enviar_Llegada (Lista: Clientes;
 				  Cliente: Natural;
 				  Nick: ASU.Unbounded_String;
 				  Client_EP_Handler: LLU.ENd_Point_Type) is
 		Tipo: CM.Message_Type;
		Nick_Servidor: ASU.Unbounded_String;
		Comentario: ASU.Unbounded_String;
		Buffer: aliased LLU.Buffer_Type(1024);
		N: Natural := 1;
		P_Aux: Clientes := Lista;
		EP: LLU.End_Point_Type;
 		begin
 			Tipo := CM.Server;
			Nick_Servidor := ASU.To_Unbounded_String("Servidor");
			Comentario := Nick & ASU.To_Unbounded_String(" ha entrado en el chat");
			LLU.Reset(Buffer);
			CM.Message_Type'Output(Buffer'Access, Tipo);
			ASU.Unbounded_String'Output(Buffer'Access, Nick_Servidor);
			ASU.Unbounded_String'Output(Buffer'Access, Comentario);	
			while N <= Cliente loop
				if P_Aux.Nick /= Nick then
					EP := P_Aux.EP_Handler;
					LLU.Send(EP, Buffer'Access);
					P_Aux := P_Aux.Next;
					N := N + 1;
				else
					P_Aux := P_Aux.Next;
					N := N + 1;
				end if;
			end loop;
		end Enviar_Llegada;
 		
 	
 	procedure Enviar_Expulsado (Lista: Clientes;
 				    Cliente: Natural;
 				    Nick_Expulsado: ASU.Unbounded_String;
 				    Client_EP_Handler: LLU.ENd_Point_Type) is
 		Tipo: CM.Message_Type;
		Nick_Servidor: ASU.Unbounded_String;
		Comentario: ASU.Unbounded_String;
		Buffer: aliased LLU.Buffer_Type(1024);
		N: Natural := 1;
		P_Aux: Clientes := Lista;
		EP: LLU.End_Point_Type;
 		begin
 			Tipo := CM.Server;
			Nick_Servidor := ASU.To_Unbounded_String("Servidor");
			Comentario := Nick_Expulsado & ASU.To_Unbounded_String(" ha sido expulsado del chat");
			LLU.Reset(Buffer);
			CM.Message_Type'Output(Buffer'Access, Tipo);
			ASU.Unbounded_String'Output(Buffer'Access, Nick_Servidor);
			ASU.Unbounded_String'Output(Buffer'Access, Comentario);	
			while N <= Cliente loop
				if P_Aux.EP_Handler /= Client_EP_Handler then
					EP := P_Aux.EP_Handler;
					LLU.Send(EP, Buffer'Access);
					P_Aux := P_Aux.Next;
					N := N + 1;
				else
					P_Aux := P_Aux.Next;
					N := N + 1;
				end if;
			end loop;
		end Enviar_Expulsado;
 	
 	procedure Expulsar_Cliente (Lista: in out Clientes;
 				    Cliente: Natural;
 				    Tiempo: AC.Time;
 				    Nick_Expulsado: in out ASU.Unbounded_String) is
 		N: Natural := 1;
 		Expulsado: Boolean := False;
 		P_Aux: Clientes := Lista;
 		P_Aux1: Clientes;
 		begin
 			while N <= Cliente and not Expulsado loop
 				if N = 1 and P_Aux.Tiempo = Tiempo then
					P_Aux1 := P_Aux.Next;
 					Nick_Expulsado := P_Aux.Nick;
 					Free(P_Aux);
					Lista := P_Aux1;
 					Expulsado := True;
 				elsif N /= 1 and P_Aux.Tiempo = Tiempo then
					P_Aux1.Next := P_Aux.Next;
 					Nick_Expulsado := P_Aux.Nick;
 					Free(P_Aux);
 					Expulsado := True;
 				else
					P_Aux1 := P_Aux;
 					P_Aux := P_Aux.Next;
 				end if;
 			end loop;
 		end Expulsar_Cliente;	
 				
 	procedure Aniadir_Nuevo (Lista: in out Clientes;
 				 Tope: Natural;
 				 Nick: ASU.Unbounded_String;
 				 Client_EP_Handler: LLU.End_Point_Type) is
 		P_Aux: Clientes := Lista;
 		P_Aux1: Clientes := null;
 		begin
 			P_Aux1 := new Datos_Cliente;
 			P_Aux1.Nick := Nick;
 			P_Aux1.EP_Handler := Client_EP_Handler;
 			P_Aux1.Tiempo := AC.Clock;
 			P_Aux1.Next := P_Aux;
 			Lista := P_Aux1;
 			P_Aux1 := null;
 			P_Aux := null;
 		end Aniadir_Nuevo;

	procedure Aniadir_Cliente (Lista: in out Clientes;
 				   Nick: ASU.Unbounded_String;
 				   Tope: Natural;
 				   Client_EP_Handler: LLU.End_Point_Type;
 				   Cliente: in out Natural) is
		Guardado: Boolean := False;
		Nick_Expulsado: ASU.Unbounded_String;
		Tiempo_Menor: AC.Time;
		N: Natural := 1;
		P_Aux1 : Clientes;    --Apunta a la celda de delante de P_Aux. Descubre si 
				      --hay null antes que P_aux y añade por el final
 		begin
			if Cliente = Tope then
				Calcular_Tiempo(Lista, Cliente, Tiempo_Menor);
				Expulsar_Cliente(Lista, Tope, Tiempo_Menor, Nick_Expulsado);
				Cliente := Cliente - 1;
				Enviar_Expulsado(Lista, Cliente, Nick_Expulsado, Client_EP_Handler); 
				Aniadir_Nuevo(Lista, Tope, Nick, Client_EP_Handler);
				Enviar_Llegada(Lista, Cliente, Nick, Client_EP_Handler);
				Cliente := Cliente + 1;
			else
				P_Aux1 := new Datos_Cliente;
				P_Aux1.Nick := Nick;
				P_Aux1.EP_Handler := Client_EP_Handler;
				P_Aux1.Tiempo := AC.Clock;
				if Lista /= null then
					P_Aux1.Next := Lista;
					Lista := P_Aux1;
				else
					P_Aux1.Next := null;
					Lista := P_Aux1;
				end if;
				Cliente := Cliente + 1;
				Enviar_Llegada(Lista, Cliente, Nick, Client_EP_Handler);
			end if;
	 	end Aniadir_Cliente;
	 	
	 procedure Buscar_Nick (Client_EP_Handler: LLU.End_Point_Type;
			        Lista: Clientes;
			        Nick: in out ASU.Unbounded_String;
			        Tope: Natural;
			        Cliente: Natural) is
		N: Natural := 1;
		P_Aux: Clientes := Lista;
		Encontrado: Boolean := False;
		begin
			while N <= Cliente and not Encontrado loop
				if P_Aux.EP_Handler = Client_EP_Handler then
					Nick := P_Aux.Nick;
					Encontrado := True;
				else
					P_Aux := P_Aux.Next;
				end if;
			end loop;
		end Buscar_Nick;
	
	procedure Actualizar (Lista: in out Clientes;
			      Nick: ASU.Unbounded_String;
			      Tope: Natural;
			      Cliente: Natural) is
		N: Natural := 1;
		P_Aux: Clientes := Lista;
		Encontrado: Boolean := False;
		begin
			while N <= Cliente and not Encontrado loop
				if P_Aux.Nick = Nick then
					P_Aux.Tiempo := AC.Clock;
					Encontrado := True;
				else
					P_Aux := P_Aux.Next;
				end if;
			end loop;
		end Actualizar;
		
	procedure Enviar_Clientes (Lista: Clientes;
				   Nick: ASU.Unbounded_String;
				   Comentario: ASU.Unbounded_String;
				   P_Buffer: access LLU.Buffer_Type;
				   Tope: Natural;
				   Cliente: Natural) is
		Tipo: CM.Message_Type;
		N: Natural := 1;
		P_Aux: Clientes := Lista;
		EP: LLU.End_Point_Type;
		begin
			Tipo := CM.Server;
			LLU.Reset(P_Buffer.all);
			CM.Message_Type'Output (P_Buffer, Tipo);
			ASU.Unbounded_String'Output (P_Buffer, Nick);
			ASU.Unbounded_String'Output (P_Buffer, Comentario);
			while N <= Cliente loop
				if P_Aux.Nick /= Nick then
					EP := P_Aux.EP_Handler;
					LLU.Send(EP, P_Buffer);
					P_Aux := P_Aux.Next;
					N := N + 1;
				else
					P_Aux := P_Aux.Next;
					N := N + 1;
				end if;
			end loop;
		end Enviar_Clientes;
	
	procedure Borrar_Cliente (Lista: in out Clientes;
				  Client_EP_Handler: LLU.End_Point_Type;
				  Tope: Natural;
				  Cliente: Natural) is
		N: Natural := 1;
 		Expulsado: Boolean := False;
 		P_Aux: Clientes := Lista;
 		P_Aux2: Clientes := Lista;
		begin
			while N <= Cliente and not Expulsado loop
 				if N = 1 and P_Aux.EP_Handler = Client_EP_Handler then
 					Lista := P_Aux.Next;
 					Free(P_Aux);
 					Expulsado := True;
 				elsif N /= 1 and P_Aux.EP_Handler = Client_EP_Handler then
 					P_Aux2.Next := P_Aux.Next;
 					Free(P_Aux);
 					Expulsado := True;
 				else
 					P_Aux2 := P_Aux;
 					P_Aux := P_Aux.Next;
 				end if;
 			end loop;
 				P_Aux2 := null;
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
		N: Natural := 1;
		EP:LLU.End_Point_Type;
		P_Aux: Clientes := Lista;
		begin
			Tipo := CM.Server;
			Nick_Servidor := ASU.To_Unbounded_String("Servidor");
			Comentario := Nick & ASU.To_Unbounded_String(" ha abandonado el chat");
			LLU.Reset(P_Buffer.all);
			CM.Message_Type'Output (P_Buffer, Tipo);
			ASU.Unbounded_String'Output (P_Buffer, Nick_Servidor);
			ASU.Unbounded_String'Output (P_Buffer, Comentario);
			while N <= Cliente loop
				if P_Aux.Nick /= Nick then
					EP := P_Aux.EP_Handler;
					LLU.Send(EP, P_Buffer);
					P_Aux := P_Aux.Next;
				end if;
				N := N + 1;
			end loop;
		end Enviar_Salida;
			

end Users;
