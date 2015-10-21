--Leire Soria Indiano
with Lower_Layer_UDP;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with Ada.Exceptions;
with Ada.Command_Line;
with chat_messages;
with Users;

procedure chat_server is
   	package LLU renames Lower_Layer_UDP;
   	package ASU renames Ada.Strings.Unbounded;
   	package ACL renames Ada.Command_Line;
	package TIO renames Ada.Text_IO;
	package CM renames chat_messages;
	
	use type CM.Message_Type;
	use type LLU.End_Point_Type;
	use type ASU.Unbounded_String;

	
   	Server_EP: LLU.End_Point_Type;
   	Buffer: aliased LLU.Buffer_Type(1024);
  	Comentario: ASU.Unbounded_String;
  	Expired: Boolean := False;
   	Usage_Error: exception;
	Lista_Clientes: Users.Clientes;
	Mensaje: CM.Mensaje;
	i: Natural := 0;
	Nick: ASU.Unbounded_String;
	Tope: Natural;
	Client_EP_Handler: LLU.End_Point_Type;
	Tipo: CM.Message_Type;
	Client_EP: LLU.End_Point_Type;
	Repetido: Boolean;
	Acogido: Boolean;
	Num_Clientes_T: Natural := 0;
		

begin

	if ACL.Argument_Count /= 2 then
		raise Usage_Error;
	end if;

	Server_EP := LLU.Build(LLU.To_IP(LLU.Get_Host_Name), Natural'Value(ACL.Argument(1)));
   	LLU.Bind (Server_EP);
   	Tope := Natural'Image(ACL.Argument(2));
	loop
		LLU.Reset(Buffer);
 		LLU.Receive (Server_EP, Buffer'Access, 1000.0, Expired);
 		if Expired then
         		Ada.Text_IO.Put_Line ("Plazo expirado, vuelvo a intentarlo");
     		else
			Tipo := CM.Message_Type'Input (Buf'Access);
			Client_EP := LLU.End_Point_Type'Input (Buf'Access);
        		Client_EP_Handler := LLU.End_Point_Type'Input (Buf'Access);
         		Nick := ASU.Unbounded_String'Input (Buf'Access);
         		if Tipo = CM.Init then
				Users.Buscar_Cliente (Lista_Clientes, Nick, Tope, Repetido);
				if Repetido = True then
					Tipo := CM.Welcome;
					Acogido := False;
					LLU.Reset(Buf);
					CM.Message_Type'Output(Buf'Access, Tipo);
					Boolean'Output(Buf'Access, Acogido);
					LLU.Send(Client_EP_Handler, Buf'Access);
					TIO.Put_Line("Recibido mensaje inicial de " &
						      ASU.To_String(Nick) & ": RECHAZADO."); 
				else
					Num_Clientes_T := Num_Clientes_T + 1;
					Users.Aniadir_Cliente(Lista_Clientes, Nick, Tope, Client_EP_Handler, Num_Clientes_T);
					TIO.Put_Line("Recibido mensaja inicial de: " &
						     ASU.To_String(Nick) & "ACEPTADO");
				end if;
			end if;
		end if;
	end loop;

  
exception
	when Ex:others => 
		TIO.Put_Line("EXcepción imprevista: " &
		Ada.Exceptions.Exception_Name(Ex) & "en: " &
		Ada.Exceptions.Exception_Message(Ex));
		
	when Usage_Error =>
		Ada.Text_IO.Put_Line ("Argumentos no validos");

	LLU.Finalize;
end chat_server;
