function crc = calcCRC_CCITT (message)
%%Tomado del documento IEEE Standard for Synchrophasor Data Transfer for Power Systems
%%Anexo B y traducido a matlab. Comparado con https://www.lammertbies.nl/comm/info/crc-calculation.html
%la entrada debe ser un string
%ejemplo:
% el mensaje AA410012000100000000000000000005 se toma de dos bytes en dos
% es decir AA 41 00 12 00 01 00 00 00 00 00 00 00 00 00 00 05
% en decimal queda
%mensaje = [170 65 00 18 00 01 00 00 00 00 00 00 00 00 00 05]
%el mensaje anterior es de 16 bytes mas 2 del CHK quda 18 que es el 18 dec
%o 0x12 que aparece en el mensaje
%el argumento de esta función debe ser tipo string, y para el ejemplo
%anterior, son 32 caracteres

%SOLO FUNCIONA PARA MENSAJES PARES, PODRÍA AFECTAR EL CAMPO EXTFRAME, PERO
%EN LA NORMA VIENE DEFINIDO QUE SON PALABRAS DE 16 BITS O 8 BYTES, POR LO
%QUE NO DEBERIA SER IMPAR NUNCA PERO NO ESTOY SEGURO


%%TENER CUIDADO CON EL TIPO DE DATOS INTRODUCIDO
%%ES DIFERENTE ABCD COMO ASCCII Y ABCD COMO VALOR HEX
%convertir caracteres a vector de números
tic;

crc =65535;% 0xFFFF
MessLen = length(message);
for i=1:2:MessLen
    n = hex2dec(message(i:i+1)); %para tomar dos bytes en lugar de 1
    temp = bitxor(bitshift(crc,-8,'uint16'),n);
    crc = bitshift(crc,8,'uint16'); %si no le pongo el tipo explicito, no funciona
    quick = bitxor(temp,bitshift(temp,-4,'uint16'),'uint16');
    crc = bitxor(crc,quick,'uint16');
    quick = bitshift(quick,5,'uint16');
    crc = bitxor(crc,quick,'uint16');
    quick = bitshift(quick,7,'uint16');
    crc = bitxor(crc,quick,'uint16');
    
end

sprintf('%X',crc)
toc