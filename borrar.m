   %% Time specifications:
   Fs = 8000;                   % samples per second
   dt = 1/Fs;                   % seconds per sample
   StopTime = 0.05;             % seconds
   t = (0:dt:StopTime-dt)';     % seconds
   %% Sine wave:
   Fc = 60;                     % hertz
   x = cos(2*pi*Fc*t);
   x1 = cos(2*pi*Fc*t+2.0944);
   x2 = cos(2*pi*Fc*t-2.0944);
   % Plot the signal versus time:
   figure;
   hold on
   plot(t,x);
   plot(t,x1);
   plot(t,x2);
   hold off
   xlabel('time (in seconds)');
   title('Signal versus Time');
   zoom xon;