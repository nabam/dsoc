#!/bin/sh
set -eux
minikube version || { echo "Minikube not found" 1>&2; exit 1; }

cd $(dirname $0)

# minikube delete -p dsoc-demo
minikube start -p dsoc-demo
minikube profile dsoc-demo
./minikube-install-istio.sh

# Patch prometheus configuration as by some reason operator is not configuring scraping for secure endpoints
minikube kubectl -- -n istio-system patch configmap prometheus --patch "$(cat monitoring/patch-prometheus-config.yaml)" && \
  minikube kubectl -- -n istio-system delete pod -l app=prometheus

# Patch grafana config for demonstration sake
minikube kubectl -- -n istio-system create configmap application-grafana-configuration-dashboards-requests --from-file monitoring/application-dashboard.json || true
minikube kubectl -- -n istio-system patch configmap istio-grafana --patch "$(cat monitoring/patch-grafana-config.yaml)" && \
  minikube kubectl -- -n istio-system patch deployment grafana --patch "$(cat monitoring/patch-grafana-deployment.yaml)"

# Deploy apps
eval $(minikube docker-env)
(cd again-service && docker build . -t dsoc/again-service)
(cd hello-world-service && docker build . -t dsoc/hello-world-service)
minikube kubectl apply -- -k hello-world-service/k8s/overlays/minikube/
minikube kubectl apply -- -k again-service/k8s/overlays/minikube/
ip=$(minikube kubectl -- -n istio-system get services istio-ingressgateway -o jsonpath='{.spec.clusterIP}')

set +x
echo
echo '###############################################################################'
echo '#                        DEMO Bootstrapped                                    #'
echo '###############################################################################'
echo '#'
echo '# Invoke following command to add service names to /etc/hosts:'
echo
echo 'echo "'$ip' challenge.local detectify.challenge.local kiali.challenge.local grafana.challenge.local prometheus.challenge.local tracing.challenge.local" | sudo tee -a /etc/hosts'
echo
echo '# Then invoke:'
echo
echo minikube tunnel
echo
echo '# Following infrastructure components available'
echo '#'
echo '# http://grafana.challenge.local - monitoring dashboards'
echo '# http://tracing.challenge.local - distributed tracing'
echo '# http://kiali.challenge.local   - mesh overview (admin:admin)'
