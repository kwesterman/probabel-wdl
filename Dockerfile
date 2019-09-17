FROM uwgac/topmed-master:latest

MAINTAINER Kenny Westerman <kewesterman@mgh.harvard.edu>

RUN apt-get update && apt-get -y install libeigen3-dev

RUN git clone https://github.com/kwesterman/probabel-wdl
RUN probabel-wdl/install_probabel.sh

RUN wget https://github.com/broadinstitute/wdltool/releases/download/0.14/wdltool-0.14.jar && wdltool=wdltool-0.14.jar
RUN wget https://github.com/broadinstitute/cromwell/releases/download/46/cromwell-46.jar && cromwell=cromwell-46.jar
