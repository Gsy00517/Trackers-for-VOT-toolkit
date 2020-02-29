# Trackers integrated into the vot toolkit



## Introduction

### This repository contains several trackers I have integrated into [VOT toolkit](https://github.com/votchallenge/vot-toolkit), you can see the README in each tracker's folder for more details.

> ### p.s. Codes provided here are mainly for evaluation by VOT toolkit, for further developing, please visit the link (if given) in the README for each tracker to get more information.



## System Requirements

### All trackers included were tested on Ubuntu18.04 with MATLAB2018b.



## Suggestions

### Trying to run NCC first with VOT toolkit is recommanded. To achieve this, you can follow  [VOT Chanllenge support](http://www.votchallenge.net/howto/). You may also need  [VOT Challenge technical support](https://groups.google.com/forum/?hl=en#!forum/votchallenge-help) and [VOT toolkit issues](https://github.com/votchallenge/vot-toolkit/issues?utf8=%E2%9C%93&q=https://github.com/votchallenge/vot-toolkit/issues?utf8=✓&q=) to search for more help.



## Trouble Shooting

### When I was trying to run NCC, I met with this ERROR: "Tracker has not passed the TraX support test."

### Actually, this problem can be avoided by modifying vot-toolkit/tracker/tracker_run.m a little bit.

- #### Find this:

  ```matlab
  connection = 'standard';
  ```

- #### Replace the above with:

  ```matlab
  connection = 'socket';
  ```

