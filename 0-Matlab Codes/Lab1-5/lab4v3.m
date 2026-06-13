clear s; close all; clc
comPort = 'COM4'; baudRate = 115200; fs = 15625; frameLen = 512;

s = serialport(comPort, baudRate); s.Timeout = 10; flush(s);
sc = uint8([hex2dec('03') hex2dec('CC') hex2dec('AA') hex2dec('55')]);
ec = uint8([hex2dec('CC') hex2dec('03') hex2dec('55') hex2dec('AA')]);

buf = uint8([]); t0 = tic; got = false;
while true
    b = read(s,1,"uint8");
    if isempty(b)
        if toc(t0)>30, error('timeout'); else, continue; end
    end
    buf(end+1) = b;

    if ~got
        k = strfind(buf,sc);
        if ~isempty(k)
            buf = buf(k(1)+4:end);
            got = true;
        else
            if numel(buf)>256, buf = buf(end-255:end); end
        end
    else
        k = strfind(buf,ec);
        if ~isempty(k)
            payload = buf(1:k(1)-1);
            break;
        end
    end
end
clear s

% ---- EXTRACT 32-bit WORDS ----
nwhole = floor(numel(payload)/4);
payload = payload(1:4*nwhole);
dw = typecast(uint8(payload), 'uint32').';

% ---- PADDING FIX (makes length exactly 512) ----
if nwhole < frameLen
    warning('Received %d words; padding to %d', nwhole, frameLen);
    % Harmless: pad with zero words
    dw(end+1:frameLen) = uint32(0);
end
% ------------------------------------------------

W = dw(1:frameLen);

prod20 = bitand(bitshift(W,-12), uint32(2^20-1));
p = double(prod20);
p(p>=2^19) = p(p>=2^19) - 2^20;

coef = [];
try
    txt = fileread('hann.txt');
    z = split(erase(extractBetween(txt,'memory_initialization_vector=',';'),[" ",newline,","]));
    z = z(~cellfun(@isempty,z));
    v = hex2dec(z);
    if numel(v) >= 512
        coef = double(v(1:512));
    end
end

if isempty(coef)
    coef = double(round(255 * hann(512,'periodic')));
end

idx = coef > 0;
adc_est = nan(512,1);
adc_est(idx) = p(idx) ./ coef(idx);
adc_est = fillmissing(adc_est,'nearest');

vin = 1.65 + adc_est*(3.3/4096);
t = (0:511)/fs;

valid = ~isnan(vin);
fprintf('VIN(valid): mean=%.6f V  min=%.6f V  max=%.6f V  valid=%d/%d\n', ...
        mean(vin(valid)), min(vin(valid)), max(vin(valid)), nnz(valid), numel(vin));

figure; plot(t,vin,'.-'); grid on; xlabel('Time (s)'); ylabel('V');
title('Estimated VIN (de-windowed, first 512 samples)'); ylim([0 3.3])

xw = double(p);
xw = xw - mean(xw);
X  = fft(xw);
K  = floor(numel(X)/2);
f  = (0:K-1)*(fs/numel(X));
mag = 20*log10(abs(X(1:K)) + 1e-12);

figure; plot(f, mag); grid on; xlabel('Hz'); ylabel('dB');
title('Windowed-frame Spectrum (single Hann total)')
