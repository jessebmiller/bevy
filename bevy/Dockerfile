from golang:1.9-alpine

run apk add --no-cache git

workdir /go/src/bevy

copy ./requirements.go ./main.go
run go-wrapper download

copy . .
run go-wrapper install

entrypoint ["go-wrapper", "run"]
