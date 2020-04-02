# Demo of K8S and Istio

Repository contains
- source code, kustomize and docker files for 2 applications:
  [hello-world-service](./hello-world-service/) and [again-service](./again-service/)
- example application dashboard and custom configuration for monitoring
  components
- scripts to bootstrap demo on minikube

## Requirements

- `docker` to build applications
- `minikube` to run on top of
- `curl` to download istio
- `helm` to deploy istio operator

## Bootstrap

To bootstrap demo invoke `./boostrap-demo.sh`.
If bootstrap succeeds you will see a banner with instruction on how to expose services.

## Istio

In that example istio perform following tasks
- Provides ingress gateway with HTTP routing
- Enables mutual TLS connections between services and ingress gateway
- Serves telemetry from the mesh

## Infrastructure

Observability tools that come together with istio are available after
solution is bootstrapped:
- [http://grafana.challenge.local](http://grafana.challenge.local) - graphing and dashboards
- [http://tracing.challenge.local](http://tracing.challenge.local) - request tracing
- [http://kiali.challenge.local ](http://kiali.challenge.local)  - mesh overview (admin:admin)

Tools cover most of the observability functions except log collection. I
would use some managed solution or in-house elasticsearch to performe
such task.

In real installations those tools should be either managed separately or
replaced with managed solutions (Instana, CloudWatch, Stackdriver,
Datadog, etc...)
