FROM fedora:latest
# Install dependencies
WORKDIR /tmp
RUN yum upgrade -y
RUN yum install -y wget g++ curl python git bison flex bc libcap-devel bzip2 deltarpm cmake boost-devel patch ncurses-devel tmux valgrind.x86_64 valgrind.i686 libasan libasan-static zzuf gcc-c++.i686 libmudflap-devel libmudflap-static glibc-devel.i686 glibc-devel.x86_64 gcc-c++.x86_64
RUN yum groupinstall -y "C Development Tools and Libraries"

# This section builds KLEE

##  Forgetting to add llvm-gcc to your PATH at this point is by far the most common source of build errors reported by new users.
ENV PATH /opt/radamsa/bin:/opt/afl:/opt/klee/bin:/opt/llvm-2.9/bin:/opt/llvm-gcc4.2-2.9-x86_64-linux/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
## The below variable is taken from https://code.google.com/p/american-fuzzy-lop/wiki/AflDoc
## which helps with detecting memory corruption vulnerabilities. However, it doesn't work on FC20
## for whatever reason, so it's commented out, for now.
# ENV AFL_HARDEN true

## https && sha1sum would be nice for the below.
RUN wget -q -O- http://llvm.org/releases/2.9/llvm-gcc4.2-2.9-x86_64-linux.tar.bz2 | tar -C /opt -xjvf -
## fix up /opt/ file owners
RUN chown -R root:root /opt/llvm-gcc4.2-2.9-x86_64-linux/

## Configure, install LLVM-2.9
RUN mkdir /opt/workdir

## Since all this is ran in a container, that makes it 100% secure, and not an issue at all
RUN wget -O- -q http://llvm.org/releases/2.9/llvm-2.9.tgz | tar -C /opt/workdir -xzvf -
## https://www.mail-archive.com/klee-dev@imperial.ac.uk/msg01302.html
ADD unistd-llvm-2.9-jit.patch /tmp/unistd-llvm-2.9-jit.patch
RUN cd /opt/workdir/llvm-2.9 && patch -p1 </tmp/unistd-llvm-2.9-jit.patch && ./configure --prefix=/opt/llvm-2.9 --enable-optimized --enable-assertions && make -j3 && make install 
RUN rm /tmp/unistd-llvm-2.9-jit.patch

## Configure, install STP
### The next two lines are horrendous :)
RUN wget -q -O- https://github.com/stp/stp/tarball/master | tar -C /opt/workdir -xzvf -
RUN mv /opt/workdir/stp-stp* /opt/workdir/stp
RUN cd /opt/workdir/stp && mkdir build && cd build && cmake -G 'Unix Makefiles' /opt/workdir/stp/ -DCMAKE_INSTALL_PREFIX=/opt/stp && make -j3 && make install
### let the system know where to find the library
RUN echo '/opt/stp/lib' > /etc/ld.so.conf.d/stp.conf
RUN ldconfig

## Configure, install klee-uclibc

RUN cd /opt/workdir && git clone --depth 1 --branch klee_0_9_29 https://github.com/klee/klee-uclibc.git
RUN cd /opt/workdir/klee-uclibc && ./configure --make-llvm-lib && make -j3

## Configure KLEE:
RUN cd /opt/workdir && git clone --depth 1 https://github.com/klee/klee.git
RUN cd /opt/workdir/klee && ./configure --prefix=/opt/klee --with-llvm=/opt/workdir/llvm-2.9 --with-stp=/opt/stp --with-uclibc=/opt/workdir/klee-uclibc --enable-posix-runtime
RUN cd /opt/workdir/klee && make ENABLE_OPTIMIZED=1 && make install 
RUN echo '/opt/klee/lib' > /etc/ld.so.conf.d/klee.conf
RUN ldconfig
RUN cp /opt/workdir/klee/scripts/klee-gcc /opt/klee/bin

## Finally, ensure that everything works...
RUN cd /opt/workdir/klee && make check && make unittests

# This section configures american fuzzy lop
RUN wget -O- -q http://lcamtuf.coredump.cx/afl.tgz | tar -C /opt/workdir/ -xzvf -
RUN mv /opt/workdir/afl-* /opt/workdir/afl
RUN mkdir /opt/afl /opt/afl/lib
RUN cd /opt/workdir/afl &&  sed -i -e s,^BIN_PATH.*,BIN_PATH=/opt/afl/,g -e s,^HELPER_PATH.*,HELPER_PATH=/opt/afl/lib,g Makefile  && make && make install   

RUN cd /opt/workdir && git clone http://haltp.org/git/radamsa.git
# cache the owl-lisp step, just in case the line after fails
RUN cd /opt/workdir/radamsa && make get-owl
RUN cd /opt/workdir/radamsa && make && make install PREFIX=/opt/radamsa
RUN ln -s /opt/radamsa/share/man/man1/radamsa.1.gz /usr/share/man/man1/radamsa.1.gz


