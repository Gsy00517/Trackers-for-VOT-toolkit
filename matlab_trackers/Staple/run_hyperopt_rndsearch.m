function run_hyperopt_rndsearch(expm_dir, num_experiments, varargin)
    run_params.dataset = 'validation';
    run_params = vl_argparse(run_params, varargin);

    hp_names = {'hog_cell_size', ...
                'fixed_area', ...
                'n_bins', ...
                'learning_rate_pwp', ...
                'inner_padding', ...
                'output_sigma_factor', ...
                'learning_rate_cf', ...
                'merge_factor', ...
                'learning_rate_scale', ...
                'scale_sigma_factor', ...
                'num_scales', ...
                'scale_step'};


    hp_values = {[3,4], ... % hog_cell_size
                (145:155).^2, ... % fixed_area
                12:24, ...   % n_bins
                linspace(0.015, 0.045, 31), ... % learning_rate_pwp
                linspace(0.01, 0.02, 21), ... % inner_padding
                linspace(0.05, 0.1, 51), ... % output_sigma_factor
                linspace(0.003, 0.02, 35), ... % learning_rate_cf
                linspace(0.45, 0.85, 41), ... % merge_factor
                linspace(0.02, 0.03, 21), ... % learning_rate_scale
                linspace(0.2, 0.5, 31), ... % scale_sigma_factor
                19:2:29, ... % num_scales
                linspace(1.02, 1.05, 31), ... %scale_step
                };

    num_hp = numel(hp_names);
    assert(numel(hp_values)==num_hp)
    dist = zeros(1, num_experiments);
    overlap = zeros(1, num_experiments);
    speed = zeros(1, num_experiments); 
    all_tracker_params = cell(1, num_experiments);

    rng('shuffle');

    if isdir(expm_dir)
        error('Experiment directory already exists');
    else
        mkdir(expm_dir);
    end

    for i = 1:num_experiments

        for j = 1:num_hp
           tracker_params.(hp_names{j}) = hp_values{j}(randi(numel(hp_values{j})));
        end

        tracker_params

        [~, ~, dist(i), overlap(i), ~, ~, speed(i), ~] = run_tracker_evaluation('all', tracker_params, run_params);
        all_tracker_params{i} = tracker_params;
        mat_name = fullfile(expm_dir, sprintf('it%03d.mat', i));
        save(mat_name, 'all_tracker_params', 'dist', 'overlap', 'speed');
    end
end
