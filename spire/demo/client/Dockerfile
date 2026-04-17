# build stage
FROM golang:1.24-alpine AS builder
WORKDIR /app
COPY . .
RUN go mod init spire-demo && go mod tidy
RUN cd client && CGO_ENABLED=0 go build -o client .

# final stage
FROM scratch
COPY --from=builder /app/client/client /client
ENTRYPOINT ["/client"]
