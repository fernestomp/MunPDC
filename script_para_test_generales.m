clc; clear all;
nBytes = 8;%8bytes 32bits y 32bits
endByte_PHEst = 17+(nBytes*6)-1;


df = [...
    170 001 000 074 000 003 099 220 006 178 009 006 023 181 000 000 069 248 ...
241 122 191 251 063 205 069 248 241 122 192 129 213 060 069 248 241 122 ...
062 006 170 182 068 231 066 175 191 242 010 207 068 231 066 175 192 127 ...
015 249 068 231 066 175 062 080 082 164 066 112 061 113 000 000 000 000 ...
046 183];
facConv=1.0000e-03;
fasores = df(17:endByte_PHEst);
PHNMR =6;
PHEst = zeros(PHNMR,2); %numero de fasores, mag y ang

for i = 1:PHNMR
            
    inicio = nBytes*(i-1)+1;
    fin = inicio+nBytes-1;
    fnbytes = fasores(inicio:fin);
    %el estandar maneja valores punto flotante de 32 bits, eso tipo single
    %en matlab
    bytesMag = uint8([fnbytes(4) fnbytes(3) fnbytes(2) fnbytes(1)]);
    phMagnitude = typecast(bytesMag,'single');
    bytesAng = uint8([fnbytes(8) fnbytes(7) fnbytes(6) fnbytes(5)]);
    phAngle = typecast(bytesAng,'single');
    %fprintf('Fasor %i\n',i)
    %fprintf('Magnitud: %f (%f)\n',phMagnitude,phMagnitude*sqrt(3))
    %fprintf('Ángulo: %f\n',phAngle)
    %fprintf('-------------------------------------\n')
    PHEst(i,1) = phMagnitude * facConv; %Magnitud
    PHEst(i,2) = rad2deg(phAngle); %angulo
    fprintf('Fasor %i, factor de conversion %f\n',i,facConv)
    fprintf('Magnitud: %f (%f)\n',PHEst(i,1),PHEst(i,1)*sqrt(3))
    fprintf('Ángulo: %f\n',PHEst(i,2))
    fprintf('-------------------------------------\n')
end
decodeDataFrameV2(df,CFG2)
