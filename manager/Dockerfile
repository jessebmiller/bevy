FROM node:alpine

RUN npm install -g truffle
RUN mkdir /dapp
WORKDIR /dapp
COPY ./package.json ./package.json

RUN npm install

COPY ./truffle.js ./truffle.js
COPY ./contracts ./contracts

RUN truffle compile

COPY . .