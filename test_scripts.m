ip = "192.168.1.10";
puerto = 4712;
idcode = 1;

%se solicita el configuration frame 2 
[tcpobj, dFrame] = conectarPMU(ip,puerto,idcode);
%se decodifica el configuration frame 2
[CFG2, cellPhasors] = decodeCFG2(dFrame);
%se manda del comando para que la PMU empiece a transmitir datos
cmd = 2;%turn on transmission of dataframes
sendCMD(cmd,idcode ,tcpobj)
%aquí esta lo no tan simple. hay que rellenar los datos obtenidos del
%configuration frame 2 
%cellphasors contiene los datos de los fasores y cfg2 contiene los datos de
%configuracion de la pmu necesarios para decodificar el data frame
%la siguiente funcion debe de ir en un ciclo o algun codigo que se repita,
%ya que la pmu esta mandando datos indiscriminadamente (asincronamete)
%lo que hago en la app es leer continumamente los datos del socket y de ahi
%procedo a identificar los dataframes individualmente y decodificarlos.

[decodedDF, PHEst, ANEst, DIGBits] = decodeDataFrame(dFrame, repPH,repFREQ,repAN,...
repPHpol,PHNMR,ANNMR,DGNMR,timeBase,facConv); 

%despues de decodificar los datos hay que visulizarlos, ya sea imprimiendo
%a consola o en una interfaz gráfica.

