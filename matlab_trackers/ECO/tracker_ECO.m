% Copy this template configuration file to your VOT workspace.
% Enter the full path to the ECO repository root folder.

tracker_label = 'ECO';

tracker_command = generate_matlab_command('eco(''ECO'', ''VOT2016_DEEP_settings'', true)', {'abs_path/ECO'});

tracker_interpreter = 'matlab';
