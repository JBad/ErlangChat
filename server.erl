% Jesse Badash
% Chat Server

-module(server).
%-export([startServer/0]).
%-export([startClient/0]).
-compile(export_all).

startServer() -> 
	{ok, Listener} = gen_tcp:listen(5555, [{active, true}, binary]),
	%--Pass Control of socket!!-----------------------------------------------to both the acceptor then t othe emessage passser!
	%--controlling_process(Socket, Pid).	
	MessagePasserPid = spawn(server, messagePasser, [[]]),
	AcceptorPid = spawn(server, acceptor, [MessagePasserPid, Listener]),
	gen_tcp:controlling_process(Listener, AcceptorPid).
	
acceptor(MessagePid, Listener) ->
		io:format("StartAcceptor ~n"),
	{ok, NewClient} = gen_tcp:accept(Listener),
	     	io:format("accepted~n"),
%-------Add a PLACE CLIENT FUCNTION HERE TO GET THE CORRECT CHANNEL, the following two lines should disappear into the function!.
	MessagePid ! {addClient, NewClient},
	gen_tcp:controlling_process(NewClient, MessagePid),
	acceptor(MessagePid, Listener).
	
messagePasser(Clients) ->
	receive 
		{test, Message} ->
		        io:format(Message);
		{addClient, NewClientSocket} ->
%			NewClient = spawn(server, client, [NewClientSocket]),
			io:format("Added"),
			messagePasser([NewClientSocket|Clients]);
		{tcp, Socket, {message, ClientMessage}} ->
			[gen_tcp:send(N, {message, ClientMessage}) || N <- lists:delete(Socket, Clients)],			
			io:format(ClientMessage),
			io:format("THIS IS A MESSAGE"),
			messagePasser(Clients);
		{tcp, Socket, Message} ->
		      	[gen_tcp:send(N, Message) || N <- lists:delete(Socket,Clients)],
		      	io:format(Message),
			messagePasser(Clients);
		{kill, Client} ->
		        gen_tcp:close(Client),
			messagePasser(lists:delete(Client, Clients))
	end.

%client(Socket) ->
%	receive
%		{message, ServerMessage} ->
%			gen_tcp:send(Socket, ServerMessage),
%			client(Socket);
%		{addClient, NewClient} ->
%			Message = NewClient ++ " Has been added",
%			gen_tcp:send(Socket, Message),
%			client(Socket);
%		{kill, rge} ->
%		        gen_tcp:close(Socket);
%	end.

%%-----------------------------Client----------------------------%

startClient() ->
	{ok, Socket} = gen_tcp:connect({127,0,0,1}, 5555, [binary, {active, true}]),
	IOPid = spawn(server, io, [Socket]),
%	SenderPid = spawn(server, sender, [Socket]),	
	gen_tcp:controlling_process(Socket, IOPid),
	Name = io:get_line("What is your name?: "),
	Prompt = string:concat(string:strip(Name, right, $\n), ": "),
	reader(IOPid, Prompt).	

reader(IOPid, Prompt) ->
	MessageToSend = io:get_line(Prompt),
%	io:format(MessageToSend),
%	gen_tcp:send(Socket,{message, MessageToSend}),
	IOPid ! {out, string:concat(Prompt,MessageToSend)},
%	io:format("Sent"),
	reader(IOPid, Prompt).

io(Socket) ->
	receive
		{tcp, Socket, ToPrint} ->
			io:format(ToPrint),
			io(Socket);
		{out, Message} ->
%		      	io:format(Message),
%			MessageToSend = Message ++ "\n",
		      	gen_tcp:send(Socket, Message),  
			io(Socket)
	end.