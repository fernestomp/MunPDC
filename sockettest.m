clc
pkg load sockets
client = socket(AF_INET, SOCK_STREAM, 0);
%server_info = struct("addr", "192.168.1.3", "port", 8900);
server_info = struct("addr", "10.10.200.21", "port", 8900);
rc = connect(client, server_info);
msg = 'AA41001200EB0000000000000000000580D0';
msg =[170	65	0	18	0	235	0	0	0	0	0	0	0	0	0	5	128 208];
lm=send(client,uint8(msg),64);