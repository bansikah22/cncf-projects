package main

import (
	"context"
	"log"
	"net"
	"os"

	"github.com/spiffe/go-spiffe/v2/spiffetls/tlsconfig"
	"github.com/spiffe/go-spiffe/v2/workloadapi"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
	"google.golang.org/grpc/peer"

	"spire-demo/proto/helloworld"
)

// server is used to implement helloworld.GreeterServer.
type server struct {
	helloworld.UnimplementedGreeterServer
}

// SayHello implements helloworld.GreeterServer
func (s *server) SayHello(ctx context.Context, in *helloworld.HelloRequest) (*helloworld.HelloReply, error) {
	p, _ := peer.FromContext(ctx)
	if tlsInfo, ok := p.AuthInfo.(credentials.TLSInfo); ok && len(tlsInfo.State.PeerCertificates) > 0 {
		uris := tlsInfo.State.PeerCertificates[0].URIs
		if len(uris) > 0 {
			log.Printf("Received request from client with SPIFFE ID: %v", uris[0].String())
		}
	}
	return &helloworld.HelloReply{Message: "Hello " + in.Name}, nil
}

func main() {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	socketPath := os.Getenv("SPIFFE_ENDPOINT_SOCKET")
	if socketPath == "" {
		socketPath = "unix:///tmp/spire-agent/public/api.sock"
	}

	// Create a new Workload API client
	source, err := workloadapi.NewX509Source(ctx, workloadapi.WithClientOptions(workloadapi.WithAddr(socketPath)))
	if err != nil {
		log.Fatalf("Unable to create X509 source: %v", err)
	}
	defer source.Close()

	// Create a TLS configuration that uses the X509 source
	tlsConfig := tlsconfig.TLSServerConfig(source)

	listener, err := net.Listen("tcp", ":50051")
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}

	s := grpc.NewServer(grpc.Creds(credentials.NewTLS(tlsConfig)))
	helloworld.RegisterGreeterServer(s, &server{})

	log.Println("Starting server...")
	if err := s.Serve(listener); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}
