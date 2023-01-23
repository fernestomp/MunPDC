function ciclo(app)
while 1
  r =[ (120 + (130-120)*rand(1)) (-180 + (180+180)*rand(1))]
pause(0.001)
if app.stopReadings== true
    break
end
end