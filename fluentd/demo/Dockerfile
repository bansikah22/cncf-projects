# Dockerfile for the logging application
FROM alpine:latest

# Create the directory for logs
RUN mkdir -p /logs

# The command to run when the container starts
CMD i=0; while true; do i=$((i+1)); echo "{\"message\":\"Log entry $i\"}" >> /logs/app.log; sleep 1; done
