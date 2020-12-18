FROM nvidia/cuda:9.0-cudnn7-devel-ubuntu16.04
ARG PYTHON_VERSION=3.6
RUN apt-get update && apt-get install -y --no-install-recommends \
         build-essential \
         cmake \
         git \
         curl \
         vim \
         ca-certificates \
         libjpeg-dev \
         libpng-dev &&\
     rm -rf /var/lib/apt/lists/*

RUN curl -o ~/miniconda.sh -O  https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh  && \
     chmod +x ~/miniconda.sh && \
     ~/miniconda.sh -b -p /opt/conda && \
     rm ~/miniconda.sh && \
     /opt/conda/bin/conda install -y python=$PYTHON_VERSION numpy pyyaml scipy ipython mkl mkl-include cython typing && \
     /opt/conda/bin/conda install -y -c pytorch magma-cuda90 && \
     /opt/conda/bin/conda clean -ya
ENV PATH /opt/conda/bin:$PATH
#RUN pip install ninja
# This must be done before pip so that requirements.txt is available
WORKDIR /opt

RUN git clone --recursive https://github.com/mysablehats/pytorch.git
RUN cd pytorch && TORCH_CUDA_ARCH_LIST="3.5 5.2 6.0 6.1 7.0+PTX" TORCH_NVCC_FLAGS="-Xfatbin -compress-all" \
    CMAKE_PREFIX_PATH="$(dirname $(which conda))/../" \
    pip install -v .

RUN git clone https://github.com/pytorch/vision.git && cd vision && pip install -v .

############# needs sshd

## merge when it works!

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -y update
RUN apt-get install -y --fix-missing \
  build-essential \
  # ros dependency, but i can add here.
  python3-pip \
  python-pip \
  openssh-server\
  libssl-dev \
  #python-sh is needed for the fix.py. once that is solved, remove it.
  python-sh \
  tar\
  lsb-release \
  # needed by opencv3
  && apt-get clean && rm -rf /tmp/* /var/tmp/*

# to get ssh working for the ros machine to be functional: (adapted from docker docs running_ssh_service)
RUN mkdir /var/run/sshd \
    && echo 'root:ros_ros' | chpasswd \
    && sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

EXPOSE 22

#### ROS stuff

ADD requirements_ros.txt /root/
RUN pip3 install --trusted-host pypi.python.org -r /root/requirements_ros.txt && \
    pip2 install --trusted-host pypi.python.org -r /root/requirements_ros.txt && \
    python -m pip install --trusted-host pypi.python.org -r /root/requirements_ros.txt

ADD scripts/ros.sh /root/
ADD requirements_ros.txt /root/

##other things we need
##ubuntu xenial comes with version 1.3.1. I probably need to static version opencv3, or this will keep breaking.
#WORKDIR /opt
#RUN wget https://github.com/facebook/zstd/releases/download/v1.3.7/zstd-1.3.7.tar.gz \
#  && tar -xvf zstd-1.3.7.tar.gz \
#  && cd zstd-1.3.7 \
#  && make \
#  && make install

##boost. libboost-dev-all needs to work, this is ridiculous
#WORKDIR /opt
#RUN git clone --recursive --branch boost-1.70.0  https://github.com/boostorg/boost.git

#RUN /opt/boost/bootstrap.sh \

#RUN /opt/boost/b2 headers \
#    && /opt/boost/b2

RUN /root/ros.sh $PYTHON_VERSION

##setting up opencv

ADD requirements_opencv.txt /root/
RUN python -m pip install --upgrade pip && \
    python -m pip install --trusted-host pypi.python.org -r /root/requirements_opencv.txt

#why? idk...
WORKDIR /root/ros_catkin_ws
RUN /root/ros_catkin_ws/src/catkin/bin/catkin_make_isolated --install -DCMAKE_BUILD_TYPE=Release \
    -DSETUPTOOLS_DEB_LAYOUT=OFF --cmake-args -DPYTHON_VERSION=$PYTHON_VERSION

##all these should work at the same time.
ADD scripts/test.sh /root
#RUN /root/test.sh

## I need to add this somewhere... to source probably
### export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/conda/lib

ADD banner.txt /root/
ADD scripts/entrypoint.sh /root/
 ## I might want to use an entrypoint in catkin_ws because it is shared and therefore updateable.
ENTRYPOINT ["/root/entrypoint.sh"]
