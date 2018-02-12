FROM golang:1.9-stretch as geth

RUN git clone https://github.com/ethereum/go-ethereum.git
RUN cd go-ethereum && make all

FROM ethereum/solc:stable as solc

FROM python

RUN apt-get update -y
RUN apt-get install -y \
  libssl-dev \
  git \
  build-essential \
  cmake \
  g++ \
  gcc \
  libboost-all-dev \
  unzip

WORKDIR /
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt

COPY --from=geth /go/go-ethereum/build/bin/* /usr/local/bin/
COPY --from=solc /usr/bin/solc /usr/bin/solc
RUN mkdir /bevy
WORKDIR /bevy
COPY . .
RUN pip install -e .

