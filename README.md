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

### By default, each tracker will repeat 3 times when you execute run_experiments.m. If you want run your tracker only once during experiment, you can add the following code between workspace_load() and workspace_evaluate().

```matlab
experiments{1,1}.parameters.repetitions = 1;
```



## Methods

### As far as I know, there mainly three ways to integrate a new tracker.

1. ### As mentioned in suggestions, if the wrapper is provided by the author, you will be lucky because all you need is to replace the vot function files such as vot.m or something.

2. ### However, because of the big difference between each version of VOT toolkit, the method above doesn't work in many ways. During the integration work, I found that if the input of the run file  is the sequence while the output is the results, then the wrapper provided by Martin Danelljan may be very useful.

   ```matlab
   function results = runfile(seq, res_path, bSaveImage, parameters)
   ```

   ### Needless to say, it works for the trackers proposed by Martin himself, such as CCOT, ECO, SRDCF, UPDT, to name a few. It seems that it also works when I apply it to GFSDCF's demo.

3. ### The most universal approach is following  [VOT Chanllenge support](http://www.votchallenge.net/howto/) and the example NCC to add handle at the proper positions so that the information can be recognized and obtained by VOT toolkit. More examples like KCF, Staple, DAT etc. can be found in this repository.



## Trouble Shooting

1. ### <u>Tracker execution interrupted: Unable to establish connection</u>

#### When I was trying to run NCC, I met with this ERROR: "Tracker execution interrupted: Unable to establish connection" and it indicates that "TraX support not detected" or "Tracker has not passed the TraX support test".

#### Actually, this problem can be avoided by modifying vot-toolkit/tracker/tracker_run.m a little bit.

- #### Find this:

  ```matlab
  connection = 'standard';
  ```

- #### Replace the above with:

  ```matlab
  connection = 'socket';
  ```

2. ### <u>Tracker execution interrupted: Did not receive response</u>

#### If you have already passed the TraX support test but receive this ERROR: "Tracker execution interrupted: Did not receive response". This is mainly caused by tracker crash. You'd better check the generated log file for the tracker you want to run under the file vot-workspace/logs/tracker_name.

#### If there are no problem with your code, then the problem may come from environment. Take my experience as an example, when I tried to run NCC and some other MATLAB trackers, I always met the ERROR above and the log files told me some functions such as normxcorr2, configureKalmanFilter, etc. were undefined. This is because some required MATLAB toolboxes were not installed. If you only install the default toolboxes, then it will be hard for visual object trackers written in MATLAB to run and the VOT toolkit also cannot work. In that case, you can search the undefined function to find the corresponding toolbox. The following toolboxes are recommended  to install.

- MATLAB(default in MATLAB R2018b)
- Simulink(default in MATLAB R2018b)
- Computer Vision System Toolbox
- Deep Learning Toolbox
- Image Acquisition Toolbox
- Image Processing Toolbox(Required by VOT toolkit)
- Parallel Computing Toolbox
- Sensor Fusion and Tracking Toolbox
- Signal Processing Toolbox
- Statistics and Machine Learning Toolbox(default in MATLAB R2018b)
- Symbolic Math Toolbox(default in MATLAB R2018b)
- Vision HDL Toolbox

#### Some of these may be redundant, but I promise that you can successfully run the tracker with these toolboxes.

#### If you have already installed the MATLAB, don't worry, you can run the MATLAB install file again to add the toolboxes above or use add-ons in MATLAB GUI to search and install.

3. ### <u>Tracker execution interrupted: Invalid MEX-file</u>

#### I also have met this ERROR: "Tracker execution interrupted: Invalid MEX-file". The list of the invalid MEX-files might be short or long, but I think the reason is the same. This issue is due to the old version of the libstdc++. To solve this, you can execute the following commands in terminal.

```l
cd /usr/local/MATLAB/R2018b/sys/os/glnxa64
sudo mv libstdc++.so.6.0.20 bak-libstdc++.so.6.0.20
sudo mv libstdc++.so.6 bak-libstdc++.so.6
sudo ln -sf /usr/lib/x86_64-linux-gnu/libstdc++.so.6.0.21 ./
sudo ln -sf ./libstdc++.so.6.0.21 ./libstdc++.so.6
```

#### Note that in the first command, you should change to the directory where your MATLAB is installed. Otherwise, the followed commands may cause some system problem.

4. ### <u>Warning: The version of gcc is not supported</u>

#### During the compile process, you may keep getting the warning that warn you that your version is not suitable. Actually, it doesn't matter. Just ignore it and compiling still can be done.

#### However, if you are using a very old version of MATLAB and the toolkit still cannot work, then maybe you really need to change the version of gcc.

#### You can check the version of gcc in your system by:

```
gcc --version
```

#### or simply by:

```
gcc -v
```

#### You can change the version of gcc and g++(e.g. to version 4.7 for old version MATLAB) by executing the following commands:

```
sudo apt-get install gcc-4.7
sudo apt-get install g++-4.7
cd usr/bin
sudo rm gcc
sudo ln -s gcc-4.7 gcc
sudo rm g++
sudo ln -s g++-4.7 g++
ls -al gcc g++
```

