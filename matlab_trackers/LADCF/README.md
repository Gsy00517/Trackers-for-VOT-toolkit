# LADCF

Code from: http://data.votchallenge.net/vot2018/trackers/LADCF-code-2018-06-18T20_59_58.836395.zip



## Preparation

### This tracker is depend on MatConvNet, PDollar Toolbox, mtimesx and mexResize, which already have been included in external_libs folder.

### Pretrained CNN models is also needed for test.

#### You must dowload [imagenet-resnet-50-dag](https://www.vlfeat.org/matconvnet/models/imagenet-resnet-50-dag.mat) and place it in feature_extraction/networks/.

### Make sure you have run install.m before the test.

### Please replace the followings, remember to change the absolute path.

- #### in tracker_LADCF.m

  ##### tracker_command = generate_matlab_command('ladcf(''LADCF'', ''VOT2018settings'', true)', {'abs_path/LADCF'});

### Move tracker_LADCF.m to your workspace.

### Then, you can run the tracker within VOT toolkit following [VOT Chanllenge support](http://www.votchallenge.net/howto/).



## Trouble Shooting

1. ### If you met with an ERROR like this: "Tracker execution interrupted: Did not receive response.", you can try to replace both LADCF/vot.m and LADCF/utils/vot.m with the vot.m in vot-toolkit/tracker/examples/matlab/.

2. ### If you use the imagenet-resnet-50-dag.mat downloaded by install.m the MAT file may can't be loaded. In that case, you'd better download the pretrained model independently from the link given in the Preparation part above.



## System Requirements

- ### Ubuntu(tested with 18.04LTS)

- ### MATLAB(tested with R2018b)

- ### The result is obtained using a single CPU