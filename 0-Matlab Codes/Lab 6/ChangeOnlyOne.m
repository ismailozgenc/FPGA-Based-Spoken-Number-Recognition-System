clear; clc;

target_digit  = 4;
num_reps_new  = 3;
fs16          = 16000;

load templates.mat

num_ceps = size(templates, 1);
all_feats_new = zeros(num_ceps, num_reps_new);

for r = 1:num_reps_new
    fprintf('Digit %d, new rep %d/%d\n', target_digit, r, num_reps_new);
    [x, fs] = lab_record_digit(1.5, 0.5);
    [x_q, fs16] = lab_preprocess_signal(x, fs);
    feat = lab_compute_features(x_q, fs16);
    all_feats_new(:, r) = feat;
    fprintf('Progress %d/%d recordings\n', r, num_reps_new);
end

new_mean = mean(all_feats_new, 2);

templates(:, target_digit + 1) = new_mean;

save templates.mat templates
fprintf('Updated digit %d template and saved templates.mat\n', target_digit);
