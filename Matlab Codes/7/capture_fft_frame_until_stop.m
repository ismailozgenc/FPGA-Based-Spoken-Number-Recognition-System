function mags2_fpga = capture_fft_frame_until_stop(port_name)
start_word = uint32(hex2dec('55AACC03'));
stop_word  = uint32(hex2dec('AA5503CC'));

s = serialport(port_name, 115200, "Timeout", 5);
flush(s);

fprintf('Waiting for FFT frame header on %s...\n', port_name);

while true
    b = read(s, 4, "uint8");
    if numel(b) < 4
        clear s
        error('Timeout while waiting for FFT start word');
    end
    w = typecast(uint8(b), 'uint32');
    if w == start_word
        break
    end
end

fprintf('Header found. Receiving FFT data until stop word...\n');

buf = int32([]);
k = 0;

while true
    b = read(s, 4, "uint8");
    if numel(b) < 4
        clear s
        error('Timeout before FFT stop word');
    end
    w_u = typecast(uint8(b), 'uint32');
    if w_u == stop_word
        fprintf('\nStop word seen after %d samples.\n', k);
        break
    end
    w_s = typecast(uint8(b), 'int32');
    buf(end+1,1) = w_s;
    k = k + 1;
    if mod(k,32) == 0
        fprintf('  %4d samples\r', k);
    end
end

fprintf('\n');
clear s

mags2_fpga = buf;
fprintf('FFT frame capture complete (%d bins).\n', numel(mags2_fpga));
end
