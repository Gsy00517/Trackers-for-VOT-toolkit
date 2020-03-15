% Copy this template configuration file to your VOT workspace.
% Enter the full path to the ECO repository root folder.

tracker_label = 'LADCF';

tracker_command = generate_matlab_command('ladcf(''LADCF'', ''VOT2018setting'', true)', {'abs_path/LADCF'});

tracker_interpreter = 'matlab';
