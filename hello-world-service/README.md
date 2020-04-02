# Hello World app

That is a simple app that serves "Hello World" string on HTTP GET /

# Local Development

To build app container invoke `docker build . -t dsoc/hello-world-service`

To deploy to minikube invoke `kubectl apply -k k8s/overlays/minikube`
