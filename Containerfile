FROM almalinux:9

ARG DPP_COMMIT=9ccd5db6171862f85c481974a6b3acd6d3ae6741
ARG DTB_COMMIT=7dcb64f7cf0244dac75b56d8e36dcceb1d683fde

RUN dnf install -y python3 python3-requests && \
    dnf clean all
RUN dnf install -y python3-pip && \
    dnf clean all && \
    mkdir -p /opt/libretranslate && \
    python3 -m venv /opt/libretranslate && \
    source /opt/libretranslate/bin/activate && \
    pip3 install libretranslate==1.5.5 \ 
        --extra-index-url https://download.pytorch.org/whl/cpu && \
    dnf remove -y python3-pip
RUN dnf install -y yum-utils && \
    dnf config-manager --set-enabled crb && \
    dnf install -y cmake clang git ninja-build openssl-devel openssl-libs zlib zlib-devel && \
    mkdir -p /root/src && \
    cd /root/src && \
    git clone https://github.com/brainboxdotcc/DPP.git dpp && \
    cd dpp && \
    git reset --hard $DPP_COMMIT && \
    cd /root/src && \
    cmake -B dpp-build dpp \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_COMPILER=clang++ \
        -DCMAKE_SHARED_LINKER_FLAGS=-s \
        -GNinja && \
    cmake --build dpp-build && \
    cmake --install dpp-build && \
    git clone https://github.com/Syping/dtranslatebot.git dtranslatebot && \
    cd dtranslatebot && \
    git reset --hard $DBT_COMMIT && \
    cd /root/src && \
    cmake -B dtranslatebot-build dtranslatebot \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_COMPILER=clang++ \
        -DCMAKE_EXE_LINKER_FLAGS=-s \
        -DCMAKE_INSTALL_RPATH=/usr/local/lib64 \
        -GNinja && \
    cmake --build dtranslatebot-build && \
    cmake --install dtranslatebot-build && \
    cd /root && \
    rm -rf \
        /root/src \
        /usr/local/include \
        /usr/local/lib64/cmake \
        /usr/local/lib64/pkgconfig && \
    dnf remove -y cmake clang git openssl-devel yum-utils zlib-devel && \
    dnf clean all
COPY dtranslatebot-ltd.py /usr/local/bin/dtranslatebot-ltd
ENTRYPOINT ["/usr/local/bin/dtranslatebot-ltd"]
