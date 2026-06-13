clear; clc;

if ~exist('templates.mat','file')
    error('templates.mat not found. Run lab_train_templates first.');
end
load templates.mat

fprintf('Step 1/10: Recording speech and playing raw + quantized...\n');
[x, fs] = lab_record_digit(1.0, 0.5);
sound(x, fs);
pause(1.2);
[x_q, fs16] = lab_preprocess_signal(x, fs);
sound(x_q, fs16);
pause(1.2);

fprintf('Step 2/10: Plotting raw waveform...\n');
t = (0:length(x)-1)/fs;
figure; plot(t, x); grid on;
title('Raw Recorded Speech');
xlabel('Time (s)');
ylabel('Amplitude');

fprintf('Step 3/10: Framing and plotting raw + windowed frame...\n');
frame_ms = 30;
hop_ms = 15;
frame_len = round(frame_ms*1e-3*fs16);
hop = round(hop_ms*1e-3*fs16);
frames = lab_frame_signal(x_q, frame_len, hop);
frame = frames(:, 1);
w = hann(frame_len, 'periodic');
frame_w = frame .* w;
figure; plot(frame); grid on;
title('First Frame (Raw)');
xlabel('Sample'); ylabel('Amplitude');
figure; plot(frame_w); grid on;
title('First Frame (Windowed)');
xlabel('Sample'); ylabel('Amplitude');

fprintf('Step 4/10: Building and plotting Mel filterbank...\n');
nfft = 2^nextpow2(frame_len);
num_mel = 40;
[H, ~] = lab_mel_filterbank(num_mel, nfft, fs16);
figure; hold on;
for k = 1:num_mel
    plot(H(k,:), '.');
end
grid on;
title('Mel Filterbank (Dots)');
xlabel('FFT Bin Index'); ylabel('Weight');

fprintf('Step 5/10: FFT magnitude up to 4 kHz...\n');
F = fft(frame_w, nfft);
Fmag = abs(F(1:nfft/2+1));
freq = linspace(0, fs16/2, nfft/2+1);
figure;
plot(freq, Fmag);
xlim([0 4000]);
grid on;
title('FFT Magnitude up to 4 kHz');
xlabel('Frequency (Hz)'); ylabel('|X(f)|');

fprintf('Step 6/10: Log-magnitude spectrum up to 4 kHz...\n');
figure;
plot(freq, log(Fmag + eps));
xlim([0 4000]);
grid on;
title('Log-Magnitude Spectrum up to 4 kHz');
xlabel('Frequency (Hz)'); ylabel('log(|X(f)|)');

fprintf('Step 7/10: Mel energies and log Mel energies...\n');
E = H * Fmag(:);
E_log = log(E + eps);
figure;
stem(0:num_mel-1, E);
grid on;
title('Mel Energies');
xlabel('Filter Index'); ylabel('Energy');
figure;
stem(0:num_mel-1, E_log);
grid on;
title('Log Mel Energies');
xlabel('Filter Index'); ylabel('log(Energy)');

fprintf('Step 8/10: DCT (MFCC) of the frame...\n');
C = dct(E_log);
num_ceps = 13;
mfcc_frame = C(1:num_ceps);
figure;
stem(1:num_ceps, mfcc_frame);
grid on;
title('MFCC Coefficients (First Frame)');
xlabel('Coefficient Index'); ylabel('Value');

fprintf('Step 9/10: End-to-end feature extraction and recognition...\n');
feat_test = lab_compute_features(x_q, fs16);
num_digits = size(templates, 2);
dists = zeros(1, num_digits);
for d = 1:num_digits
    dists(d) = norm(feat_test - templates(:, d));
    fprintf('  Progress %d/%d, digit %d, distance = %.4f\n', d, num_digits, d-1, dists(d));
end
[~, idx_min] = min(dists);
recognized_digit = idx_min - 1;
fprintf('\nRecognized digit: %d\n', recognized_digit);
fprintf('Distances to templates (0..9):\n');
disp(dists);

fprintf('Step 10/10: Showing quantization ranges at key stages...\n');
fprintf('ADC-like signal (x_q):      min = %.4f, max = %.4f\n', min(x_q), max(x_q));
fprintf('Windowed frame (frame_w):   min = %.4f, max = %.4f\n', min(frame_w), max(frame_w));
fprintf('FFT magnitude (Fmag):       min = %.4f, max = %.4f\n', min(Fmag), max(Fmag));
fprintf('Mel energies (E):           min = %.4f, max = %.4f\n', min(E), max(E));
fprintf('Log Mel energies (E_log):   min = %.4f, max = %.4f\n', min(E_log), max(E_log));
fprintf('Frame MFCC (mfcc_frame):    min = %.4f, max = %.4f\n', min(mfcc_frame), max(mfcc_frame));
fprintf('Utterance MFCC (feat_test): min = %.4f, max = %.4f\n', min(feat_test), max(feat_test));

fprintf('\nLab-6 demo sequence finished.\n');
