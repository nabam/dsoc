# Hello World app

That is a simple app that adds ", again" to the response of hello world service and serves it on HTTP GET /

# Local Development

To build app container invoke `docker build . -t dsoc/again-service`

To deploy to minikube invoke `kubectl apply -k k8s/overlays/minikube`
