FROM uwgac/topmed-master:latest

MAINTAINER Kenny Westerman <kewesterman@mgh.harvard.edu>

RUN apt-get update && apt-get -y install libeigen3-dev

RUN git clone https://github.com/kwesterman/probabel-wdl
RUN probabel-wdl/install_probabel.sh
