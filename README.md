# Trackers integrated into the vot toolkit



## Introduction

### This repository contains several trackers I have integrated into [VOT toolkit](https://github.com/votchallenge/vot-toolkit), you can see the README in each tracker's folder for more details.

### Specifically, the code is tested with the following version of VOT toolkit:[c53fa23ba1fe59181af63fff783ab243ffeeff4b](https://github.com/votchallenge/vot-toolkit/tree/c53fa23ba1fe59181af63fff783ab243ffeeff4b).

> ### p.s. Codes provided here are mainly for evaluation by VOT toolkit, for further developing, please visit the link (if given) in the README for each tracker to get more information.



## System Requirements

### All trackers included were tested on Ubuntu18.04 with MATLAB2018b. Only a single CPU is needed for the evaluation because VOT toolkit provides a evaluation strategy which can ignore the influence of different hardwares.



## Suggestions

### Trying to run NCC first with VOT toolkit is recommended. To achieve this, you can follow  [VOT Chanllenge support](http://www.votchallenge.net/howto/). You may also need  [VOT Challenge technical support](https://groups.google.com/forum/?hl=en#!forum/votchallenge-help) and [VOT toolkit issues](https://github.com/votchallenge/vot-toolkit/issues?utf8=%E2%9C%93&q=https://github.com/votchallenge/vot-toolkit/issues?utf8=✓&q=) to search for more help.

### You'd better check whether the benchmark wrapper is provided by the author before you want to integrate a new tracker. This can save your time. If there aren't any benchmark wrappers provided or there is but crushed, you can follow NCC example and the guide on the official website to integrate the tracker by yourself.



## Methods

### As far as I know, there mainly three ways to integrate a new tracker.

1. ### As mentioned in suggestions, if the wrapper is provided by the author, you will be lucky because all you need is to replace the vot function files such as vot.m or something.

2. ### However, because of the big difference between each version of VOT toolkit, the method above doesn't work in many ways. During the integration work, I found that if the input of the run file  is the sequence while the output is the results, then the wrapper provided by Martin Danelljan may be very useful.

   ```matlab
   function results = runfile(seq, res_path, bSaveImage, parameters)
   ```

   ### Needless to say, it works for the trackers proposed by Martion himself, such as CCOT, ECO, SRDCF, UPDT, to name a few. It seems that it also works when I apply it to GFSDCF's demo.

3. ### The most universal approach is following  [VOT Chanllenge support](http://www.votchallenge.net/howto/) and the example NCC to add handle at the proper positions so that the information can be recognized and obtained by VOT toolkit. More examples like KCF, Staple, DAT etc. can be found in this repository.



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

