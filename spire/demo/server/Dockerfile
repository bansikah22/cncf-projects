# build stage
FROM golang:1.24-alpine AS builder
WORKDIR /app
COPY . .
RUN go mod init spire-demo && go mod tidy
RUN cd server && CGO_ENABLED=0 go build -o server .

# final stage
FROM scratch
COPY --from=builder /app/server/server /server
ENTRYPOINT ["/server"]
