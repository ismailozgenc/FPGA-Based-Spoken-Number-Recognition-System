fs16 = 16000;
t = (0:16383)/fs16;
x = sin(2*pi*1000*t);
x_q = lab_quantize_signed(x, 12, 11);

fid = fopen('adc_samples.txt','w');
for n = 1:length(x_q)
    code = round(x_q(n)*2^11);
    if code < 0
        code = code + 2^12;
    end
    fprintf(fid, '%03X\n', code);
end
fclose(fid);

frame_len = 512;
hop = 256;
frames = lab_frame_signal(x_q, frame_len, hop);
frame = frames(:,1);
w = hann(frame_len,'periodic');
frame_w = frame .* w;

fid = fopen('win_frame.txt','w');
for n = 1:length(frame_w)
    fprintf(fid, '%.10f\n', frame_w(n));
end
fclose(fid);
