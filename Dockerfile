FROM uwgac/ubuntu-18.04-hpc

MAINTAINER Kenny Westerman <kewesterman@mgh.harvard.edu>

RUN apt-get update && apt-get install -y libeigen3-dev

RUN git clone https://github.com/GenABEL-Project/ProbABEL \
	&& cd ProbABEL \
	&& autoreconf -i \
	&& ./configure \
	&& make \
	&& make check \
	&& make install

ENV PATH  /ProbABEL/src:$PATH
