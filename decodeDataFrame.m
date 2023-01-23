% decodeDataFrame %falta el factor de conversion
function [decodedDF, PHEst, ANEst, DIGBits] = decodeDataFrame(dFrame, repPH,repFREQ,repAN,...
repPHpol,PHNMR,ANNMR,DGNMR,timeBase,facConv)

%repPH indica si la variable es de 16 bits o de 32
%repFREQ entero o flotante
%PHNMR número de fasores
%ANNMR número de analogicos
%DGNMR número de digitales
%repPHpol representacion polar o rectangular de los fasores
DIGBits=0;% si no hay salidas digitales lo pongo a cero

%1 SYNC 2 bytes
%First byte: AA hex
%Second byte: 21 hex for configuration 1
%31 hex for configuration 2
%Both frames are version 1 (IEEE Std C37.118-2005 [B6])
rdSYNC = dFrame(1:2);
%tomar los bits 7,6,5 que indican el tipo de frame (empieza en 1 y no cero)
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
rdFRAMESIZE = dFrame(3:4);
%Este el número de bytes recibidos en formato decimal
decFRAMESIZE = typecast([rdFRAMESIZE(2) rdFRAMESIZE(1)],'uint16');

%% 3 IDCODE 2 bytes
rdIDCODE = dFrame(5:6);
decIDCODE = typecast([rdIDCODE(2) rdIDCODE(1)],'uint16');

%% 4 SOC 4 bytes
rdSOC = dFrame(7:10);
decSOC = typecast([rdSOC(4) rdSOC(3) rdSOC(2) rdSOC(1)],'uint32');

%% 5 FRACSEC 4 bytes
rdFRACSEC = dFrame(11:14);
%time quality flags
MSG_TQ = rdFRACSEC(1); %Tabla 3 del standar
%PARECE QUE NO ESTA FUNCIONANDO
decFRACSEC = typecast( [ rdFRACSEC(3) rdFRACSEC(2) rdFRACSEC(1) 0],'uint32');
%% STAT
rdSTAT=typecast(dFrame(15:16),'uint16');
% Bits 03–00: Trigger reason:
% 1111–1000: Available for user definition
% 0111: Digital 0110: Reserved
% 0101: df/dt High 0100: Frequency high or low
% 0011: Phase angle diff 0010: Magnitude high
% 0001: Magnitude low 0000: Manual
rdTriggerRsn = bitand(rdSTAT,15);%para obtener solo los bits 03-00 (00001111)

% Bits 05–04: Unlocked time: 00 = sync locked or unlocked < 10 s (best quality)
% \01 = 10 s ? unlocked time < 100 s
% 10 = 100 s < unlock time ? 1000 s
% 11 = unlocked time > 1000 s
rdUnlockedTime = bitshift(bitand(rdSTAT,48),-4);% (0011 0000)

%Bits 08–06: PMU Time Quality. Refer to codes in Table 7.
rdPMUTQ =bitshift(bitand(rdSTAT,448),-6); %0000 0001 1100 0000

% Bit 09: Data modified, 1 if data modified by post processing, 0 otherwise
rdDataMod = bitget(rdSTAT,10);

%Bit 10: Configuration change, set to 1 for 1 min to advise configuration will change, and
%clear to 0 when change effected.
rdConfChng = bitget(rdSTAT,11);

%Bit 11: PMU trigger detected, 0 when no trigger
rdPMUTrigg = bitget(rdSTAT,12);

%Bit 12: Data sorting, 0 by time stamp, 1 by arrival
rdDataSort = bitget(rdSTAT,13);

%Bit 13: PMU sync, 0 when in sync with a UTC traceable time source
rdPMUSync = bitget(rdSTAT,14);

%Bit 15–14: Data error:
%00 = good measurement data, no errors
%01 = PMU error. No information about data
%10 = PMU in test mode (do not use values) or absent data tags have been inserted (do not use values)
%11 = PMU error (do not use values)
rdDataError =  bitshift(bitand(rdSTAT,49152),-14);% 1100 0000 0000 0000
%% 7 PHASORS ESTIMATES (falta añadir el factor de conversion

PHEst = zeros(PHNMR,2); %numero de fasores, mag y ang
if repPH ==0 %entero de 16 bits
    
    nBytes = 4;%4bytes 16bits de fase y 16 de angulo  o real e imaginario
    endByte_PHEst = 17+(nBytes*PHNMR)-1;
    fasores = dFrame (17:endByte_PHEst);
    byte1 = typecast([fasores(2) fasores(1)],'int16');
    byte2  = typecast([fasores(4) fasores(3)],'int16');
    
    if repPHpol==0 %representacion rectangular
        
        for i = 1:PHNMR
            
            PHEst(i,1) = abs(byte1 + byte2) *facConv;%magniutd
            % esto esta bien??????????????????????
            %multiplicar el angulo por el facconv y dividirlo entre
            %10^4????
            PHEst(i,2) = rad2deg(angle(byte1 + byte2)*facConv)/10^4;%fase
            
        end
        
    else %representacion polar
        
        for i = 1:PHNMR
            
            inicio = nBytes*(i-1)+1;
            fin = inicio+nBytes-1;
            fnbytes = fasores(inicio:fin);
            byte1 = typecast([fnbytes(2) fnbytes(1)],'uint16');
            byte2  = typecast([fnbytes(4) fnbytes(3)],'int16');
            PHEst(i,1) = double(byte1) * facConv; %Magnitud
            PHEst(i,2) = rad2deg(double(byte2) /10^4); %Fase
        end
        
    end
    
else %flotante de 32 bits
    
    nBytes = 8;%8bytes 32bits y 32bits
    
end

%% 8 FREQ estimado de la frecuencia
%% NOTA: revisar si no es f(1) f(2) en el typecast
%LA FREQDev esta en  mHz
if repFREQ ==0 %entero de 16 bits
    nBytes = 2;
    f = dFrame(endByte_PHEst+1:endByte_PHEst+nBytes);
    FREQEst= double(typecast([ f(2), f(1)],'int16'))/1000; 

else
    nBytes = 4;% flotante de 32 bits
end
endByte_FREQDev = endByte_PHEst + nBytes; 

%% 9 DFREQ 2/4 ROCOF punto fijo o flotante
% ROCOF, in hertz per second times 100 ( 1000)?
% Range –327.67 to +327.67 Hz per second
if repFREQ ==0 %entero de 16 bits
    nBytes = 2;
    devf = dFrame(endByte_FREQDev+1:endByte_FREQDev+nBytes);
    DFREQEst= typecast([ devf(2), devf(1)],'int16'); 

else
    nBytes = 4;% flotante de 32 bits
end
endByte_DFREQEst = endByte_FREQDev + nBytes; %se incluye el primer byte

%% 10 ANALOG Nota:funciona pero ser mas explicito en que no hay datos y no se debe hacer nada en esta seccion
%Analog data, 2 or 4 bytes per value depending on fixed or floating-point
%format used, as indicated by the FORMAT field in configuration 1, 2, and
%3 frames. The number of values is determined by the ANNMR field in
%configuration 1, 2, and 3 frames.
    if repAN ==0 %entero de 16 bits
        nBytes = 4;
    else
        nBytes = 8;% flotante de 32 bits
    end
    endByte_ANEst = endByte_DFREQEst+(nBytes*ANNMR); %se incluye el primer byte
    ANALOGS = dFrame (endByte_DFREQEst+1:endByte_ANEst);
    
    ANEst = zeros(ANNMR,nBytes); %numero de fasores x numero de bits
    for i = 1:ANNMR
        inicio = (nBytes*(i-1)+1);
        fin = inicio+nBytes-1;
        ANEst(i,:) = ANALOGS(inicio:fin); %Estimación del fasor
    end

%% 11 Digital 2 × DGNMR
%Digital data, usually representing 16 digital status points (channels). The
%number of values is determined by the DGNMR field in configuration 1,
%2, and 3 frames.

    nBytes = DGNMR*2; % dos bytes por numero de digitales

    endByte_DIGITAL = endByte_ANEst+nBytes;
    DIGITAL = dFrame(endByte_ANEst+1:endByte_DIGITAL);
    for i = 1:DGNMR
        inicio = (nBytes*(i-1)+1);
        fin = inicio+nBytes-1;
        DIGBits(i,:) = DIGITAL(inicio:fin);
    end

%% 12   CHK
rdCHK = dFrame(endByte_DIGITAL+1:end);
decCHK = typecast([rdCHK(2) rdCHK(1)],'uint16');%
strCHK = sprintf('%X',decCHK);

%% Calculo de la fecha de la medicion
tmPosix = decSOC + (decFRACSEC/timeBase);
measDate = datetime(tmPosix, 'ConvertFrom', 'posixtime');
%% Crear una estructura con todas los datos leidos
decodedDF = struct(...
    'FRAMETYPE',strFrameType,...
    'VERSION',protocolVersion,...
    'FRAMESIZE',decFRAMESIZE,...
    'IDCODE',decIDCODE,...
    'SOC',decSOC,...
    'MSG_TQ',MSG_TQ,...
    'FRACSEC',decFRACSEC,...
    'TRIGRSN',rdTriggerRsn,...
    'UNLCKTIME',rdUnlockedTime,...
    'PMUTQ',rdPMUTQ,...
    'DATAMOD',rdDataMod,...
    'CFGCHNG',rdConfChng,...
    'PMUTRG',rdPMUTrigg,...
    'DATASRT',rdDataSort,...
    'PMUSYNC',rdPMUSync,...
    'DATAERR',rdDataError,...
    'FREQEST',FREQEst,...
    'DFREQEST',DFREQEst,...    
    'MEASDATE', measDate,...
    'CHK',strCHK);
%% 
    