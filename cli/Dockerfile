FROM golang:alpine

RUN apk add --no-cache git

RUN go get -u github.com/spf13/cobra/cobra

RUN apk del git

RUN mkdir /go/src/bevy
COPY . /go/src/bevy

WORKDIR /go/src/bevy
RUN go-wrapper download
RUN go-wrapper install
