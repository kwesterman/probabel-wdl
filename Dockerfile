FROM ubuntu:latest

MAINTAINER Kenny Westerman <kewesterman@mgh.harvard.edu>

RUN apt-get update && apt-get install -y git python3 python3-pip libeigen3-dev autoconf 
RUN pip3 install pandas scipy

RUN git clone https://github.com/GenABEL-Project/ProbABEL \
	&& cd ProbABEL \
	&& autoreconf -i \
	&& ./configure \
	&& make \
	&& make check \
	&& make install

ENV PATH  /ProbABEL/src:$PATH

COPY format_probabel_phenos.py format_probabel_output.py /
