with Ada.Text_IO;
With Ada.Strings.Unbounded;
with Maps_G;
with Ada.Calendar;
with Gnat.Calendar.Time_IO;
with Lower_Layer_UDP;
with Maps_Protector_G;

procedure Maps_Test is
	 package ASU  renames Ada.Strings.Unbounded;
	 package ATIO renames Ada.Text_IO;
	 package C_IO renames Gnat.Calendar.Time_IO;
	 package LLU renames Lower_Layer_UDP;
	 use type ASU.Unbounded_STring;
   
   	 type Seq_N_T is mod Integer'Last;

	 function Image_Hora (T: Ada.Calendar.Time) return String is
   		begin
     			return C_IO.Image(T, "%T.%i");
   		end Image_Hora;
   	
   	--function Direccion_IP (EP: LLU.End_Point_Type) return ASU.Unbounded_String is
   		--Imagen_EP: ASU.Unbounded_String;
   		--Frase: ASU.Unbounded_String;
		--Posicion : Natural;
		--IP : ASU.Unbounded_String;
   		--begin
   		--	Imagen_EP := ASU.To_Unbounded_String(LLU.Image(EP));
   		--	Frase := Imagen_EP;
   		--	Posicion := ASU.Index(Frase, "IP: ");
   		--	Frase := ASU.Tail(Frase, ASU.Length(Frase) - Posicion);
   		--	return IP;
   		--end Direccion_IP;
   	
	 Maximo_Nodos: Integer := 10; 
         Maximo_SMS: Integer := 50;	
  	 package NP_Neighbors is new Maps_G (Key_Type   => LLU.End_Point_Type,
                               Value_Type => Ada.Calendar.Time,
                               Null_Key => null,
                               Null_Value => Ada.Calendar.Time_Of(2003,5,5),
                               Max_Length => Maximo_Nodos,
                               "="        => LLU."=",
                               Key_To_String  => LLU.Image,
                               Value_To_String  => Image_Hora);
                               
	 package NP_Latest_Msgs is new Maps_G (Key_Type   => LLU.End_Point_Type,
                               Value_Type => Seq_N_T,
                               Null_Key => null,
                               Null_Value => 99999,
                               Max_Length => Maximo_SMS,
                               "="        => LLU."=",
                               Key_To_String  => LLU.Image,
                               Value_To_String  => Seq_N_T'Image);

	package Neighbors is new Maps_Protector_G (NP_Neighbors);
	package Latest_Msgs is new Maps_Protector_G (NP_Latest_Msgs);

   Vecinos : Neighbors.Prot_Map;
   Mensajes : Latest_Msgs.Prot_Map;
   Primero : LLU.End_Point_Type;
   Segundo : LLU.End_Point_Type;
   Tercero : LLU.End_Point_Type;
   Success : Boolean;
   Value : Ada.Calendar.Time := Ada.Calendar.Clock;
   --Dir_IP1: ASU.Unbounded_String;
   --Dir_IP2: ASU.Unbounded_String;
   --Dir_IP3: ASU.Unbounded_String;
   EP_Array : Neighbors.Keys_Array_Type;
   Hora_Array : Neighbors.Values_Array_Type; 

begin
	Primero := LLU.Build(LLU.To_IP(LLU.Get_Host_Name), 3333); 
	Segundo := LLU.Build(LLU.To_IP(LLU.Get_Host_Name), 6666); 
	Tercero := LLU.Build(LLU.To_IP(LLU.Get_Host_Name), 9999); 
	--Dir_IP1 := Direccion_IP(Primero);
	--Dir_IP2 := Direccion_IP(Segundo);
	--Dir_IP3 := Direccion_IP(Tercero);
	
   --Escribimos la longuitud de la primera tabla
   ATIO.New_Line;
   ATIO.Put_Line ("Longitud de la tabla de símbolos: " &
                    Integer'Image(Neighbors.Map_Length(Vecinos)));
   Neighbors.Print_Map (Vecinos);


   --Introducimos el primer end point
   ATIO.Put_Line("Introducimos el primer end point");
   Neighbors.Put (Vecinos,
             Primero,
             Value,
             Success);
   ATIO.New_Line;

   --Introducimos el Segundo end point
   ATIO.Put_Line("Introducimos el segundo end point");
   Neighbors.Put (Vecinos,
             Segundo,
             Value,
             Success);
   ATIO.New_Line;

   --Introducimos el tercer end point
   ATIO.Put_Line("Introducimos el tercer end point");
   Neighbors.Put (Vecinos,
             Tercero,
             Value,
             Success);
   ATIO.New_Line;
   
   --Escribrimos de nuevo la longuitud de la tabla
   ATIO.Put_Line ("Longitud de la tabla de símbolos: " &
                    Integer'Image(Neighbors.Map_Length(Vecinos)));
   Neighbors.Print_Map(Vecinos);
   ATIO.New_Line;

   --Escribimos la tabla (Array-End_Points)
   ATIO.Put_Line("Escribimos la tabla de vecinos (IP)");
   EP_Array := Neighbors.Get_Keys(Vecinos);
   for I in 1..Maximo_Nodos loop
	ATIO.Put_Line (LLU.Image(EP_Array(I)));
   end loop;
   ATIO.New_Line;

    --Escribimos la tabla (Array-Horas)
   ATIO.Put_Line("Escribimos la tabla de vecinos (Horas)");
   Hora_Array := Neighbors.Get_Values(Vecinos);
   for I in 1..Maximo_Nodos loop
	ATIO.Put_Line (Image_Hora(Hora_Array(I)));
   end loop;
   ATIO.New_Line;
   
   --Examinamos si existe el segundo end_point
   ATIO.Put_Line("Existe IP 2?");
   Neighbors.Get (Vecinos, Segundo, Value , Success);
   if Success then
      ATIO.Put_Line ("Get: Dirección IP " & LLU.Image(Segundo) & "es: " &
                       Image_Hora(Ada.Calendar.Clock));
   else
      ATIO.Put_Line ("Get: NO hay una entrada para la clave " & LLU.Image(Segundo));
   end if;
   ATIO.New_Line;
   
   --Examinamos si existe el primer end_Point
   ATIO.Put_Line("Existe IP 1?");
   Neighbors.Get (Vecinos, Primero, Value , Success);
	 if Success then
      ATIO.Put_Line ("Get: Dirección IP " & LLU.Image(Primero) & "es: " &
                       Image_Hora(Ada.Calendar.Clock));
   else
      ATIO.Put_Line ("Get: NO hay una entrada para la clave " & LLU.Image(Primero));
   end if;
   ATIO.New_Line;
   
   --Suprimimos el segundo end_point
   ATIO.Put_Line("Borramos el EP2");
   Neighbors.Delete (Vecinos, Segundo, Success);
   if Success then
      ATIO.Put_Line ("Delete: BORRADO " & LLU.Image(Segundo));
   else
      ATIO.Put_Line ("Delete: " & LLU.Image(Segundo) & "no encontrado");
   end if;
   ATIO.New_Line;
 
   --Escribimos la tabla de vecinos (Array-EP)
   ATIO.Put_Line("Escribimos la tabla de vecinos (IP)");
   EP_Array := Neighbors.Get_Keys(Vecinos);
   for I in 1..Maximo_Nodos loop
	ATIO.Put_Line (LLU.Image(EP_Array(I)));
   end loop;
   ATIO.New_Line;

    --Escribimos la tabla (Array-Horas)
   ATIO.Put_Line("Escribimos la tabla de vecinos (Horas)");
   Hora_Array := Neighbors.Get_Values(Vecinos);
   for I in 1..Maximo_Nodos loop
	ATIO.Put_Line (Image_Hora(Hora_Array(I)));
   end loop;
   ATIO.New_Line;
   
   --Escribirmos de nuevo la tabla
   ATIO.Put_Line ("Longitud de la tabla de símbolos: " &
                    Integer'Image(Neighbors.Map_Length(Vecinos)));
   Neighbors.Print_Map(Vecinos);
   
   --Introducimos el Segundo end point
    ATIO.Put_Line("Introducimos el segundo end point");
   Neighbors.Put (Vecinos,
             Segundo,
             Value,
             Success);
   ATIO.New_Line;
   
   --Introducimos el tercero end point
    ATIO.Put_Line("Introducimos el tercer end point");
   Neighbors.Put (Vecinos,
             Tercero,
             Value,
             Success);
   ATIO.New_Line;

     --Escribimos la tabla de vecinos (Array-EP)
   ATIO.Put_Line("Escribimos la tabla de vecinos (IP)");
   EP_Array := Neighbors.Get_Keys(Vecinos);
   for I in 1..Maximo_Nodos loop
	ATIO.Put_Line (LLU.Image(EP_Array(I)));
   end loop;
   ATIO.New_Line;

    --Escribimos la tabla (Array-Horas)
   ATIO.Put_Line("Escribimos la tabla de vecinos (Horas)");
   Hora_Array := Neighbors.Get_Values(Vecinos);
   for I in 1..Maximo_Nodos loop
	ATIO.Put_Line (Image_Hora(Hora_Array(I)));
   end loop;
   ATIO.New_Line;
   
   --Escribirmos de nuevo la tabla
   ATIO.Put_Line ("Longitud de la tabla de símbolos: " &
                    Integer'Image(Neighbors.Map_Length(Vecinos)));
   Neighbors.Print_Map(Vecinos);
   
   
   --Suprimimos el segundo end-Point
    ATIO.Put_Line("Borramos el EP2");
   Neighbors.Delete (Vecinos, Segundo, Success);
   if Success then
      ATIO.Put_Line ("Delete: BORRADO " & LLU.Image(Segundo));
   else
      ATIO.Put_Line ("Delete: " & LLU.Image(Segundo) & "no encontrado");
   end if;
   ATIO.New_Line;

     --Escribimos la tabla de vecinos (Array-EP)
   ATIO.Put_Line("Escribimos la tabla de vecinos (IP)");
   EP_Array := Neighbors.Get_Keys(Vecinos);
   for I in 1..Maximo_Nodos loop
	ATIO.Put_Line (LLU.Image(EP_Array(I)));
   end loop;
   ATIO.New_Line;

    --Escribimos la tabla (Array-Horas)
   ATIO.Put_Line("Escribimos la tabla de vecinos (Horas)");
   Hora_Array := Neighbors.Get_Values(Vecinos);
   for I in 1..Maximo_Nodos loop
	ATIO.Put_Line (Image_Hora(Hora_Array(I)));
   end loop;
   ATIO.New_Line;
   
   --Escribimos de nuevo la tabla
   ATIO.Put_Line ("Longitud de la tabla de símbolos: " &
                    Integer'Image(Neighbors.Map_Length(Vecinos)));
   Neighbors.Print_Map(Vecinos);


end Maps_Test;
