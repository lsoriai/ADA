--Leire Soria Indiano

with Ada.Text_IO;
with Ada.Strings.Unbounded;
with Ada.Command_Line;
with Ada.Exceptions;
with ADA.IO_Exceptions;
with list;
with Ada.Strings.Maps.Constants;
with Ada.Strings.Fixed;

procedure Cuenta is
	package TIO renames Ada.Text_IO;
	package ASU renames Ada.Strings.Unbounded;
	package ACL renames Ada.Command_Line;
	package ASF renames Ada.Strings.Fixed;
  	package ASMC renames Ada.Strings.Maps.Constants;

	
	procedure Conversion_Minusculas (Palabra: in out ASU.Unbounded_String) is
		begin
			 ASU.Translate(Palabra, ASMC.Lower_Case_Map);
		end Conversion_Minusculas;

	--Procedure que nos prermite ir separando una frase de otra, definiendo como frase aquel conjunto de caracteres hasta el eol
	--Despues llama al procedimiento trocear que está encima de él.

	procedure Escribir_Resultado_f (File: TIO.File_Type) is
		Frase: ASU. Unbounded_String;
		Num_Caracteres_Total : Natural := 0;
		Num_Frases : Natural := 0;
		Num_Palabras : Natural := 0;
		Num_Palabras_Frases : Natural := 0;
		Posicion : Natural;
		Palabra : ASU.Unbounded_String;
		Fin : Boolean := False;

		begin	
			while not Fin loop	
				begin		
				Frase := ASU.To_Unbounded_String(Ada.Text_IO.Get_Line(File));
				Num_Caracteres_Total := ASU.Length(Frase) + Num_Caracteres_Total + 1;
				Num_Frases := Num_Frases + 1;
				Posicion := 10000000; --Bucle
				Num_Palabras_Frases := 0; --Contador de palabra
					while Posicion /= 0 loop
						Posicion := ASU.Index(Frase, " ");
					   	if Posicion = 1 then
							Frase := ASU.Tail(Frase, ASU.Length(Frase) - Posicion);
					    	elsif Posicion = 0 then
							if ASU.Length(Frase) /= 0 then
							Palabra := Frase;
							Num_Palabras_Frases := Num_Palabras_Frases + 1;
							end if;
					    	else 
							Palabra := ASU.Head (Frase, Posicion - 1);
							Frase := ASU.Tail (Frase, ASU.Length (Frase) - Posicion);
							Num_Palabras_Frases := Num_Palabras_Frases + 1;
					    	end if;
				    	end loop;
				Num_Palabras := Num_Palabras + Num_Palabras_Frases;
				exception 
					when Ada.IO_Exceptions.End_Error =>
      						Fin := True;
      						
     				end;
			end loop;
			Num_Caracteres_Total := Num_Caracteres_Total;
			TIO.Put_Line(" Lineas:" & Natural'Image(Num_Frases) & 
				     " Palabras:" & Natural'Image(Num_Palabras) &
				     " Caracteres:" & Natural'Image(Num_Caracteres_Total));
		end Escribir_Resultado_f;
				
	procedure Escribir_Resultado_f_t (File: TIO.File_Type) is
		Frase: ASU. Unbounded_String;
		Posicion : Natural;
		Palabra : ASU.Unbounded_String;
		Fin : Boolean := False;
		Lista : list.Cell_A;

		begin	
			while not Fin loop	
				begin		
				Frase := ASU.To_Unbounded_String(Ada.Text_IO.Get_Line(File));
				Posicion := 10000000; --Bucle
					while Posicion /= 0 loop
						Posicion := ASU.Index(Frase, " ");
						if Posicion = 1 then
							Frase := ASU.Tail(Frase, ASU.Length(Frase) - Posicion);
						elsif Posicion = 0 then
							if ASU.Length(Frase) /= 0 then
								list.Buscar_Palabra (Lista, Frase);
							end if;
					    	else 
							Palabra := ASU.Head (Frase, Posicion - 1);
							Frase := ASU.Tail (Frase, ASU.Length (Frase) - Posicion);
							list.Buscar_Palabra (Lista, Palabra);
					    	end if;
			    		end loop;
					Lista := Lista.Next;
				exception 
					when Ada.IO_Exceptions.End_Error =>
      						Fin := True;
     				end;
			end loop;
			
			list.Escribir_Palabras(Lista);
		end Escribir_Resultado_f_t;
			

	--Variables a declarar

	File: TIO.File_Type;
	Texto: ASU. Unbounded_String;
	Usage_Error: exception;

begin
	if ACL.Argument_Count = 2 then
		if ACL.ARgument (1) = "-f" then
			TIO.Open(File, TIO.In_File, ACL.Argument(2));
			Escribir_Resultado_f (File);
			TIO.Close(File);
		else
			raise Usage_Error;
		end if;

	elsif ACL.Argument_Count = 3 then
		if ACL.Argument (1) = "-t" and ACL.Argument (2) = "-f" then
			TIO.Open(File, TIO.In_File, ACL.Argument(3));
			Escribir_Resultado_f (File);
			TIO.Close(File);
			TIO.Put_Line("Las palabras son: ");
			TIO.Open(File, TIO.In_File, ACL.Argument(3));
			Escribir_Resultado_f_t(File);
			TIO.Close(File);
		elsif ACL.Argument (1) = "-f" and ACL.Argument (3) = "-t" then
			TIO.Open(File, TIO.In_File, ACL.Argument(2));
			Escribir_Resultado_f (File);
			TIO.Close(File);
			TIO.New_Line;
			TIO.Put_Line("Las palabras son: ");
			TIO.Open(File, TIO.In_File, ACL.Argument(2));
			Escribir_Resultado_f_t(File);
			TIO.Close(File);
		else
			raise Usage_Error;
		end if;

	elsif ACL.Argument_Count /= 2 or ACL.Argument_Count /= 3 then
		raise Usage_Error;

	end if;
	

exception
	when Usage_Error =>
		TIO.Put_Line("¿Estás seguro que has escrito bien el nombre del fichero?" &
		"/-f <nombre del fichero> -t/ " &
		"/-t <nombre del fichero> -f/ " &
		"/-f <nombre del fichero>/");
end Cuenta;
