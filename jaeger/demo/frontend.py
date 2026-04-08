# frontend.py
from flask import Flask, request
import requests
import os

from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor

# Configure OpenTelemetry
provider = TracerProvider()
processor = BatchSpanProcessor(OTLPSpanExporter(insecure=True))
provider.add_span_processor(processor)
trace.set_tracer_provider(provider)
tracer = trace.get_tracer(__name__)

app = Flask(__name__)
FlaskInstrumentor().instrument_app(app)
RequestsInstrumentor().instrument()

@app.route("/")
def hello():
    with tracer.start_as_current_span("frontend_request"):
        # This will create a child span that is automatically correlated
        # with the parent span created by the Flask instrumentor.
        requests.get("http://backend:8082/api")
        return "Hello from Frontend!"

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8081)
