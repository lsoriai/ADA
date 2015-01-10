with Ada.Text_IO;
with Ada.Strings.Unbounded;


procedure Trocea is

    package TIO renames Ada.Text_IO;
    package ASU renames Ada.Strings.Unbounded;
    use type ASU.Unbounded_String;
    
    --Procedure que lee de pantalla una cadena de cacacteres--
    procedure Leer_Frase (Frase: out ASU.Unbounded_String) is
        begin
            TIO.Put("Escribe la frase: ");
            Frase := ASU.To_Unbounded_String(TIO.Get_Line);
        end Leer_Frase;


    --Procedure que escribe las palabras y los espacios que tiene la frase--
    procedure Escribir_Resultado(Frase: in out ASU.Unbounded_String) is
        Posicion : Natural;
        Num_Palabra : Natural;
        Palabra : ASU.Unbounded_String;
        Espacio : Natural;
        i : Natural;
        begin
		Posicion := 10000000; --Para que pueda entrar en el bucle--
		Num_Palabra := 0; --Contador que utilizamos para ver el numero de palabras--
		Espacio := 0; --Contador que utilizamos para ver el numero de espacios--
		i := 0;  --Contador para poder diferenciar cual es cada palabra : primera, segunda, tercera...--
            while Posicion /= 0 loop
                Posicion := ASU.Index(Frase, " ");
                    if Posicion = 1 then
                        Frase := ASU.Tail(Frase, ASU.Length(Frase) - Posicion);
                        Espacio := Espacio + 1;
                    elsif Posicion = 0 then
                        i := i + 1;
			if ASU.Length(Frase) /= 0 then
		                Palabra := Frase;
		                Num_Palabra := Num_Palabra + 1;
				TIO.Put_Line("La palabra numero " & Natural'Image(i) & " es: |" & ASU.To_String(Palabra) & "|");
			end if;
                    else 
                        i := i + 1;
                        Palabra := ASU.Head (Frase, Posicion - 1);
                        TIO.Put_Line("La palabra numero " & Natural'Image(i) & " es: |" & ASU.To_String(Palabra) & "|");
                        Frase := ASU.Tail (Frase, ASU.Length (Frase) - Posicion);
                        Num_Palabra := Num_Palabra + 1;
                        Espacio := ESpacio + 1;
                    end if;
            end loop;
            	if Num_Palabra = 1 then
            		TIO.Put("Total: " & Natural'Image(Num_Palabra) & " Palabra" & Natural'Image(Espacio) & " Espacios");
            	else
            		TIO.Put("Total: " & Natural'Image(Num_Palabra) & " Palabras" & Natural'Image(Espacio) & " Espacios");
            	end if;
        
        end;

    Frase: ASU.Unbounded_String;

begin
    Leer_Frase(Frase);
    Escribir_Resultado(Frase);
end Trocea;
