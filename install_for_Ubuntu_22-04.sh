#!/bin/bash


# Build for Ubuntu 22.04
if [[ "$(grep -Po '(?<=DISTRIB_RELEASE=)[0-9\.]*$' /etc/lsb-release)" == "22.04" ]] ; then
    echo "Creating build directory"
    openvino=$(cd ../ && pwd)
    cd ..
    mkdir build && cd build

    echo "Installing Python dependencies"
    sudo apt update
    sudo apt-get install -y --no-install-recommends python3-pip python3.10-venv
    python3 -m venv venv
    source venv/bin/activate
    python3 -m pip install --upgrade pip
    python3 -m pip install -r "${openvino}"/docs/requirements.txt
    python3 -m pip install -r "${openvino}"/src/bindings/python/wheel/requirements-dev.txt
    python3 -m pip install -r "${openvino}"/cmake/developer_package/ncc_naming_style/requirements_dev.txt
    python3 -m pip install "${openvino}"/docs/openvino_sphinx_theme
    python3 -m pip install "${openvino}"/docs/openvino_custom_sphinx_sitemap

    host_cpu=$(uname -m)

    if ! command -v cmake &> /dev/null; then
        cmake_packages=(cmake)
    fi

    sudo apt-get install -y --no-install-recommends \
    	gcc-multilib \
    	g++-multilib \
        file \
        build-essential \
        ccache \
        "${cmake_packages[@]}" \
        "${x86_64_specific_packages[@]}" \
        pkg-config \
        git \
        shellcheck \
        patchelf \
        fdupes \
        gzip \
        lintian \
        libtbb-dev \
        libpugixml-dev \
        libva-dev \
        python3-pip \
        python3-venv \
        python3-setuptools \
        libpython3-dev \
        libffi-dev \
        python3-enchant \
        libgflags-dev \
        zlib1g-dev \
        wget \
	liblua5.2-0 \
	clang-14 \
	libclang-14-dev \
	graphviz \
	texlive-latex-extra \
	doxygen


    # TF lite frontend
    if apt-cache search --names-only '^libflatbuffers-dev'| grep -q libflatbuffers-dev; then
        sudo apt-get install -y --no-install-recommends libflatbuffers-dev
    fi
    # git-lfs is not available on debian9
    if apt-cache search --names-only '^git-lfs'| grep -q git-lfs; then
        sudo apt-get install -y --no-install-recommends git-lfs
    fi
    # for python3-enchant
    if apt-cache search --names-only 'libenchant1c2a'| grep -q libenchant1c2a; then
        sudo apt-get install -y --no-install-recommends libenchant1c2a
    fi
    # samples
    if apt-cache search --names-only '^nlohmann-json3-dev'| grep -q nlohmann-json3; then
        sudo apt-get install -y --no-install-recommends nlohmann-json3-dev
    else
        sudo apt-get install -y --no-install-recommends nlohmann-json-dev
    fi

    # cmake 3.20.0 or higher is required to build OpenVINO
    current_cmake_ver=$(cmake --version | sed -ne 's/[^0-9]*\(\([0-9]\.\)\{0,4\}[0-9][^.]\).*/\1/p')
    required_cmake_ver=3.20.0
    if [ ! "$(printf '%s\n' "$required_cmake_ver" "$current_cmake_ver" | sort -V | head -n1)" = "$required_cmake_ver" ]; then
	installed_cmake_ver=3.23.2
	arch=$(uname -m)
	cmake_install_bin="cmake-${installed_cmake_ver}-linux-${arch}.sh"
	github_cmake_release="https://github.com/Kitware/CMake/releases/download/v${installed_cmake_ver}/${cmake_install_bin}"
	wget "${github_cmake_release}" -O "${cmake_install_bin}"
	chmod +x "${cmake_install_bin}"
	"./${cmake_install_bin}" --skip-license --prefix=/usr/local
	rm -rf "${cmake_install_bin}"
    fi

    cd build
    cmake "${openvino}" -DENABLE_DOCS=ON -DENABLE_DOCKER=ON

else
    echo "This script only works with Ubuntu 22.04"
fi

