--Leire Soria Indiano
with Lower_Layer_UDP;

package Chat_Messages is	
	package LLU renames Lower_Layer_UDP;

	type Message_Type is (Init, Reject, Confirm, Writer, Logout, Ack);

	type Buffer_A_T is access LLU.Buffer_Type;

	P_Buffer_Main: Buffer_A_T;
	P_Buffer_Handler: Buffer_A_T;


end Chat_Messages;

