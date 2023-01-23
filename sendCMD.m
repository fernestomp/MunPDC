%funcion para mandar comandos segun el protocolo c37.118-x
function sendCMD(CMD,IDCODE ,tcpobj)
%% 1 SYNC 2 bytes
%%Sync byte followed by frame type and version number (AA41 hex).
%Primer byte: AA sync byte
%Seguno byte: 41 0100 0001
%bit7 =reservado(0), bit 6-4:100 command frame, bits 3-0: 0001 version 1
CMD_SYNC_1 = 170; %0xAA
CMD_SYNC_2 =  65; %0x41

%% FRAMESIZE 2 bytes
%son 18 bytes segun la tabla 2
CMD_FRAMESIZE_1 = 0;
CMD_FRAMESIZE_2 = 18;

%% IDCODE 2 bytes
%Partir en dos el IDCODE 16 bits
CMD_IDCODE_1 = bitshift(IDCODE,-8);
CMD_IDCODE_2 =  bitand(IDCODE,255);

%% SOC 4 bytes
CMD_SOC_1 =00;
CMD_SOC_2=00;
CMD_SOC_3=00;
CMD_SOC_4=00;

%% FRACSEC 4 bytes
CMD_FRACSEC_1  = 0; 
CMD_FRACSEC_2  =0; 
CMD_FRACSEC_3  =0;
CMD_FRACSEC_4  =0;

%% EXTFRAME no lo uso
%% CMD 2 BYTES 
% Command word bits Definition
% Bits 15–0:
% 0000 0000 0000 0001 Turn off transmission of data frames.
% 0000 0000 0000 0010 Turn on transmission of data frames.
% 0000 0000 0000 0011 Send HDR frame.
% 0000 0000 0000 0100 Send CFG-1 frame.
% 0000 0000 0000 0101 Send CFG-2 frame.
% 0000 0000 0000 0110 Send CFG-3 frame (optional command).
% 0000 0000 0000 1000 Extended frame.
% 0000 0000 xxxx xxxx All undesignated codes reserved.
% 0000 yyyy xxxx xxxx All codes where yyyy ? 0 available for user designation.
% zzzz xxxx xxxx xxxx All codes where zzzz ? 0 reserved.
CMD_CMD_1 = 0;
CMD_CMD_2 = CMD;

%% CHK 
%mensajae sin CHK
messnoCHK = [CMD_SYNC_1 , CMD_SYNC_2...
    CMD_FRAMESIZE_1, CMD_FRAMESIZE_2...
    CMD_IDCODE_1, CMD_IDCODE_2...
    CMD_SOC_1,CMD_SOC_2,CMD_SOC_3,CMD_SOC_4,...
    CMD_FRACSEC_1, CMD_FRACSEC_2, CMD_FRACSEC_3, CMD_FRACSEC_4, ...
    CMD_CMD_1, CMD_CMD_2];

[crc1,crc2] = getCRC(messnoCHK);
message = [messnoCHK, crc1, crc2];
write(tcpobj,uint8(message))
pause(1)% para que alcanze a escribir y regresar la informacion la PMU
%dFrame = read(tcpobj);
