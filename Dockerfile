FROM uwgac/ubuntu-18.04-hpc

MAINTAINER Kenny Westerman <kewesterman@mgh.harvard.edu>

RUN apt-get update && apt-get install -y git python3 python3-pip libeigen3-dev autoconf 

RUN git clone https://github.com/GenABEL-Project/ProbABEL \
	&& cd ProbABEL \
	&& autoreconf -i \
	&& ./configure \
	&& make \
	&& make check \
	&& make install

ENV PATH  /ProbABEL/src:$PATH

RUN git clone https://github.com/large-scale-gxe-methods/probabel-workflow
RUN pip3 install pandas scipy
