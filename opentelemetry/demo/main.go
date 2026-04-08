// main.go
package main

import (
	"context"
	"log"
	"net/http"
	"os"

	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.21.0"
	"google.golang.org/grpc"
)

// Initializes an OTLP exporter, and configures the corresponding trace provider.
func initTracer() (func(context.Context), error) {
	ctx := context.Background()

	res, err := resource.New(ctx,
		resource.WithAttributes(
			// the service name used to display traces in backends
			semconv.ServiceNameKey.String("go-app-service"),
		),
	)
	if err != nil {
		return nil, err
	}

	// Set up a trace exporter
	conn, err := grpc.DialContext(ctx, os.Getenv("OTEL_EXPORTER_OTLP_ENDPOINT"),
		grpc.WithInsecure(),
	)
	if err != nil {
		return nil, err
	}

	traceExporter, err := otlptracegrpc.New(ctx, otlptracegrpc.WithGRPCConn(conn))
	if err != nil {
		return nil, err
	}

	// Register the trace exporter with a batch processor to combine spans for export.
	bsp := sdktrace.NewBatchSpanProcessor(traceExporter)
	tracerProvider := sdktrace.NewTracerProvider(
		sdktrace.WithSampler(sdktrace.AlwaysSample()),
		sdktrace.WithResource(res),
		sdktrace.WithSpanProcessor(bsp),
	)
	otel.SetTracerProvider(tracerProvider)

	// set global propagator to tracecontext (the default is no-op).
	otel.SetTextMapPropagator(propagation.TraceContext{})

	// Shutdown will flush any remaining spans.
	return func(ctx context.Context) {
		tracerProvider.Shutdown(ctx)
	}, nil
}

func main() {
	shutdown, err := initTracer()
	if err != nil {
		log.Fatal(err)
	}
	defer shutdown(context.Background())

	helloHandler := func(w http.ResponseWriter, req *http.Request) {
		w.Write([]byte("Hello from Go!"))
	}

	otelHandler := otelhttp.NewHandler(http.HandlerFunc(helloHandler), "hello")

	http.Handle("/", otelHandler)
	log.Println("Go server listening on port 8080...")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
