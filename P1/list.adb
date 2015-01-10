--Leire Soria Indiano

with Ada.Text_IO;
with Ada.Unchecked_Deallocation;
with Ada.Strings.Maps.Constants;
with Ada.Strings.Fixed;

package body List is

	package TIO renames Ada.Text_IO;
	package ASMC renames Ada.Strings.Maps.Constants; 
	package ASF renames Ada.Strings.Fixed;

	--Procedimiento para inicializar una celda
	procedure Inicializar (Lista: out Cell_A) is
		begin
			Lista := null;
		end Inicializar;
	
	--Procedimiento liberar memoria	
	procedure Free is new Ada.Unchecked_Deallocation (Cell, Cell_A);

	--Procedure que añade a cualquier lista una nueva celda
	procedure Aniadir (Lista: in out Cell_A; Palabra: ASU.Unbounded_String) is
		PAux : Cell_A;
		begin
			PAux := new Cell;
			PAux.Name := Palabra;
			PAux.Count := 1;
			PAux.Next := Lista;
			Lista := PAux;
		end Aniadir;

	procedure Conversion_Minusculas (Palabra: in out ASU.Unbounded_String) is
		begin
			 ASU.Translate(Palabra, ASMC.Lower_Case_Map);
		end Conversion_Minusculas;


	--Procedure que se recorre todo el conjunto de celdas para buscar si la palabra ya existe (suma uno al contador)
	--y si por el contrario no existiera añadiria una nueva celda con los datos correspondientes.
	procedure Buscar_Palabra (Lista : in out Cell_A;  Palabra: in out ASU.Unbounded_String) is
		PAux : Cell_A;
		Encontrado : Boolean := False;
		begin
			PAux := Lista;
			Conversion_Minusculas(Palabra);
			while PAux /= null and not Encontrado loop
				if ASU.To_String(Palabra) = ASU.To_String(PAux.Name) then
					PAux.Count := PAux.Count + 1;	
					Encontrado := True;
				end if;
				PAux := PAux.Next;				
			end loop;
			
			if not Encontrado then
				Aniadir(Lista, Palabra);
			end if;

		end Buscar_Palabra;
		
	--Procedure que nos escribe las palabras y el numero de repeticiones de cada una de ellas	
	procedure Escribir_Palabras (Lista: Cell_A) is
		PAux : Cell_A;
		begin
			PAux := Lista;
			while PAux /= null loop
				TIO.Put_Line(ASU.To_String(PAux.Name) & ":" & Natural'Image(PAux.Count));
				PAux := PAux.Next;
			end loop;
		end Escribir_Palabras;

	--Procedure que borra toda la memoria que nos dió el ordenador para la cadena de celdas
	procedure Borrar_Lista (Lista: in out Cell_A) is
		PAux : Cell_A;
		begin
			while Lista /= null loop
				PAux := Lista;
				Lista := Lista.Next;
				Free(PAux);
			end loop;
		end Borrar_Lista;
			
				
		
end List;
				
