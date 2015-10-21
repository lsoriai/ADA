with Lower_Layer_UDP;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with Ada.Exceptions;
with Ada.Calendar;
with Ada.Command_Line;
with chat_messages;
with maps_g;
with Chat_Handlers;

procedure chat_peer is

   	package LLU renames Lower_Layer_UDP;
   	package ASU renames Ada.Strings.Unbounded;
   	package ACL renames Ada.Command_Line;
	package TIO renames Ada.Text_IO;
	package CM renames Chat_messages;
	package AC renames Ada.Calendar;
	package MP renames maps_g;
	package CH renames Chat_Handlers;
	
	use type CM.Message_Type;
	use type LLU.End_Point_Type;
	use type ASU.Unbounded_String;
	
	
	procedure Enviar_Init(EP_H: LLU.End_Point_Type,
			     EP_R: LLU.End_Point_Type
			     Nick: ASU.Unbounded_String,
			     EP_Vecino: LLU.ENd_Point_Type) is
		Tipo: CM.Message_Type := CM.Init;
		EP_H_Creat: LLU.End_Point_Type := EP_H;
		Buffer: aliased LLU.Buffer_Type(1024);
		EP_R_Creat: LLU.End_Point_Type := EP_H;
		EP_H_Rsnd: LLU.End_Point_Type := EP_H;
		begin
			CH.Seq_N_T := CH.Seq_N_T + 1;
			LLU.Reset(Buffer);
			CM.Message_Type'Output (Buffer'Access, Tipo);
			LLU.End_Point_Type'Output (Buffer'Access, EP_H_Creat);
			Natural'Value'Output (Buffer'Access, CH.Seq_N_T);
			LLU.End_Point_Type'Output (Buffer'Access, EP_H_Rsnd);
			LLU.End_Point_Type'Output (Buffer'Access, EP_R_Creat);
			ASU.Unbounded_String'Output (Buffer'Access, Nick);
			LLU.Send(EP_Vecino, Buffer'Access);
			TIO.Put_Line("Init enviado");
		end Crear_Init;
			
			
	Usage_Error: exception;
	EP_R: LLU.End_Point_Type;
	EP_H: LLU.End_Point_Type;
	EP_Vecino1: LLU.End_Point_Type;
	EP_Vecino2: LLU.End_Point_Type;
	Hora: AC.Time := AC.Clock;
	Success: Boolean;
	Nick: ASU.Unbounded_String;
	CH.Seq.N_T := 0;
	
begin
	if ACL.Argument_Count /= 2 and
	   ACL.Argument_Count /= 4 and
	   ACL.Argument_Count /= 6 then
		raise Usage_Error;
	end if;
	
	if ACL.Argument_Count = 2 then
		EP_H := LLU.Build(LLU.To_IP(LLU.Get_Host_Name), Natural'Value(ACL.Argument(1)));
		LLU.Bind (EP_H, Handler.Handler'Access);
		LLU.Bind_Any(EP_R);
	elsif ACL.Argument_Count = 4 then
		EP_H := LLU.Build(LLU.To_IP(LLU.Get_Host_Name), Natural'Value(ACL.Argument(1)));
		LLU.Bind (EP_H, Handler.Handler'Access);
		LLU.Bind_Any(EP_R);
		EP_Vecino1 := LLU.Build(LLU.To_IP(ACL.Argument(3)), Natural'Value(ACL.Argument(4)));
		CH.Neighbors.Put(CH.Vecinos, EP_Vecino1, Hora, Success);
		Nick := ASU.To_Unbounded_String(ACL.Argument(2))
		Enviar_Init(EP_H, EP_R, Nick, EP_Vecino1);
	else
		EP_H := LLU.Build(LLU.To_IP(LLU.Get_Host_Name), Natural'Value(ACL.Argument(1)));
		LLU.Bind (EP_H, Handler.Handler'Access);
		LLU.Bind_Any(EP_R);
		EP_Vecino1 := LLU.Build(LLU.To_IP(ACL.Argument(3)), Natural'Value(ACL.Argument(4)));
		CH.Neighbors.Put(CH.Vecinos, EP_Vecino1, Hora, Success);
		EP_Vecino2 := LLU.Build(LLU.To_IP(ACL.Argument(5)), Natural'Value(ACL.Argument(6)));
		CH.Neighbors.Put(CH.Vecinos, EP_Vecino2, Hora, Success);
		Enviar_Init(EP_H, EP_R, Nick, EP_Vecino2);
	end if;
	
		
when Usage_Error =>
		Ada.Text_IO.Put_Line ("Argumentos no validos" &
				      "<Nombre_Maquina> <Puerto> <Nick>");
		
	
end chat_peer;

