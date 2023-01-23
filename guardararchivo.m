
a =[11,12;21,22;31,32;41,42;51,52;61,62;];

x = size(a,1);
y = size(a,2);
t = x*y;
fileID = fopen('testc.txt','w');
fsp = ['%d,' , '%s,' , repmat('%.4f,',1,t) , '%.4f','\n'];
for i =1:10
c = { i, 'date', reshape(a,[1,t]), 60};
fprintf(fileID,fsp,c{:});
end
fclose(fileID);