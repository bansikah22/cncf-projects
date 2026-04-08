# Dockerfile for the Go app
# --- Build Stage ---
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Copy the Go module files AND the source code
COPY go.mod ./
COPY main.go ./

# Download dependencies and then tidy to create go.sum
RUN go get -d ./...
RUN go mod tidy

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -o /go-app

# --- Final Stage ---
FROM alpine:latest

# Create a non-root user for security best practices
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy only the compiled binary from the builder stage
COPY --from=builder /go-app /go-app

# Switch to the non-root user
USER appuser

# Expose the web server port
EXPOSE 8080

# Run the application
CMD ["/go-app"]
