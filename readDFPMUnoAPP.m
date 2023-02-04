% para leer los dataframes que esta mandando el pmu
function reading = readDFPMUnoAPP(conn,cfgData,cellPhasors,numFramesALeer)
%conn: objeto tcpclient
%cfgData: struct con los datos de configuracion obtenidos del PMU (i.e.
%CGG2 frame)


numFramesLeidos=0;
while numFramesLeidos <numFramesALeer

    if conn.BytesAvailable > 0
        
        dFrame = read(conn);
        [decodedDF, PHEst, ANEst, DIGBits] = decodeDataFrame(...
            dFrame,...
            cfgData.PH_REP,...
            cfgData.FREQ_REP,...
            cfgData.AN_REP,...
            cfgData.PH_POL_REP,...
            cfgData.PH_NUMBER,...
            cfgData.AN_NUMBER,...
            cfgData.DG_NUMBER,...
            cfgData.TIME_BASE,...
            cfgData.FACCONV);
        
        tiempo = double(decodedDF.SOC) + (double(decodedDF.FRACSEC)/double(cfgData.TIME_BASE));
        
        %t = num2str(int32(tiempo));
        %us = t(end-2:end);
        tiempocalc = datetime(tiempo, 'ConvertFrom', 'posixtime', 'Format','MM/dd/yy HH:mm:ss.SSSS');

        reading  = PHEst ;
                
        
        %% calculando angulos de referencia con respecto  fase a
        %esto de identificar el primer fasor puede hacerse solo con el orden de la lista de fasores
        %no me acuerdo porque lo hice así pero así,buscando el string de
        %los fasores, pero así lo voy a dejar
        %para simplificar los primeros tres fasores de voltaje son los
        %primeros fasores configurados en la PMU. Pero puede que haya más
        %fasores de voltaje o que no sean los primeros tres. 
        %Se podría buscar no el nombre del fasor sino el tipo (Tension o
        %corriente) y agruparlos de tres en tres.
        idxa = find(strcmp(cellPhasors(1:end,1), 'PH1')); %primer fasor de voltaje segun la documentacion
            
            if idxa > 0
            
                %primer fasor referenciado a cero
                angPHAA = PHEst(idxa,2); %angulo de referencia, fase A
                %magFas = [str2double(cellPhasors{idxa,3}(:,1:end-2)), 0]; %valor reportado por la PMU
                
            end
        
        idxb = find(strcmp(cellPhasors(1:end,1), 'PH2')); %segundo fasor de voltaje segun la documentacion
            
            if idxb > 0
                angDirPHAB =PHEst(idxb,2);
                if angPHAA >= 0 && angDirPHAB <= 0 
                    angRefPHAB =  angDirPHAB -angPHAA; %angulo referenciado a la fase b
                end
                if angPHAA <= 0 && angDirPHAB >= 0 
                    angRefPHAB =  (angDirPHAB -angPHAA -360); 
                end
                if angPHAA <= 0 && angDirPHAB <= 0 
                    angRefPHAB =  angDirPHAB -angPHAA; %angulo referenciado a la fase b
                end
                if angPHAA >= 0 && angDirPHAB >= 0 
                    angRefPHAB =  angDirPHAB -angPHAA; %angulo referenciado a la fase b
                end
                %magFas(end+1,:) = [str2double(cellPhasors{idxb,3}(:,1:end-2)), angRefPHAB];
                
            end
            
            idxc = find(strcmp(cellPhasors(1:end,1), 'PH3')); %tercer fasor de voltaje segun la documentacion
            
            if idxc > 0
                angDirPHAC = PHEst(idxc,2);
                if angPHAA >= 0 && angDirPHAC <= 0 
                    angRefPHAC =  angDirPHAC- angPHAA +360; %angulo referenciado a la fase b
                end
                if angPHAA <= 0 && angDirPHAC >= 0 
                    angRefPHAC =  angDirPHAC -angPHAA ; 
                end
                if angPHAA <= 0 && angDirPHAC <= 0 
                    angRefPHAC =  angDirPHAC -angPHAA; %angulo referenciado a la fase b
                end
                if angPHAA >= 0 && angDirPHAC >= 0 
                    angRefPHAC =  angDirPHAC -angPHAA; %angulo referenciado a la fase b
                end
                %magFas(end+1,:) = [str2double(cellPhasors{idxc,3}(:,1:end-2)),angRefPHAC];
            
            end
            %en la PMU que estoy usando yo no tengo este voltaje, por eso
            %lo comento, pero creo que por default los equipos de sel si lo
            %tienen
            
            %voltaje de secuencia positiva, solo tiene que restarse el angulo de referencia de la fase A (prueba visual)
            %idxSP = find(strcmp(cellPhasors(1:end,2), 'V1PM            ')); %tercer fasor de voltaje segun la documentacion
            %if idxSP >0
               % angRefSP = PHEst(idxSP,2)-angPHAA;     
            %end
        
            %EL ANGULO VS NO ESTA REFERENCIADO A FASE A    
        PHEstARef = [PHEst PHEst(:,2)]; %fasores estimados incluidos angulos referenciados a fase A
        PHEstARef(idxa,3)=0;
        PHEstARef(idxb,3)=angRefPHAB;
        PHEstARef(idxc,3)=angRefPHAC;
        %angulo de referencia de secuencia positiva. ver los comentarios de
        %arriba
        %PHEstARef(idxSP,3)=angRefSP;
        
    numFramesLeidos = numFramesLeidos+1;
    end
    pause(eps);

end
