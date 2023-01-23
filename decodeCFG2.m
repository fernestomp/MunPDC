%decodificar el mensaje CFG2
function [CFG2, cellPhasors] = decodeCFG2(dframe)
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

    switch frameType
        case 0
            strFrameType='Data frame';
        case 1
            strFrameType='Configuration frame 1';
        case 3
            strFrameType='Configuration frame 2';
        case 5
            strFrameType='Configuration frame 3';
        case 4
            strFrameType='Command frame';
    end
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

if repFREQ == 0 
    strRepFREQ = 'Fijo';
else
    strRepFREQ='Punto flotante';
end

if repANALOG == 0
    strRepANALOG= 'Entero';
else
    strRepANALOG='Punto flotante';
end

if repPHASORS == 0
    strRepPhASORS = 'Entero';
else
    strRepPhASORS = 'Punto flotante';
end

if repPHASORSpol == 0
    strRepPHASORSpol='Rectangular';
else
    strRepPHASORSpol = 'Polar';
end

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
facConv = double(typecast(...
        [uint8(arrPHUNIT(i,4))...
        uint8(arrPHUNIT(i,3))...
        uint8(arrPHUNIT(i,2)), ...
        0],...
        'uint32')) / 10^5; %Asi dice PHUNIT, 10^5

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

%% 19 CFGCNT 2 bytes Contador de cambios de configuraci´on
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
% if decDATA_RATE > 0
%     strDATA_RATE = sprintf('%d frames por segundo\n',decDATA_RATE);
% else
%     strDATA_RATE = sprinft('1 frame por cada %d segundos\n',abs(decDATA_RATE));
% end
%% Ultimo CHK 2 bytes(este es diferente segun el documento)
rdCHK = dframe(endbyte_DATA_RATE+1:end);
decCHK = typecast([rdCHK(2) rdCHK(1)],'uint16');%
strCHK = sprintf('%X',decCHK);
%% CREAR UNA ESTRUCTURA
CFG2 = struct(...
    'FRAMETYPE',strFrameType,...
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
    'FREQ_REP',repFREQ,...
    'AN_REP',repANALOG,...
    'PH_REP',repPHASORS,...
    'PH_POL_REP',repPHASORSpol,...
    'PH_NUMBER',decPHNMR,...
    'AN_NUMBER',decANNMR,...
    'DG_NUMBER',decDGNMR,...
    'FACCONV', facConv,...
    'FREQ_NOM',valFNOM,...
    'CFGCNT',decCFGCNT,...
    'DATA_RATE',decDATA_RATE,...
    'CHK',strCHK);

%% Crear un cell array con los datos de fasores
cellPhasors =cell(decPHNMR,4);
for i =1:decPHNMR
    txtname= ['PH',num2str(i)];
    if arrPHUNIT(i,1) == 0 
        txtype ='Tension';
    else
        txtype='Corriente';
    end
%     %ESTA PARTE LA
%     %los otros tres bytes de arrPHUNIT indican el factor de conversion
%     facConv = double(typecast(...
%         [uint8(arrPHUNIT(i,4))...
%         uint8(arrPHUNIT(i,3))...
%         uint8(arrPHUNIT(i,2)), ...
%         0],...
%         'uint32')) / 10^5; %Asi dice PHUNIT, 10^5
    %formato del cell array: nombre (inventado), nombre real del canal,
    %tipo y factor de conversion
    cellPhasors(i,:)= {txtname,strCHNAM(i,:),txtype,facConv};

end

