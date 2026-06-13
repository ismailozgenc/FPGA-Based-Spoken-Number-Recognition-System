function [H, mel_freqs] = lab_mel_filterbank(num_mel, nfft, fs)

fmax = fs/2;
fmin = 0;

mmin = 2595*log10(1 + fmin/700);
mmax = 2595*log10(1 + fmax/700);

mel_freqs = linspace(mmin, mmax, num_mel+2);
hz = 700*(10.^(mel_freqs/2595) - 1);

bin = floor((nfft+1)*hz/fs);

H = zeros(num_mel, nfft/2+1);

for m = 1:num_mel
    f_left = bin(m);
    f_center = bin(m+1);
    f_right = bin(m+2);
    if f_center == f_left
        f_center = f_center + 1;
    end
    if f_right == f_center
        f_right = f_right + 1;
    end
    for k = f_left:f_center
        if k >= 1 && k <= nfft/2+1
            H(m, k) = (k - f_left) / max(f_center - f_left, 1);
        end
    end
    for k = f_center:f_right
        if k >= 1 && k <= nfft/2+1
            H(m, k) = (f_right - k) / max(f_right - f_center, 1);
        end
    end
    fprintf('Progress %d/%d mel filters\n', m, num_mel);
end
