# ATOM

Code from: https://github.com/visionml/pytracking

## Preparation

### Note that this test needs a GPU with cuda toolkit, if you want to run on a single CPU, you'd better check the [GitHub issues](https://github.com/visionml/pytracking/issues?q=) for help.

### Like DiMP, ATOM is also provided in pytracking toolkit and the setting is very similar. Thus, you can try DiMP before you want to integrate ATOM.

### To run the trackers, you need several parameters files downloaded. If you are in China and have trouble in downloading the file using official links, you can use my copy at [BaiduNetdisk](https://pan.baidu.com/s/1cj6ozS0OTWwOIghurwG-zw) with code: wyx0.

### Please replace the followings, remember to change the environment path and absolute path.

- #### in tracker_ATOM.m

  ##### python_path = 'env_path/bin/python';

  ##### pytracking_path = 'abs_path/trackers/DiMP/pytracking';

  ##### trax_path = 'abs_path/vot-toolkit/native/trax';

### Move tracker_ATOM.m to your workspace.

### Then, you can run the tracker within VOT toolkit following [VOT Chanllenge support](http://www.votchallenge.net/howto/).

## System Requirements

- ### Ubuntu(recommended, tested with 16.04LTS)

- ### MATLAB(tested with R2017a)

- ### Nvidia GPU with cuda toolkit installed