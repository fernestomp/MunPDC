% para leer los dataframes que esta mandando el pmu
function reading = readDFPMU(conn,cfgData,cellPhasors,app,nsegs)
%conn: objeto tcpclient
%cfgData: struct con los datos de configuracion obtenidos del PMU (i.e.
%CGG2 frame)
%app: objeto app del app designer


numfrms = 0; %cuenta el numero de frames leidos
%numero de frames que tienen que pasar para que se actualice la GUI
%esta pensado para varios frames por segundo y no varios segundos por
%frame
numfrmsupd = cfgData.DATA_RATE*nsegs; 

%numero de elementos de la matriz de fasores 
%*2 por que son magnitud y fase
neph= numel({app.PHCfg{:,2}})*2;

% fileID = fopen('PMUData.csv');
% if fileID ~= -1 %si el archivo existe
%     rdEnc = fgetl(fileID); %lee el encabezado del archivo
% end

if exist('PMUData.csv', 'file') ==0
 fileID  = fopen('PMUData.csv','a');
    %dos cellphasors uno para mag, angulo y angulo referenciado a fase a
    encabezado ={'Tiempo',cellPhasors{:,2},cellPhasors{:,2},cellPhasors{:,2},'Frecuencia'};
    %format spec
    fspenc = ['%s,',... %tiempo
        repmat('%s:Mag,',1,(neph/2)),...
        repmat('%s:Ang,',1,(neph/2)),...
        repmat('%s:AngRefA,',1,(neph/2)),... % de angulos de referencia
        '%s\n'];%frecuencia
    fprintf(fileID,fspenc, encabezado{:});
else
    fileID  = fopen('PMUData.csv','a');
end
%formatspec para los datos
fsp = ['%s,' , repmat('%.4f,',1,neph +(neph/2)) , '%.4f','\n'];%formatspec

while app.stopReadings== false

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
        numfrms = numfrms +1;
        if numfrms == numfrmsupd
            app.updateDataGUI(PHEst,tiempocalc,decodedDF.FREQEST,cfgData)
            numfrms=0;
        end
        
        
        %% calculando angulos de referencia con respecto  fase a
            idxa = find(strcmp(cellPhasors(1:end,2), 'VAPM            ')); %primer fasor de voltaje segun la documentacion
            
            if idxa > 0
            
                %primer fasor referenciado a cero
                angPHAA = PHEst(idxa,2); %angulo de referencia, fase A
                %magFas = [str2double(cellPhasors{idxa,3}(:,1:end-2)), 0]; %valor reportado por la PMU
                
            end
        
        idxb = find(strcmp(cellPhasors(1:end,2), 'VBPM            ')); %segundo fasor de voltaje segun la documentacion
            
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
            
            idxc = find(strcmp(cellPhasors(1:end,2), 'VCPM            ')); %tercer fasor de voltaje segun la documentacion
            
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
            
            %voltaje de secuencia positiva, solo tiene que restarse el angulo de referencia de la fase A (prueba visual)
            idxSP = find(strcmp(cellPhasors(1:end,2), 'V1PM            ')); %tercer fasor de voltaje segun la documentacion
            if idxSP >0
                angRefSP = PHEst(idxSP,2)-angPHAA;     
            end
        %EL ANGULO VS NO ESTA REFERENCIADO A FASE A    
        PHEstARef = [PHEst PHEst(:,2)]; %fasores estimados incluidos angulos referenciados a fase A
        PHEstARef(idxa,3)=0;
        PHEstARef(idxb,3)=angRefPHAB;
        PHEstARef(idxc,3)=angRefPHAC;
        PHEstARef(idxSP,3)=angRefSP;
        
        %%%%% guardar datos en archivo csv %%%%%%%
        data2save = {tiempocalc,...
            reshape(PHEstARef,[1,numel(PHEstARef)]),...
            (cfgData.FREQ_NOM +decodedDF.FREQEST)...
            };
        fprintf(fileID,fsp,data2save{:});
    end
    pause(eps);

end
fclose(fileID);
