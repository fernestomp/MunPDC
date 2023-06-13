Then %archivo de funciones que puede ser usada por la app pero no exclusivamente
%% ------------ CONECTAR-------------------
function [tcpobj, dFrame] = conectarPMU(ip,puerto,idcode)
%ip: ip de la PMU
%puerto: puerto de la PMU
%idcode: IDCODE de la pmu
%returns:
%dFreame: Configuration frame 2 de la PMU (sin decodificar) 
%tcpobj: el objeto socket creado. Este objeto se pasaría a los demás
%scripts de ser necesario.

% 1 field SYNC 
field1_1 = 170;%AA.
field1_2 = 65; %0-reservado;100-data frame comando;0001-2005
%2 FRAMESIZE
field2_1 =0 ; %el tamaño siempre es 18 incluyendo los dos bits del CHK
field2_2=18;
% 3 field IDCODE
%dividir en dos bytes
field3_1 = bitshift(idcode,-8);
field3_2 = bitand(idcode,255);
%4 SOC
field4_1 =0; %en este caso del comando CFG2 es cero
field4_2 =0;
field4_3 =0;
field4_4 =0;
%5 FRACSEC
field5_1 =0; %en este caso del comando CFG2 es cero
field5_2 =0;
field5_3 =0;
field5_4 =0;
%6 CMD
field6_1 = 0; %primer byte es cero
field6_2= 5; %00000101- comando get CFG2
%7 EXTFRAME no se usa
%8 CHK
%mensajae sin CHK
messnoCHK = [field1_1 , field1_2,...
    field2_1,field2_2,...
    field3_1, field3_2 ...
    field4_1, field4_2, field4_3, field4_4...
    field5_1, field5_2, field5_3, field5_4...
    field6_1, field6_2];


[crc1,crc2] = getCRC(messnoCHK);

message = [messnoCHK, crc1, crc2];

tcpobj = tcpclient(ip,puerto, 'ConnectTimeout', 10);
write(tcpobj,uint8(message));

pause(2)% para que alcanze a escribir y regresar la informacion la PMU
dFrame = read(tcpobj);


