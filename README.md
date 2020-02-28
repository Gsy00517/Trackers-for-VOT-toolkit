# Trackers integrated into the vot toolkit



## Introduction

### This repository contains several trackers I have integrated into [vot-toolkit](https://github.com/votchallenge/vot-toolkit), you can see the README in each tracker's folder for more details.



## System Requirements

### All trackers included were tested on Ubuntu18.04 with MATLAB2018b.



## Suggestions

### Trying to run NCC first with vot-toolkit is recommanded. To achieve this, you can follow  [VOT Chanllenge support](http://www.votchallenge.net/howto/). You may also need  [VOT Challenge technical support](https://groups.google.com/forum/?hl=en#!forum/votchallenge-help) and [VOT toolkit issues](https://github.com/votchallenge/vot-toolkit/issues?utf8=%E2%9C%93&q=https://github.com/votchallenge/vot-toolkit/issues?utf8=✓&q=) to search for more help.



## Trouble Shooting

### When I was trying to run NCC, I met with this ERROR: "Tracker has not passed the TraX support test."

### Actually, this problem can be avoided by changing vot-toolkit/tracker/tracker_run.m a little bit.

- #### Find this:

  ```matlab
  connection = 'standard';
  ```

- #### Replace the above with:

  ```matlab
  connection = 'socket';
  ```

