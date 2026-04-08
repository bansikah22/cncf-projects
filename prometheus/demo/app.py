from prometheus_client import start_http_server, Counter
import http.server
import time

# Create a Prometheus metric to track the number of page views.
PAGE_VIEWS = Counter('http_requests_total', 'Total number of HTTP requests received')

class MyHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        # Increment the counter on each request.
        PAGE_VIEWS.inc()
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"Hello, world! I've been viewed " + str(PAGE_VIEWS._value.get()).encode() + b" times.")

if __name__ == '__main__':
    # Start up the server to expose the metrics.
    start_http_server(8000)
    # Start a simple web server on port 8080
    server = http.server.HTTPServer(('', 8080), MyHandler)
    print("Web server listening on port 8080...")
    server.serve_forever()
