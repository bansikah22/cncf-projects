# Dockerfile for the web app
FROM python:3.9-slim

WORKDIR /app

# Install the Prometheus client library
RUN pip install prometheus-client==0.20.0

# Copy the application code
COPY app.py .

# Expose the web server port (8080) and metrics port (8000)
EXPOSE 8080
EXPOSE 8000

CMD ["python", "app.py"]
