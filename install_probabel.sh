#!/bin/bash

git clone https://github.com/GenABEL-Project/ProbABEL 

cd ProbABEL
autoreconf -i

./configure
make
make check
make install
