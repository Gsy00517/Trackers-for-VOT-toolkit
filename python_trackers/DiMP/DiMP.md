# DiMP

Code from: https://github.com/visionml/pytracking

## Preparation

### Note that this test needs a GPU with cuda toolkit, if you want to run on a single CPU, you'd better check the [GitHub issues](https://github.com/visionml/pytracking/issues?q=) for help.

### Because of system difference, it is recommended to set the environment step-by-step. My setting is a bit different with the official steps and I will write my steps later. Before that, you can follow the steps in the official repository and contact me if you meet any issues.

### To run the trackers, you need several parameters files downloaded. If you are in China and have trouble in downloading the file using official links, you can use my copy at [BaiduNetdisk](https://pan.baidu.com/share/init?surl=62V1MCVIls4eJufVC3QOGA) with code: 2vdz.

### Please replace the followings, remember to change the environment path and absolute path.

- #### in tracker_DiMP.m

  ##### python_path = 'env_path/bin/python';

  ##### pytracking_path = 'abs_path/trackers/DiMP/pytracking';

  ##### trax_path = 'abs_path/vot-toolkit/native/trax';

### Move tracker_DiMP.m to your workspace.

### Then, you can run the tracker within VOT toolkit following [VOT Chanllenge support](http://www.votchallenge.net/howto/).

## System Requirements

- ### Ubuntu(recommended, tested with 16.04LTS)

- ### MATLAB(tested with R2017a)

- ### Nvidia GPU with cuda toolkit installed

