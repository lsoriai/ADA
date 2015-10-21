--Leire Soria Indiano
with Lower_Layer_UDP;
with Ada.Strings.Unbounded;

package chat_messages is
	package LLU renames Lower_Layer_UDP;
	package ASU renames Ada.Strings.Unbounded;
	
	type Message_Type is (Init, Reject, Confirm, Writer, Logout);

end chat_messages;

