# Docker Container for Jetson and Jetpack 4.4

This docker container is built based on l4t-base:r32.4.3 and prebuilt arm deb package which can be obtained via NVIDIA SDK Manager. This container includes following things.

- zsh with auto-suggestion and syntax-highlighing
- cuda 10.2
- opencv 4.1.1
- tensorrt 7.1.3
- ros melodic(ros-base)
- pytorch 1.6 and torchvision 0.6

## Building Docker Container on Jetson

```
sudo docker build -t jetpack:4.4 .
```

## Building Docker Container on x86 machine

```
sudo apt-get install qemu binfmt-support qemu-user-static
sudo docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

sudo docker build -t jetpack:4.4 .
```

## Build Details

### zsh

If you want to change the theme, plugins, refer to [this link](https://github.com/deluan/zsh-in-docker)

### cuda, opencv, tensorrt

It is based on prebuilt arm deb package from NVIDIA SDK Manager. So, you first download them using NVIDIA SDK Manager, and copy deb package to debs folder. The list of files is as follows.

1. cuda

   - cuda-repo-l4t-10-2-local-10.2.89_1.0-1_arm64.deb
   - libcudnn8_8.0.0.180-1+cuda10.2_arm64.deb
   - libcudnn8-dev_8.0.0.180-1+cuda10.2_arm64.deb
   - libcudnn8-doc_8.0.0.180-1+cuda10.2_arm64.deb

2. opencv

   - OpenCV-4.1.1-2-gd5a58aa75-aarch64-dev.deb
   - OpenCV-4.1.1-2-gd5a58aa75-aarch64-libs.deb
   - OpenCV-4.1.1-2-gd5a58aa75-aarch64-licenses.deb
   - OpenCV-4.1.1-2-gd5a58aa75-aarch64-python.deb

3. tensorrt
   - tensorrt_7.1.3.0-1+cuda10.2_arm64.deb
   - libnvinfer-bin_7.1.3-1+cuda10.2_arm64.deb
   - libnvinfer-dev_7.1.3-1+cuda10.2_arm64.deb
   - libnvinfer-doc_7.1.3-1+cuda10.2_all.deb
   - libnvinfer-plugin-dev_7.1.3-1+cuda10.2_arm64.deb
   - libnvinfer-plugin7_7.1.3-1+cuda10.2_arm64.deb
   - libnvinfer7_7.1.3-1+cuda10.2_arm64.deb
   - libnvinfer-samples_7.1.3-1+cuda10.2_all.deb
   - libnvonnxparsers-dev_7.1.3-1+cuda10.2_arm64.deb
   - libnvonnxparsers7_7.1.3-1+cuda10.2_arm64.deb
   - libnvparsers-dev_7.1.3-1+cuda10.2_arm64.deb
   - libnvparsers7_7.1.3-1+cuda10.2_arm64.deb
   - python3-libnvinfer_7.1.3-1+cuda10.2_arm64.deb
   - python3-libnvinfer-dev_7.1.3-1+cuda10.2_arm64.deb

### ros

It is installed from deb packages. But for python3, cv_bridge is built from source.

### pytorch and torchvision

pytorch is installed from prebuilt deb packages. torchvision is built from source.
