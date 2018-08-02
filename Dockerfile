FROM debian:8

RUN set -x && \
    apt-get update -yq && \
    apt-get install --yes --no-install-recommends \
        build-essential \
        ca-certificates \
        g++-4.9 \
        gcc-4.9 \
        gfortran-4.9 \
        git \
        ninja-build \
        unzip \
        wget \
        libblas3 \
        liblapack3 \
        libbz2-dev \
        && \
    apt-get clean && \
    rm -rf /tmp/* /var/tmp/* && \
    rm -rf /var/lib/apt/lists

RUN update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.9 100
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.9 100
RUN update-alternatives --install /usr/bin/gfortran gfortran /usr/bin/gfortran-4.9 100
RUN update-alternatives --set g++ /usr/bin/g++-4.9
RUN update-alternatives --set gcc /usr/bin/gcc-4.*
RUN update-alternatives --set gfortran /usr/bin/gfortran-4.*

RUN mkdir -p /opt
WORKDIR /opt

RUN mkdir -p /opt/cmake && \
    wget https://cmake.org/files/v3.5/cmake-3.5.2-Linux-x86_64.sh -O cmake.sh && \
    sh ./cmake.sh --exclude-subdir --prefix=/opt/cmake && \
    rm -rf cmake.sh
ENV PATH="/opt/cmake/bin:${PATH}"

# BOOST 1.60 with Boost geometry extensions
# SSC : system thread random chrono
# XDYN : program_options filesystem system regex
# libbz2 is required for Boost compilation
RUN wget http://sourceforge.net/projects/boost/files/boost/1.60.0/boost_1_60_0.tar.gz -O boost_src.tar.gz && \
    mkdir -p boost_src && \
    tar -xzf boost_src.tar.gz --strip 1 -C boost_src && \
    rm -rf boost_src.tar.gz && \
    cd boost_src && \
    ./bootstrap.sh && \
    ./b2 cxxflags=-fPIC --without-mpi --without-python link=static threading=single threading=multi --layout=tagged --prefix=/opt/boost install
# BOOST Geometry extension
RUN git clone https://github.com/boostorg/geometry && \
    cd geometry && \
    git checkout 4aa61e59a72b44fb3c7761066d478479d2dd63a0 && \
    cp -rf include/boost/geometry/extensions /opt/boost/include/boost/geometry/. && \
    cd .. && \
    rm -rf geometry

# Ipopt
ENV IPOPT_VERSION=3.12.9
RUN \
    ##################
    # Download ipopt source
    # http://www.coin-or.org/Ipopt/documentation/node10.html
    ##################
    gfortran --version && \
    wget http://www.coin-or.org/download/source/Ipopt/Ipopt-$IPOPT_VERSION.tgz -O ipopt_src.tgz && \
    mkdir -p ipopt_src && \
    tar -xf ipopt_src.tgz --strip 1 -C ipopt_src && \
    rm -rf ipopt_src.tgz && \
    cd ipopt_src && \
    # Downloading BLAS, LAPACK, and ASL
    cd ThirdParty/Blas && \
        ./get.Blas && \
    cd ../Lapack && \
        ./get.Lapack && \
    cd ../ASL && \
        ./get.ASL && \
    # Downloading MUMPS Linear Solver
    cd ../Mumps && \
        ./get.Mumps && \
    # Get METIS
    cd ../Metis && \
        ./get.Metis && \
    ##################
    # Compile ipopt
    ##################
    cd ../../ && \
    mkdir build && \
    cd build && \
    ../configure -with-pic --disable-shared --prefix=/opt/CoinIpopt && \
    make && \
    make test && \
    make install && \
    cd .. && \
    cd .. && \
    rm -rf ipopt_src