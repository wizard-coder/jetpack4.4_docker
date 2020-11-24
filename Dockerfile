FROM nvcr.io/nvidia/l4t-base:r32.4.3

ENV DEBIAN_FRONTEND=noninteractive 

# debs folder
ARG DEB_FOLDER=debs/

###################################
######## zsh part start ########
###################################
WORKDIR /install/zsh
RUN sh -c "$(wget --quiet --no-check-certificate -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.1.1/zsh-in-docker.sh)" -- \
    -p git \
    -p https://github.com/zsh-users/zsh-autosuggestions \
    -p https://github.com/zsh-users/zsh-syntax-highlighting


###################################
######## cuda and related part start ########
###################################
WORKDIR /install/cuda
ARG CUDA_VAR=cuda-repo-10-2-local-10.2.89
ARG CUDA_DPKG=cuda-repo-l4t-10-2-local-10.2.89
ARG CUDA_DEB=cuda-repo-l4t-10-2-local-10.2.89_1.0-1_arm64.deb
ARG CUDNN_DEB=libcudnn8_8.0.0.180-1+cuda10.2_arm64.deb
ARG CUDNN_DEV_DEB=libcudnn8-dev_8.0.0.180-1+cuda10.2_arm64.deb
ARG CUDNN_DOC_DEB=libcudnn8-doc_8.0.0.180-1+cuda10.2_arm64.deb

# copy from the SDK
COPY ${DEB_FOLDER}${CUDA_DEB} .
COPY ${DEB_FOLDER}${CUDNN_DEB} .
COPY ${DEB_FOLDER}${CUDNN_DEV_DEB} .
COPY ${DEB_FOLDER}${CUDNN_DOC_DEB} .

RUN apt-get update && apt-get install -y gnupg && \
    dpkg -i ${CUDA_DEB} && \
    apt-key add /var/${CUDA_VAR}/7fa2af80.pub && \
    dpkg -i ${CUDNN_DEB} \
    ${CUDNN_DEV_DEB} \
    ${CUDNN_DOC_DEB} && \
    apt-get update && \
    apt-get install -y cuda-toolkit-10-2 \
    cuda-compiler-10-2 && \
    dpkg --remove ${CUDA_DPKG} && \
    dpkg -P ${CUDA_DPKG} && \
    echo "/usr/lib/aarch64-linux-gnu/tegra" > /etc/ld.so.conf.d/nvidia-tegra.conf && \
    ldconfig 

###################################
######## opencv part start ########
###################################

# WORKDIR /install/opencv
ARG OPENCV_DEV=OpenCV-4.1.1-2-gd5a58aa75-aarch64-dev.deb
ARG OPENCV_LIB=OpenCV-4.1.1-2-gd5a58aa75-aarch64-libs.deb
ARG OPENCV_LICENSE=OpenCV-4.1.1-2-gd5a58aa75-aarch64-licenses.deb
ARG OPENCV_PYTHON=OpenCV-4.1.1-2-gd5a58aa75-aarch64-python.deb

COPY ${DEB_FOLDER}${OPENCV_DEV} .
COPY ${DEB_FOLDER}${OPENCV_LIB} .
COPY ${DEB_FOLDER}${OPENCV_LICENSE} .
COPY ${DEB_FOLDER}${OPENCV_PYTHON} .

RUN apt-get update && \
    apt-get install -y libgtk2.0-dev \
    libtbb-dev \
    lbzip2 \
    git wget unzip \
    cmake automake build-essential \
    autoconf libtool \
    libgtk2.0-dev pkg-config \
    libavcodec-dev \
    libgstreamer1.0-0 \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    gstreamer1.0-doc \
    gstreamer1.0-tools \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    ffmpeg \
    zlib1g-dev \
    libwebp-dev \
    libtbb2 libtbb-dev \
    libavcodec-dev libavformat-dev \
    libswscale-dev libv4l-dev

RUN dpkg -i ${OPENCV_DEV} \
    ${OPENCV_LIB} \
    ${OPENCV_LICENSE} \
    ${OPENCV_PYTHON}

###################################
######## ros part start ########
###################################
ARG ROS_PKG=ros_base
ENV ROS_DISTRO=melodic
ENV ROS_ROOT=/opt/ros/${ROS_DISTRO}
ENV ROS_PYTHON_VERSION=3

WORKDIR /install/ros_${ROS_DISTRO}

# add the ROS deb repo to the apt sources list
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    cmake \
    build-essential \
    curl \
    wget \ 
    gnupg2 \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
RUN apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654

# install ROS packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ros-${ROS_DISTRO}-ros-base \
    ros-${ROS_DISTRO}-image-transport \
    ros-${ROS_DISTRO}-vision-msgs \
    python-rosdep \
    python-rosinstall \
    python-rosinstall-generator \
    python-wstool \
    && rm -rf /var/lib/apt/lists/*

# init/update rosdep
RUN apt-get update && \
    cd ${ROS_ROOT} && \
    rosdep init && \
    rosdep update && \
    rm -rf /var/lib/apt/lists/*

# cv_bridge for python3 and opencv4
# install dependancy
RUN apt-get update && \
    apt-get install -y python3-pip \
    python-catkin-tools python3-dev python3-numpy && \
    pip3 install rospkg catkin_pkg

WORKDIR /ros_package/cv_bridge_ws/src
RUN git clone -b noetic https://github.com/wizard-coder/vision_opencv.git

WORKDIR /ros_package/cv_bridge_ws
RUN catkin config -DPYTHON_EXECUTABLE=/usr/bin/python3 \
    -DPYTHON_INCLUDE_DIR=/usr/include/python3.6m \
    -DPYTHON_LIBRARY=/usr/lib/aarch64-linux-gnu/libpython3.6m.so
RUN catkin config --install
RUN . ${ROS_ROOT}/setup.sh && catkin build cv_bridge




# add to zshrc
RUN echo 'source ${ROS_ROOT}/setup.zsh' >> /root/.zshrc
RUN echo 'source /ros_package/cv_bridge_ws/install/setup.zsh --extend' >> /root/.zshrc


###################################
######## pytorch part start ########
###################################

# install prerequisites (many of these are for numpy)

WORKDIR /install/pytorch
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3-pip \
    python3-dev \
    libopenblas-dev \
    libopenmpi2 \
    openmpi-bin \
    openmpi-common \
    gfortran \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install setuptools Cython wheel
RUN pip3 install numpy --verbose

#
# PyTorch (for JetPack 4.4 DP)
#
#  PyTorch v1.2.0 https://nvidia.box.com/shared/static/lufbgr3xu2uha40cs9ryq1zn4kxsnogl.whl (torch-1.2.0-cp36-cp36m-linux_aarch64.whl)
#  PyTorch v1.3.0 https://nvidia.box.com/shared/static/017sci9z4a0xhtwrb4ps52frdfti9iw0.whl (torch-1.3.0-cp36-cp36m-linux_aarch64.whl)
#  PyTorch v1.4.0 https://nvidia.box.com/shared/static/c3d7vm4gcs9m728j6o5vjay2jdedqb55.whl (torch-1.4.0-cp36-cp36m-linux_aarch64.whl)
#  PyTorch v1.5.0 https://nvidia.box.com/shared/static/3ibazbiwtkl181n95n9em3wtrca7tdzp.whl (torch-1.5.0-cp36-cp36m-linux_aarch64.whl)
#  PyTorch v1.6.0 https://nvidia.box.com/shared/static/9eptse6jyly1ggt9axbja2yrmj6pbarc.whl (torch-1.6.0-cp36-cp36m-linux_aarch64.whl)
ARG PYTORCH_URL=https://nvidia.box.com/shared/static/9eptse6jyly1ggt9axbja2yrmj6pbarc.whl	
ARG PYTORCH_WHL=torch-1.6.0-cp36-cp36m-linux_aarch64.whl

RUN wget --quiet --show-progress --progress=bar:force:noscroll --no-check-certificate ${PYTORCH_URL} -O ${PYTORCH_WHL} && \
    pip3 install ${PYTORCH_WHL} --verbose && \
    rm ${PYTORCH_WHL}


#
# torchvision 0.6
#
WORKDIR /install/torchvision
ARG TORCHVISION_VERSION=v0.6.0
ARG PILLOW_VERSION=pillow<7
ARG TORCH_CUDA_ARCH_LIST="5.3;6.2;7.2"

RUN printenv && echo "torchvision version = $TORCHVISION_VERSION" && echo "pillow version = $PILLOW_VERSION" && echo "TORCH_CUDA_ARCH_LIST = $TORCH_CUDA_ARCH_LIST"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    build-essential \
    libjpeg-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

RUN git clone -b ${TORCHVISION_VERSION} https://github.com/pytorch/vision torchvision && \
    cd torchvision && \
    python3 setup.py install && \
    cd ../ && \
    rm -rf torchvision && \
    pip3 install "${PILLOW_VERSION}"


###################################
######## tensorrt part start ########
###################################
WORKDIR /install/tensorrt
ARG TENSORRT=tensorrt_7.1.3.0-1+cuda10.2_arm64.deb
ARG LIB_INFER_BIN=libnvinfer-bin_7.1.3-1+cuda10.2_arm64.deb
ARG LIB_INFER_DEV=libnvinfer-dev_7.1.3-1+cuda10.2_arm64.deb
ARG LIB_INFER_DOC=libnvinfer-doc_7.1.3-1+cuda10.2_all.deb
ARG LIB_PLUGIN_DEV=libnvinfer-plugin-dev_7.1.3-1+cuda10.2_arm64.deb
ARG LIB_PLUGIN7=libnvinfer-plugin7_7.1.3-1+cuda10.2_arm64.deb
ARG LIB_INFER7=libnvinfer7_7.1.3-1+cuda10.2_arm64.deb
ARG LIB_INFER_SAMPLE=libnvinfer-samples_7.1.3-1+cuda10.2_all.deb
ARG LIB_ONNXPARSER_DEV=libnvonnxparsers-dev_7.1.3-1+cuda10.2_arm64.deb
ARG LIB_ONNXPARSER7=libnvonnxparsers7_7.1.3-1+cuda10.2_arm64.deb
ARG LIB_NVPARSER_DEV=libnvparsers-dev_7.1.3-1+cuda10.2_arm64.deb
ARG LIB_NVPARSER7=libnvparsers7_7.1.3-1+cuda10.2_arm64.deb
ARG PYTHON_LIB_INFER=python3-libnvinfer_7.1.3-1+cuda10.2_arm64.deb
ARG PYTHON_LIB_INFER_DEV=python3-libnvinfer-dev_7.1.3-1+cuda10.2_arm64.deb

COPY ${DEB_FOLDER}${LIB_INFER7} .
COPY ${DEB_FOLDER}${LIB_PLUGIN7} .
COPY ${DEB_FOLDER}${LIB_PLUGIN_DEV} .
COPY ${DEB_FOLDER}${LIB_NVPARSER7} .
COPY ${DEB_FOLDER}${LIB_ONNXPARSER7} .
COPY ${DEB_FOLDER}${LIB_INFER_BIN} .
COPY ${DEB_FOLDER}${LIB_INFER_DEV} .
COPY ${DEB_FOLDER}${LIB_NVPARSER_DEV} .
COPY ${DEB_FOLDER}${LIB_ONNXPARSER_DEV} .
COPY ${DEB_FOLDER}${LIB_INFER_SAMPLE} .
COPY ${DEB_FOLDER}${LIB_INFER_DOC} .
COPY ${DEB_FOLDER}${TENSORRT} .
COPY ${DEB_FOLDER}${PYTHON_LIB_INFER} .
COPY ${DEB_FOLDER}${PYTHON_LIB_INFER_DEV} .

RUN apt-get update && apt-get install -y gnupg && \
    dpkg -i ${LIB_INFER7} \
    ${LIB_PLUGIN7} \
    ${LIB_PLUGIN_DEV} \
    ${LIB_NVPARSER7} \
    ${LIB_ONNXPARSER7} \
    ${LIB_INFER_BIN} \
    ${LIB_INFER_DEV} \
    ${LIB_NVPARSER_DEV} \
    ${LIB_ONNXPARSER_DEV} \
    ${LIB_INFER_SAMPLE} \
    ${LIB_INFER_DOC} \
    ${TENSORRT} \
    ${PYTHON_LIB_INFER} \
    ${PYTHON_LIB_INFER_DEV}

#################################################
############### python upgrade #####################
#################################################
WORKDIR /install/python
RUN python3 -m pip install --upgrade pip && \
    pip3 freeze > requirements.txt && \
    pip3 install -r requirements.txt --upgrade


#### delete
WORKDIR /
RUN rm -rf /install
RUN apt-get autoremove


### entrypoint
ENTRYPOINT [ "/bin/zsh" ]