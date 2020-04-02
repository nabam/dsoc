#!/bin/sh

set -eux

curl --version || { echo "Curl not found" 1>&2; exit 1; }
helm version -c || { echo "Helm not found" 1>&2; exit 1; }
minikube version || { echo "Minikube not found" 1>&2; exit 1; }
minikube status | grep 'apiserver: Running' 2>&1  || { echo "Minikube is not running" 1>&2; exit 1; }

TMPDIR=$(mktemp -d)

cleanup() {
  rm -r "$TMPDIR"
}
trap cleanup EXIT

cd "$TMPDIR"
curl -s -L https://istio.io/downloadIstio | ISTIO_VERSION=1.5.1 sh -
helm template istio-1.5.1/install/kubernetes/operator/operator-chart/ \
  --set hub=docker.io/istio \
  --set tag=1.5.1 \
  --set operatorNamespace=istio-operator \
  --set istioNamespace=istio-system | minikube kubectl -- apply -f -

minikube kubectl -- -n istio-operator rollout status deployment/istio-operator
minikube kubectl -- create ns istio-system || true

minikube kubectl -- apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: kiali
  namespace: istio-system
  labels:
    app: kiali
type: Opaque
data:
  username: YWRtaW4=
  passphrase: YWRtaW4=
EOF

minikube kubectl -- apply -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: dsoc-controlplane
spec:
  addonComponents:
    grafana:
      enabled: true
    tracing:
      enabled: true
    kiali:
      enabled: true
    grafana:
      enabled: true
  values:
    sidecarInjectorWebhook:
      rewriteAppHTTPProbe: true
    pilot:
      traceSampling: "100.0"
EOF

for i in $(seq 1 60); do
  minikube kubectl -- get crd virtualservices.networking.istio.io && break || sleep 1
done

minikube kubectl -- apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: grafana-ingress
  namespace: istio-system
spec:
  hosts:
    - grafana.challenge.local
  gateways:
    - ingressgateway
  http:
  - match:
    - uri:
        prefix: "/"
    route:
    - destination:
        host: grafana
        port:
          number: 3000
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: tracing-ingress
  namespace: istio-system
spec:
  hosts:
    - tracing.challenge.local
  gateways:
    - ingressgateway
  http:
  - match:
    - uri:
        prefix: "/"
    route:
    - destination:
        host: tracing
        port:
          number: 80
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: prometheus-ingress
  namespace: istio-system
spec:
  hosts:
    - prometheus.challenge.local
  gateways:
    - ingressgateway
  http:
  - match:
    - uri:
        prefix: "/"
    route:
    - destination:
        host: prometheus
        port:
          number: 9090
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: kiali-ingress
  namespace: istio-system
spec:
  hosts:
    - kiali.challenge.local
  gateways:
    - ingressgateway
  http:
  - match:
    - uri:
        prefix: "/"
    route:
    - destination:
        host: kiali
        port:
          number: 20001
EOF

minikube kubectl -- apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: istio-system
spec:
  mtls:
    mode: STRICT
EOF

minikube kubectl -- label namespace default istio-injection=enabled --overwrite=true


for i in $(seq 1 60); do
  minikube kubectl -- -n istio-system get deployment istiod && break || sleep 1
done
minikube kubectl -- -n istio-system rollout status deployment/istiod
