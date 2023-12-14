#!/bin/zsh
set -e

# Please install binutils, gcc and gnu-sed first
# Currently, glibc cannot be built on MacOS

test_folder_name=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
mkdir "/opt/$test_folder_name" > /dev/null 2>&1 && rm -rf "/opt/$test_folder_name" || (echo '/opt is not writeable!'; exit)

export CC=/usr/local/bin/gcc-13
export CXX=/usr/local/bin/g++-13
export CFLAGS='-I/usr/local/include -L/usr/local/lib -march=x86-64-v3 -O3 -pipe -fno-plt -s -flto=auto'
export CXXFLAGS='-I/usr/local/include -L/usr/local/lib -march=x86-64-v3 -O3 -pipe -fno-plt -s -flto=auto'
export NCORES=$(sysctl -n hw.ncpu)

mkdir build || true
cd build

# binutils 2.32
[[ -f binutils-2.32.tar.gz ]] || curl -O -L 'https://mirrors.sjtug.sjtu.edu.cn/gnu/binutils/binutils-2.32.tar.gz'
rm -rf binutils-2.32 && tar -xf binutils-2.32.tar.gz

pushd binutils-2.32
./configure \
	--disable-debug \
	--disable-multilib \
	--disable-nls \
	--enable-deterministic-archives \
	--enable-ld=default \
	--enable-plugins \
	--prefix=/opt/merlin-5.04-toolchains \
	--target=arm-linux-gnueabihf \
	--with-system-zlib
make -j "$NCORES"
make install
rm -rf /opt/merlin-5.04-toolchains/share
popd

# linux headers 4.19
[[ -f linux-4.19.tar.gz ]] || curl -O -L 'https://mirrors.ustc.edu.cn/kernel.org/linux/kernel/v4.x/linux-4.19.tar.gz'
rm -rf linux-4.19 && tar -xf linux-4.19.tar.gz

pushd linux-4.19
make ARCH=arm mrproper
make ARCH=arm headers_check
make INSTALL_HDR_PATH=/opt/merlin-5.04-toolchains/arm-linux-gnueabihf ARCH=arm headers_install

find /opt/merlin-5.04-toolchains \( -name .install -or -name ..install.cmd \) -delete
popd

# gcc 9.5 stage 1
# Please install libmpc and isl from homebrew first
[[ -f gcc-9.5.0.tar.gz ]] || curl -O -L 'https://mirrors.sjtug.sjtu.edu.cn/gnu/gcc/gcc-9.5.0/gcc-9.5.0.tar.gz'
[[ -d gcc-9.5.0 ]] || tar -xf gcc-9.5.0.tar.gz

rm -rf gcc-build && mkdir gcc-build
pushd gcc-build
../gcc-9.5.0/configure \
	--build=x86_64-apple-darwin \
	--disable-libssp \
	--disable-libstdcxx-pch \
	--disable-libunwind-exceptions \
	--disable-lto \
	--disable-multilib \
	--disable-nls \
	--disable-plugin \
	--disable-shared \
	--disable-threads \
	--disable-werror \
	--enable-checking=release \
	--enable-clocale=gnu \
	--enable-__cxa_atexit \
	--enable-default-pie \
	--enable-default-ssp \
	--enable-gnu-indirect-function \
	--enable-gnu-unique-object \
	--enable-install-libiberty \
	--enable-languages=c,c++ \
	--enable-linker-build-id \
	--host=x86_64-apple-darwin \
	--libdir=/opt/merlin-5.04-toolchains/lib \
	--libexecdir=/opt/merlin-5.04-toolchains/lib \
	--prefix=/opt/merlin-5.04-toolchains \
	--program-prefix=arm-linux-gnueabihf- \
	--target=arm-linux-gnueabihf \
	--with-arch=armv6 \
	--with-as=/opt/merlin-5.04-toolchains/bin/arm-linux-gnueabihf-as \
	--with-build-sysroot=/opt/merlin-5.04-toolchains/arm-linux-gnueabihf \
	--with-float=hard \
	--with-fpu=vfp \
	--with-isl \
	--with-ld=/opt/merlin-5.04-toolchains/bin/arm-linux-gnueabihf-ld \
	--with-linker-hash-style=gnu \
	--with-local-prefix=/opt/merlin-5.04-toolchains/arm-linux-gnueabihf \
	--with-newlib \
	--with-sysroot=/opt/merlin-5.04-toolchains/arm-linux-gnueabihf \
	--with-system-zlib
make -j "$NCORES" all-gcc all-target-libgcc
make install
rm -rf /opt/merlin-5.04-toolchains/share
popd

## glibc headers 2.30
## Please install bison first
#[[ -f glibc-2.30.tar.gz ]] || curl -O -L 'https://mirrors.sjtug.sjtu.edu.cn/gnu/glibc/glibc-2.30.tar.gz'
#[[ -d glibc-2.30 ]] || tar -xf glibc-2.30.tar.gz
#
#rm -rf glibc-build && mkdir glibc-build
#pushd glibc-build
#../glibc-2.30/configure \
#	--build=x86_64-apple-darwin \
#	--disable-multi-arch \
#	--disable-profile \
#	--disable-werror \
#	--enable-add-ons \
#	--enable-bind-now \
#	--enable-kernel=4.19 \
#	--enable-lock-elision \
#	--enable-stack-protector=strong \
#	--enable-stackguard-randomization \
#	--host=arm-linux-gnueabihf \
#	--libdir=/lib \
#	--libexecdir=/lib \
#	--prefix=/ \
#	--target=arm-linux-gnueabihf \
#	--with-headers=/opt/merlin-5.04-toolchains/arm-linux-gnueabihf/include
#make -j "$NCORES" csu/subdir_lib
#make install
#popd

## gcc 9.5
#[[ -f gcc-9.5.0.tar.gz ]] || curl -O -L 'https://mirrors.sjtug.sjtu.edu.cn/gnu/gcc/gcc-9.5.0/gcc-9.5.0.tar.gz'
#[[ -d gcc-9.5.0 ]] || tar -xf gcc-9.5.0.tar.gz
#
#rm -rf gcc-build && mkdir gcc-build
#cd gcc-build
#../gcc-9.5.0/configure \
#	--build=x86_64-apple-darwin \
#	--disable-libssp \
#	--disable-libstdcxx-pch \
#	--disable-libunwind-exceptions \
#	--disable-multilib \
#	--disable-nls \
#	--disable-werror \
#	--enable-checking=release \
#	--enable-clocale=gnu \
#	--enable-__cxa_atexit \
#	--enable-default-pie \
#	--enable-default-ssp \
#	--enable-gnu-indirect-function \
#	--enable-gnu-unique-object \
#	--enable-install-libiberty \
#	--enable-languages=c,c++ \
#	--enable-linker-build-id \
#	--enable-lto \
#	--enable-plugin \
#	--enable-shared \
#	--enable-threads=posix \
#	--host=x86_64-apple-darwin \
#	--libdir=/opt/merlin-5.04-toolchains/lib \
#	--libexecdir=/opt/merlin-5.04-toolchains/lib \
#	--prefix=/opt/merlin-5.04-toolchains \
#	--program-prefix=arm-linux-gnueabihf- \
#	--target=arm-linux-gnueabihf \
#	--with-arch=armv6 \
#	--with-as=/opt/merlin-5.04-toolchains/bin/arm-linux-gnueabihf-as \
#	--with-build-sysroot=/opt/merlin-5.04-toolchains/arm-linux-gnueabihf \
#	--with-float=hard \
#	--with-fpu=vfp \
#	--with-isl \
#	--with-ld=/opt/merlin-5.04-toolchains/bin/arm-linux-gnueabihf-ld \
#	--with-linker-hash-style=gnu \
#	--with-local-prefix=/opt/merlin-5.04-toolchains/arm-linux-gnueabihf \
#	--with-sysroot=/opt/merlin-5.04-toolchains/arm-linux-gnueabihf \
#	--with-system-zlib
#make -j "$NCORES"
#make install

## glibc 2.30
#curl -O -L

