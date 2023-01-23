%comando get configuration frame 2
% 1 field SYNC 
field1_1 = 170;%AA.
field1_2 = 65; %0-reservado;100-data frame comando;0001-2005
%2 FRAMESIZE
field2_1 =0 ; %el tamaño siempre es 18 incluyendo los dos bits del CHK
field2_2=18;
% 3 field IDCODE
field3_1 = 0; %primer byte
field3_2 = 3; %identificador del PMU
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
field6_2= 5; %00000101- comandoget CFG2
%7 EXTFRAME no se usa
%8 CHK
%mensajae sin CHK
messnoCHK = [field1_1 , field1_2,...
    field2_1,field2_2,...
    field3_1, field3_2 ...
    field4_1, field4_2, field4_3, field4_4...
    field5_1, field5_2, field5_3, field5_4...
    field6_1, field6_2];

[crc1 crc2] = getCRC(messnoCHK);
message = [messnoCHK, crc1, crc2];
sprintf('%X %X',crc1, crc2)
msg =[170	65	0	18	0	235	0	0	0	0	0	0	0	0	0	5	128 208];
%tcpobj = tcpclient('192.168.1.4',4712);
tcpobj = tcpclient('10.10.200.20',4712);
pause(2)
write(tcpobj,uint8(message));
dframe = read(tcpobj);
%clear tcpobj; %cerrar conexion
%% decodificar el mensaje CFG2
%1 SYNC 2 bytes
%First byte: AA hex
%Second byte: 21 hex for configuration 1
%31 hex for configuration 2
%Both frames are version 1 (IEEE Std C37.118-2005 [B6])
rdSYNC = dframe(1:2);
%tomar los bytes 7,6,5 que indican el tipo de frame (empieza en 1 y no cero)
frameType=  bin2dec([num2str(bitget(rdSYNC(2),7))...
        num2str(bitget(rdSYNC(2),6))...
        num2str(bitget(rdSYNC(2),5))]);
protocolVersion = bin2dec([num2str(bitget(rdSYNC(2),4))...
        num2str(bitget(rdSYNC(2),3))...
        num2str(bitget(rdSYNC(2),2))...
        num2str(bitget(rdSYNC(2),1))]);
   
   
%% 2 FRAMESIZE 2 bytes
rdFRAMESIZE = dframe(3:4);
%Este el número de bytes recibidos en formato decimal
decFRAMESIZE = typecast([rdFRAMESIZE(2) rdFRAMESIZE(1)],'uint16');

%% 3 IDCODE 2 bytes
rdIDCODE = dframe(5:6);
decIDCODE = typecast([rdIDCODE(2) rdIDCODE(1)],'uint16');

%% 4 SOC 4 bytes
rdSOC = dframe(7:10);
decSOC = typecast([rdSOC(4) rdSOC(3) rdSOC(2) rdSOC(1)],'uint32');

%% 5 FRACSEC 4 bytes
rdFRACSEC = dframe(11:14);
%time quality flags
MSG_TQ = rdFRACSEC(1); %Tabla 3 del standar
%PARECE QUE NO ESTA FUNCIONANDO
decFRACSEC = typecast( [0 rdFRACSEC(3) rdFRACSEC(2) rdFRACSEC(1)],'uint32');

%% 6 TIME_BASE 4 bytes
rdTIME_BASE = dframe(15:18);
decTIME_BASE = typecast(...
    [ uint8(rdTIME_BASE(2))...
    uint8(rdTIME_BASE(3))...
    uint8(rdTIME_BASE(4))...
    0],...
    'uint32');

%% 7 NUM_PMU 2 bytes número de PMU's que mandan datos
rdNUM_PMU = dframe(19:20);
decNUM_PMU = typecast( [rdNUM_PMU(2) rdNUM_PMU(1)],'uint16');

%% 8 STN 16 bytes (nombre del PMU)
rdSTN = dframe(21:36);
strSTN = char(rdSTN);

%% 9 IDCODE 2 bytes identificador del que manda los datos
rdIDCODEsrc = dframe(37:38);
decIDCODEsrc = typecast([rdIDCODEsrc(2) rdIDCODEsrc(1)],'uint16');

%% 10 FORMAT 2 bytes  
%bit 15-4 no se utilizan
%bit 3 tipo de numero con lo que se presenta FREQ y o DFREQ
%   0 fijo con entero de 16 bits
%   1 punto flotante de 32 bits formato IEEE
%bit 2 tipo de número con que se presentan los analogos
%   0 entero de 16 bits (requiere factor de conversión
%   1 punto flotante de 32 bits
%bit 1 tipo de número con que se presentan los fasores
%   0 entero de 16 bits
%   1 punto flotane de 32 bits
%bit 0 forma en que se presentan los fasores
%   0 Rectangular
%   1 polar
rdFORMAT = dframe(39:40);
repFREQ = bitget(rdFORMAT(2),4); %representación de la frecuencia
repANALOG = bitget(rdFORMAT(2),3);
repPHASORS = bitget(rdFORMAT(2),2);
repPHASORSpol = bitget(rdFORMAT(2),1); %forma polar o rectangular

%% 11 PHNMR 2 bytes numero de fasores que se recibiran en el frame
rdPHNMR = dframe(41:42);
%se leen dos bytes pero en realidad es un solo número. Con typecast uno los
%dos bytes para crear un número de 16 bits
decPHNMR = typecast([rdPHNMR(2) rdPHNMR(1)],'uint16');

%% 12 ANNMR 2 bytes Numero de valores analogos que se recibiran el dframe
rdANNMR = dframe(43:44);
decANNMR = typecast([rdANNMR(2) rdANNMR(1)],'uint16');

%% 13 DGNMR 2 bytes Numero de entradas digitales que se recibiran en el
%dframe
rdDGNMR = dframe(45:46);
decDGNMR = typecast([rdDGNMR(2) rdDGNMR(1)],'uint16');

%% 14 CHNAM Nombre de fasores y banderas (definido en la programación del
%PMU) 1 letra formato ASCII por cada byte
%N= no fasores + no analogos + 16x no entradas digitales
%convirtiendo de 2 bytes a un número decimal
N_CHNAM = 16*(decPHNMR + decANNMR + (16*decDGNMR));

%como el número de bytes de CHNAM no se conoce, uso la siguiente variable
%para definir el ultimo byte de CHNAM y los subsiguientes 
endbyte_CHNAM = 46 + N_CHNAM; 
rdCHNAM = dframe(47:endbyte_CHNAM);
%nombre de los fasores
%NOTA: SOLO FUNCIONA CON NOMBRES DE FASORES Y NO DE CANALES (CREO)
strCHNAM = char(zeros(decPHNMR,16)); % matriz para nombres de 16 bytes
for i = 1:decPHNMR
   inicio = (16*(i-1)+1);
   fin = inicio+15;
   strCHNAM(i,:) = char(rdCHNAM(inicio:fin) );
end
%% 15 PHUNIT 4x PHNMR factor de conversion de fasores
%Bits 31-24 (byte m´as significativo):
%(00): Tensi´on
%(01): Corriente
%Bits 23-0 (3 Bytes menos significativos):
%Factor de conversi´on requerido en “FORMAT”
%Entero de 24 bits sin signo, multiplicado por un factor
%de 105
endbyte_rdPHUNIT= endbyte_CHNAM + (4*decPHNMR);
rdPHUNIT = dframe(endbyte_CHNAM+1:endbyte_rdPHUNIT);
%decodificando 
arrPHUNIT = zeros(decPHNMR,4); 
for i = 1:decPHNMR
   inicio = (4*(i-1)+1);
   fin = inicio+3;
   arrPHUNIT(i,:) = rdPHUNIT(inicio:fin);
end

%% 16 ANUNIT 4X ANNMR factor de conversión analogos
endbyte_ANUNIT = endbyte_rdPHUNIT + (4*decANNMR);
rdANUNIT = dframe(endbyte_rdPHUNIT+1:endbyte_ANUNIT);
%decodificando
arrANUNIT = zeros(decANNMR,4); 
for i = 1:decANNMR
   inicio = (4*(i-1)+1);
   fin = inicio+3;
   arrANUNIT(i,:) = rdANUNIT(inicio:fin);
end

%% 17 DIGUNIT 4xDGNMR
%Mascaras para entradas digitales (definido por el usuario)
%Sugerencia de uso:
%Los 2 bytes m´as significativos pueden ser el estado predeterminado de las entradas
%Los 2 bytes menos significativos pueden ser el estado
%actual de las entradas
endbyte_DIGUNIT = endbyte_ANUNIT + (4*decDGNMR);
rdDIGUNIT = dframe(endbyte_ANUNIT+1:endbyte_DIGUNIT);
%decodificando
arrDIGUNIT = zeros(decDGNMR,4); 
for i = 1:decDGNMR
   inicio = (4*(i-1)+1);
   fin = inicio+3;
   arrDIGUNIT(i,:) = rdDIGUNIT(inicio:fin);
end

%18 FNOM 2 bytes
%Frecuencia nominal
%Bits 15-1: Reservados (valor predeterminado 0)
%Bit 0:
%0= FNOM 60 [Hz]
%1= FNOM 50 [Hz]
endbyte_rdFNOM = endbyte_DIGUNIT+2;
rdFNOM = dframe(endbyte_DIGUNIT+1:endbyte_rdFNOM);
if bitget(rdFNOM(1),1) ==0
    valFNOM = 60;
else
    valFNOM =50;
end

%% 19 CFGNCT 2 bytes Contador de cambios de configuraci´on
endbyte_CFGCNT = endbyte_rdFNOM+2;
rdCFGCNT = dframe(endbyte_rdFNOM+1:endbyte_CFGCNT);
decCFGCNT= typecast([rdCFGCNT(2) rdCFGCNT(1)], 'uint16');
% - En caso de existir m´as de un PMU se repiten los puntos
%8-19 por cada PMU adicional

%% Penultima DATA_RATE 2 bytes 
%Rate of phasor data transmissions?2-byte integer word (–32 767 to +32 767)
%If DATA_RATE > 0, rate is number of frames per second.
%If DATA_RATE < 0, dframe(endbyte_CFGNCT+1:end);rate is negative of seconds per frame.
%E.g., DATA_RATE = 15 is 15 frames per second; DATA_RATE = –5 is 1 frame per
%5 s
endbyte_DATA_RATE = endbyte_CFGCNT +2;
rdDATA_RATE = dframe(endbyte_CFGCNT+1:endbyte_DATA_RATE);
decDATA_RATE = typecast([rdDATA_RATE(2) rdDATA_RATE(1)],'int16');
%% Ultimo CHK 2 bytes(este es diferente segun el documento)
rdCHK = dframe(endbyte_DATA_RATE+1:end);
decCHK = typecast([rdCHK(2) rdCHK(1)],'uint16');

%% Desplegar todos los datos 
clc
fprintf('CONFIGURATION FRAME 2\n');

fprintf('(1) SYNC: %X\n');
fprintf('   Primer byte: %X\n',rdSYNC(1));
fprintf('   Tipo de frame: ');
switch frameType
    case 0
        fprintf('Data frame\n');
    case 1
        fprintf('Configuration frame 1\n');
    case 3
        fprintf('Configuration frame 2\n');
    case 5
        fprintf('Configuration frame 3\n');
    case 4
        fprintf('Command frame 3\n');
end
fprintf('   Protocol version: %d\n', protocolVersion)

fprintf('(2) FRAMESIZE: %d\n',decFRAMESIZE);
fprintf('(3) IDCODE: %d\n',decIDCODE);
fprintf('(4) SOC: %d\n',decSOC);
fprintf('(5) FRACSEC: %d\n',decFRACSEC);
fprintf('(6) TIMEBASE: %d\n',decTIME_BASE);
fprintf('(7) NUM_PMU: %d\n',decNUM_PMU);
fprintf('(8) STN: %s\n', strSTN);
fprintf('(9) IDCODE (bloque): %d\n', decIDCODEsrc);

fprintf('(10)FORMAT\n');
fprintf('   Tipo de dato de la frecuencia: ');
if repFREQ == 0 
    fprintf('Fijo\n');
else
    fprintf('Punto flotante\n');
end
fprintf('   Tipo de dato de analogicos: ');
if repANALOG == 0
    fprintf('Entero\n');
else
    fprintf('Punto flotante\n');
end
fprintf('   Tipo de dato de los fasores: ');
if repPHASORS == 0
    fprintf('Entero');
else
    fprintf('Punto flotante\n');
end
fprintf('   Representacion de los fasores: ');
if repPHASORSpol == 0
    fprintf('Rectangular\n');
else
    fprintf('Polar\n');
end

fprintf('(11)PHNMR:%d\n',decPHNMR);
fprintf('(12)ANNMR:%d\n',decANNMR);
fprintf('(13)DGNMR:%d\n',decDGNMR);

fprintf('(14)CHNAM:\n');
for i = 1:decPHNMR
    fprintf('%d-%s\n',i,strCHNAM(i,:));
end

fprintf('(15)PHUNIT\n');
for i =1:decPHNMR
    fprintf('Nombre:%s\n',strCHNAM(i,:));
    fprintf('   Tipo de fasor:')
    if arrPHUNIT(i,1) == 0 %bits 32-24 
        fprintf(' Tension\n');
    else
        fprintf(' Corriente\n');
    end
    %factor de conversion. Se divide en 32768 por que la escala es a 16
    %bits
    facConv = ...
        (typecast([uint8(0) uint8(arrPHUNIT(i,3)) uint8(arrPHUNIT(i,2)) uint8(arrPHUNIT(i,1))], 'uint32')...
        /32768) *1e5;
    fprintf('   Factor de conversion: %d\n',facConv);
end
        
fprintf('(16)ANUNIT\n');
for i = 1:decANNMR
    switch arrANUNIT(i,1)
        case 0
            fprintf(' Un solo punto en la onda');
        case 1
            fprintf(' Valor rms');
        case 2
            fprintf(' Valor pico de la entrada analogica');
    end
    facConv = ...
        (typecast([uint8(0) uint8(arrANUNIT(3))...
        uint8(arrANUNIT(2)) uint8(arrANUNIT(1))], 'uint32')...
        /32768) *1e5;
    fprintf('   Factor de conversion: %d\n',facConv);
end


fprintf('(17)DGUNIT\n');
for i = 1:decDGNMR
   fprintf('Estado normal de las entrads: %X\n',...
       typecast([ uint8(arrDIGUNIT(i,1)) uint8(arrDIGUNIT(i,2))],...
       'uint16')); %primeros dos bytes
   fprintf('Estado actual de las entrads: %X\n',...
       typecast([ uint8(arrDIGUNIT(i,3)) uint8(arrDIGUNIT(i,4))],...
       'uint16')); 
end

fprintf('(18)FNOM: %d\n',valFNOM);
fprintf('(19)CFGCNT: %d\n',decCFGCNT);
fprintf('(Penultimo)DATA_RATE:');
if decDATA_RATE > 0
    fprintf('%d frames por segundo\n',decDATA_RATE);
else
    fprinft('1 frame por cada %d segundos\n',abs(decDATA_RATE));
end

fprintf('(Ultimo)CHK hex: %X\n',decCHK);
%% CREAR UNA ESTRUCTURA
CFG2 = struct(...
    'FRAMETYPE',frameType,...
    'VERSION',protocolVersion,...
    'FRAMESIZE',decFRAMESIZE,...
    'IDCODE',decIDCODE,...
    'SOC',decSOC,...
    'MSG_TQ',MSG_TQ,...
    'FRACSEC',decFRACSEC,...
    'TIME_BASE',decTIME_BASE,...
    'NUM_PMU',decNUM_PMU,...
    'STN_NAME',strSTN,...
    'IDCODE_SRC',decIDCODEsrc,...
    'FREQ_FORMAT',repFREQ,...
    'AN_FORMAT',repANALOG,...
    'PH_FORMAT',repPHASORS,...
    'PH_POL_RECT',repPHASORSpol,...
    'PH_NUMBER',decPHNMR,...
    'AN_NUMBER',decANNMR,...
    'DG_NUMBER',decDGNMR,...
    'FREQ_NOM',valFNOM,...
    'CFGCNT',decCFGCNT,...
    'CHK',decCHK);
%% Crear un cell array con los datos de fasores
cellPhasors =cell(decPHNMR,4);
for i =1:decPHNMR
    txtname= ['PHASOR',num2str(i)];
    if arrPHUNIT(i,1) == 0 
        txtype ='Tension';
    else
        txtype='Corriente';
    end
    %los otros tres bytes de arrPHUNIT indican el factor de conversion
    facConv = typecast(...
        [0 ...
        uint8(arrPHUNIT(i,2))...
        uint8(arrPHUNIT(i,3))...
        uint8(arrPHUNIT(i,4))],...
        'uint32');
    %formato del cell array: nombre (inventado), nombre real del canal,
    %tipo y factor de conversion
    cellPhasors(i,:)= {txtname,strCHNAM(i,:),txtype,facConv};
end
%%
CMD = 2; %habilitar envio de datos
IDCODE =1;

 sendCMD(CMD,IDCODE ,tcpobj)
 pause(1);
 for i = 1:1
 pause(2)
     df = read(tcpobj);

 end
