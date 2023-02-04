% para leer los dataframes que esta mandando el pmu
function dFrames = readDFnoDecode(conn,confFrame2,numFramesALeer)
%conn: objeto tcpclient




%%

numFramesLeidos=0;
dFrames= cell([1e6,0]);
while numFramesLeidos <numFramesALeer

    if conn.BytesAvailable > 0
        fprintf('Numero de bytes pendientes de leer %i\n', conn.BytesAvailable )
        dFrame = read(conn);
%         rdFRAMESIZE = dFrame(3:4);
%         %Este el número de bytes recibidos en formato decimal
%         decFRAMESIZE = typecast([rdFRAMESIZE(2) rdFRAMESIZE(1)],'uint16')
        %ya que se leyó un dataframe, los siguientes van a guardarse en
        %la misma variable pero en una dimension diferente que va
        %creciendo segun el numero de frames leidos
        %la primera dimension es 1, por eso se le suma dos a los frames
        %leidos, para que el primero se guarde en la dimension 2 y así
        %sucesivamente.
        dFrames{numFramesLeidos+1} = dFrame;      
        numFramesLeidos = numFramesLeidos+1;
    end
    
    pause(eps);

end