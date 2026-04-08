# Dockerfile for the backend service
FROM node:18-alpine

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm install

COPY server.js .

EXPOSE 8000
CMD [ "node", "server.js" ]
