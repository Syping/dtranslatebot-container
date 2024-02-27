FROM almalinux:9 AS build

ARG DPP_COMMIT=9ccd5db6171862f85c481974a6b3acd6d3ae6741
ARG DTB_COMMIT=912ac1eced6ae7762fdae0298137e69ff1566151

# Install build dependencies
RUN dnf install -y yum-utils && \
    dnf config-manager --set-enabled crb
RUN dnf install -y cmake clang git ninja-build openssl-devel openssl-libs python3-pip zlib zlib-devel yum-utils

# Install LibreTranslate in virtual environment
RUN mkdir -p /opt/libretranslate && \
    python3 -m venv /opt/libretranslate && \
    source /opt/libretranslate/bin/activate && \
    pip3 install libretranslate==1.5.5 \ 
        --extra-index-url https://download.pytorch.org/whl/cpu

# Build libdpp and dtranslatebot
RUN mkdir -p /root/src && \
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
    cmake --install dtranslatebot-build

# Copy built files and dtranslatebot-ltd
RUN mkdir -p /root/destdir/opt && \
    mkdir -p /root/destdir/usr/local/bin && \
    mkdir -p /root/destdir/usr/local/lib64 && \
    cp -R /opt/libretranslate /root/destdir/opt/ && \
    cp /usr/local/bin/dtranslatebot /root/destdir/usr/local/bin/ && \
    cp /usr/local/lib64/libdpp.so* /root/destdir/usr/local/lib64/
COPY dtranslatebot-ltd.py /root/destdir/usr/local/bin/dtranslatebot-ltd

# Build the image
FROM almalinux:9
RUN dnf install -y openssl-libs python3-requests zlib && \
    dnf clean all
COPY --from=build /root/destdir/ /
ENTRYPOINT ["/usr/local/bin/dtranslatebot-ltd"]
