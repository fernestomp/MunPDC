%% This code allows to extract data from PMU via Ethernet
%para probar algunos de los scripts para leer datos de la pmu
%lee n dataframes (configurable) y te regresa un array con los datos leidos
%no decodifica los dataframes

clear all; clc

global endByte_PHEst endByte_DFREQEst
% endByte_PHEst=0;
%% Describe PMU connetion data. 
ip = "192.168.10.106";
puerto = 4713;
idcode = 3;
 
%% To connect PMU 
%se solicita el configuration frame 2 
fprintf('Intentando conectar a PMU...\n')
[tcpobj, cfg2Frame] = conectarPMU(ip,puerto,idcode);
fprintf('Conectado a PMU.\n')
fprintf('IP: %s\n',ip)
fprintf('Puerto: %i\n',puerto)
fprintf('idcode: %i\n', idcode)
%% To identify the PMU configuration
fprintf('-------------------------------------\n')
fprintf('Decodificando CFG2...\n')
fprintf('-------------------------------------\n')
[CFG2, cellPhasors] = decodeCFG2(cfg2Frame);
stParam=CFG2;
                if stParam.FREQ_REP == 0
                
                    stParam.FREQ_REP = 'Fijo';
                
                else
                
                    stParam.FREQ_REP = 'Punto flotante';
                
                end
                
                if stParam.AN_REP ==0
                
                    stParam.AN_REP = 'Entero';
               
                else
                
                    stParam.AN_REP = 'Punto flotante';
               
                end
                
                if stParam.PH_REP == 0
                
                    stParam.PH_REP = 'Entero';
               
                else
                
                    stParam.PH_REP = 'Punto flotante';
                
                end
                
                if stParam.PH_POL_REP == 0
                
                    stParam.PH_POL_REP = 'Rectangular';
                
                else
                
                    stParam.PH_POL_REP = 'Polar';
               
                end
                
                if stParam.DATA_RATE > 0
                
                    stParam.DATA_RATE = sprintf('%d frames por segundo', stParam.DATA_RATE);
               
                else
                
                    stParam.DATA_RATE = sprinft('1 frame por cada %d segundos',abs( stParam.DATA_RATE));
                
                end
stbl = [fieldnames(CFG2) struct2cell(stParam)];
fprintf('Valores le�dos de la PMU (CFG2):\n');
disp(stbl)
%%
%definiendo el formato de los datos sengun la tabla 10
if CFG2.FREQ_REP ==0
    fprintf('La frecuencia se representa con un entero de 16 bits\n')
else
    fprintf('La frecuencia se representa con punto flotante\n')
end
    
if CFG2.AN_REP == 0
    fprintf('Las se�ales anal�gicas se representan un entero de 16 bits\n')
else    
    fprintf('Las se�ales anal�gicas se representan con punto flotante\n')
end

if CFG2.PH_REP == 0
    fprintf('Los fasores se representan con un entero de 16 bits\n')
else    
    fprintf('Los fasores se representan con punto flotante\n')
end

if CFG2.PH_POL_REP == 0
    fprintf('Los fasores se representan de forma rectangular\n')
else    
    fprintf('Los fasores se representan de forma polar\n')
end

%% otros datos que vienen en el cfg2
fprintf('N�mero de fasores: %i\n',CFG2.PH_NUMBER)
fprintf('N�mero de entradas anal�gicas: %i\n',CFG2.AN_NUMBER)
fprintf('N�mero de entradas digitales: %i\n',CFG2.DG_NUMBER)
fprintf('Factor de conversi�n: %f\n',CFG2.FACCONV)
fprintf('Frecuencia nominal: %i\n',CFG2.FREQ_NOM)
fprintf('N�mero de cambios hechos a la configuraci�n de la PMU: %i\n',CFG2.CFGCNT)
fprintf('Data rate: %i\n',CFG2.DATA_RATE)

%%
fprintf('Enviando cmd 2 (Turn on transmission of data frames)...\n')
cmd=2;
sendCMD(cmd,idcode ,tcpobj);
%limpiar buffer
%revisa si hay bytes pendientes de leer en el buffer del socket
%si hay los lee
%esto es solo para limpiar el buffer y empezar la lectura de dataframes
%desde cero
if tcpobj.BytesAvailable > 0
   read(tcpobj);
end
fprintf('cmd 2 enviado.\n')
%%
%numero de frames a leer
nframes2read = 5;
fprintf('Leyendo %i data frames...\n',nframes2read)
dataFramesDecod = readDFnoDecode(tcpobj,CFG2, nframes2read);
fprintf('%i data frames leidos.\n',nframes2read)
%%
%fprintf('Cerrando conexion a PMU...\n')
%clear tcpobj
%fprintf('Conexion a PMU cerrada.\n')
%fprintf('------------------------------------\n')
%% decodificando dataframe
for i=1 : nframes2read
    dataframeDecod =decodeDataFrameV2(dataFramesDecod{i},CFG2);
    fprintf('Data frame decodificado:\n')
    disp(dataframeDecod)
    fprintf('-------------------------\n')
end
%% leer continuamente, maximo un millon de lecturas
fprintf('*********************************\n')
fprintf('Leyendo continuamente, CTRL+C para detener\n')
fprintf('**********************************\n')
dataFramesDecod= cell([1e6,0]); %almacena los dataframes decodificados
phasor_values = cell([1e6,0]);%almacena los valores de los fasores
an_values = cell([1e6,0]);%almacena los valores de las se�ales analogicas
dig_values = cell([1e6,0]);%almacena los valores de las se�ales digitales
num_df_leido = 1;
while 1
    if tcpobj.BytesAvailable>0
        nframes2read = 1;
        fprintf('Leyendo %i data frames ...\n',nframes2read)
        dataFrame = readDFnoDecode(tcpobj,CFG2, nframes2read);
        [dataFramesDecod{num_df_leido},phasor_values{num_df_leido},an_values{num_df_leido},dig_values{num_df_leido}] = ...
            decodeDataFrameV2(dataFrame{1},CFG2);
        fprintf('Data frame decodificado:\n')
        disp(dataFramesDecod{num_df_leido})
        fprintf('%i data frames leidos.\n',num_df_leido)
        fprintf('-------------------------\n')
        num_df_leido = num_df_leido+ 1;
    end
end
