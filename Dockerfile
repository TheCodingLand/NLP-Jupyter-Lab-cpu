ARG BASE_CONTAINER=ubuntu:bionic
FROM $BASE_CONTAINER
ARG NB_USER="jovyan"
ARG NB_UID="1000"
ARG NB_GID="100"

ENV DEBIAN_FRONTEND noninteractive
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8


#build deps
RUN apt-get update && apt-get -yq dist-upgrade \
 && apt-get install -yq --no-install-recommends \
    wget \
    bzip2 \
    ca-certificates \
    sudo \
    locales \
    fonts-liberation \
 && rm -rf /var/lib/apt/lists/*

 RUN apt-get update && apt-get install -yq --no-install-recommends \
    build-essential \
    emacs \
    git \
    inkscape \
    jed \
    libsm6 \
    libxext-dev \
    libxrender1 \
    lmodern \
    netcat \
    pandoc \
    python-dev \
    texlive-fonts-extra \
    texlive-fonts-recommended \
    texlive-generic-recommended \
    texlive-latex-base \
    texlive-latex-extra \
    texlive-xetex \
    unzip \
    nano \
    bash \
    python3-pip \
    curl \
    unzip \
    libosmesa-dev \
    libglew-dev \
    patchelf \
    libglfw3-dev \
    graphviz \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y python3-dev
#RUN apt-get install -y python-setuptools

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen

COPY ./fix-permissions /usr/local/bin/fix-permissions
RUN chmod 777 /usr/local/bin/fix-permissions

ENV HOME=/home/$NB_USER

RUN groupadd wheel -g 11 
RUN echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su
RUN useradd -m -s /bin/bash -N -u $NB_UID $NB_USER
RUN chmod g+w /etc/passwd
RUN mkdir -p /usr/local/bin/
RUN mkdir -p /home/jovyan/install/fastText
RUN fix-permissions $HOME

USER $NB_USER

ENV JUPYTER_ENABLE_LAB yes
RUN pip3 install setuptools
COPY requirements.txt .
RUN pip3 install -r requirements.txt

WORKDIR /home/jovyan/install
RUN pip3 install pybind11
RUN mkdir -p /home/jovyan/install/fastText
RUN fix-permissions /home/jovyan/install/fastText
RUN git clone https://github.com/facebookresearch/fastText.git
WORKDIR /home/jovyan/install/fastText
USER root
ENV PATH="${PATH}:/home/jovyan/.local/bin"
RUN echo "export PATH=$PATH" > /etc/environment

USER $NB_USER
RUN whoami
RUN python3 setup.py install --user
RUN pip3 install wheel
RUN wget https://github.com/Anacletus/tensorflow-wheels/raw/master/v11.0/tensorflow-1.11.0-cp36-cp36m-linux_x86_64.whl
RUN pip3 install tensorflow-1.11.0-cp36-cp36m-linux_x86_64.whl

RUN echo $PATH
#RUN ~/.local/bin/jupyter serverextension enable --py jupyterlab
RUN jupyter serverextension enable --py jupyterlab
RUN mkdir -p /home/jovyan/work
WORKDIR /home/jovyan/work

CMD cd /home/jovyan/work && jupyter notebook --ip=0.0.0.0 --NotebookApp.password='sha1:fb84cfae37ec:091b809499d14466fa8884f84ab724b6964fb61d'