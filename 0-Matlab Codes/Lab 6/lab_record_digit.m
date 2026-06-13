function [x, fs] = lab_record_digit(rec_duration, silence_duration)

if nargin < 1
    rec_duration = 1.5;
end
if nargin < 2
    silence_duration = 0.5;
end

fs = 44100;

fprintf('Get ready...\n');
pause(silence_duration);
fprintf('Speak now...\n');

recObj = audiorecorder(fs, 16, 1);
recordblocking(recObj, rec_duration);
fprintf('Done.\n');

x = getaudiodata(recObj, 'double');
