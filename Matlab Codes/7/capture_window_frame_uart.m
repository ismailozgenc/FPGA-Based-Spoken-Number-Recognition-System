function p = capture_window_frame_uart(port_name, baudRate, frameLen)
if nargin < 2
    baudRate = 115200;
end
if nargin < 3
    frameLen = 512;
end

s = serialport(port_name, baudRate);
s.Timeout = 10;
flush(s);

sc = uint8([hex2dec('03') hex2dec('CC') hex2dec('AA') hex2dec('55')]);
ec = uint8([hex2dec('CC') hex2dec('03') hex2dec('55') hex2dec('AA')]);

buf = uint8([]);
t0 = tic;
got = false;

fprintf('Waiting for WINDOW frame header on %s...\n', port_name);

while true
    b = read(s,1,"uint8");
    if isempty(b)
        if toc(t0) > 30
            clear s
            error('Timeout while waiting for WINDOW frame');
        else
            continue;
        end
    end

    buf(end+1) = b;

    if ~got
        k = strfind(buf, sc);
        if ~isempty(k)
            buf = buf(k(1)+4:end);
            got = true;
            fprintf('Header found, receiving WINDOW payload...\n');
        else
            if numel(buf) > 256
                buf = buf(end-255:end);
            end
        end
    else
        k = strfind(buf, ec);
        if ~isempty(k)
            payload = buf(1:k(1)-1);
            break;
        end
    end
end

clear s

nwhole = floor(numel(payload)/4);
payload = payload(1:4*nwhole);
dw = typecast(uint8(payload), 'uint32').';

if nwhole < frameLen
    fprintf('Received %d words; padding to %d\n', nwhole, frameLen);
    dw(end+1:frameLen) = uint32(0);
elseif nwhole > frameLen
    fprintf('Received %d words; keeping first %d\n', nwhole, frameLen);
end

W = dw(1:frameLen);

prod20 = bitand(bitshift(W,-12), uint32(2^20-1));
p = double(prod20);
p(p >= 2^19) = p(p >= 2^19) - 2^20;

fprintf('WINDOW frame capture complete (%d samples).\n', numel(p));
end
