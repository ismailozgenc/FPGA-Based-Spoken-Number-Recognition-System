clear; clc;

load templates.mat

fprintf('Recording test digit...\n');
[x, fs] = lab_record_digit(1.5, 0.5);

[x_q, fs16] = lab_preprocess_signal(x, fs);

feat_test = lab_compute_features(x_q, fs16);

num_digits = size(templates, 2);
dists = zeros(1, num_digits);

for d = 1:num_digits
    dists(d) = norm(feat_test - templates(:, d));
    fprintf('Progress %d/%d, digit %d, distance = %.4f\n', d, num_digits, d-1, dists(d));
end

[~, idx_min] = min(dists);
recognized_digit = idx_min - 1;

fprintf('\nRecognized digit: %d\n', recognized_digit);
disp('Distances to templates (0..9):');
disp(dists);
