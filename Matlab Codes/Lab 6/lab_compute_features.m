function feat_vec = lab_compute_features(x, fs)

frame_ms = 30;
hop_ms = 15;

frame_len = round(frame_ms*1e-3*fs);
hop = round(hop_ms*1e-3*fs);

frames = lab_frame_signal(x, frame_len, hop);

[num_samples, num_frames] = size(frames);

w = hann(num_samples, 'periodic');
w = w(:);

frames_w = frames .* repmat(w, 1, num_frames);

nbits_win = 20;
frac_bits_win = 19;
frames_wq = lab_quantize_signed(frames_w, nbits_win, frac_bits_win);

nfft = 2^nextpow2(num_samples);

F = fft(frames_wq, nfft, 1);
Fmag = abs(F(1:nfft/2+1, :));

nbits_fft = 20;
frac_bits_fft = 19;
Fmag_q = lab_quantize_signed(Fmag, nbits_fft, frac_bits_fft);

num_mel = 40;
[mel_bank, mel_freqs] = lab_mel_filterbank(num_mel, nfft, fs);

E = mel_bank * Fmag_q;

nbits_mel = 20;
frac_bits_mel = 19;
E_q = lab_quantize_signed(E, nbits_mel, frac_bits_mel);

E_log = log(E_q + eps);

nbits_log = 20;
frac_bits_log = 18;
E_log_q = lab_quantize_signed(E_log, nbits_log, frac_bits_log);

C = dct(E_log_q);
num_ceps = 13;
C = C(1:num_ceps, :);

nbits_ceps = 16;
frac_bits_ceps = 12;
C_q = lab_quantize_signed(C, nbits_ceps, frac_bits_ceps);

feat_vec = mean(C_q, 2);
