# Phase 3: Email Alerts via SES

# Prerequisites
Using terraform we spin up phase 1 and phase 2 then we continue from there.

# Steps

# 1. Upload Alertmanager config to use SES  
cat > alertmanager-config.yaml << 'EOF'
#(paste the full contents of alertmanager-config.yaml here,
exactly as it should appear in the file)
EOF

kubectl create secret generic alertmanager-prometheus-kube-prometheus-alertmanager \
  --from-file=alertmanager.yaml=alertmanager-config.yaml \
  --namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# 2. Create Pod-Restart PrometheusRule

cat > pod-restart-alerts.yaml << 'EOF'
EOF

kubectl apply -f pod-restart-alerts.yaml

# 3. Reload Prometheus

kubectl delete pod prometheus-prometheus-kube-prometheus-prometheus-0 -n monitoring
kubectl get pods -n monitoring | grep prometheus-prometheus-*-0

# 4. Force a pod restart to trigger your rule

kubectl delete pod prometheus-kube-prometheus-operator-676ff55fb5-jqz99 \
  -n monitoring --grace-period=0 --force

#verify restart count > 2
kubectl get pod prometheus-kube-prometheus-operator-676ff55fb5-jqz99 \
  -n monitoring -o jsonpath="{.status.containerStatuses[0].restartCount}"
  
# 5. Restart Alertmanager to send the alert
kubectl delete pod alertmanager-prometheus-kube-prometheus-alertmanager-0 -n monitoring

# 6. Check your email
Within 1–2 minutes, we will get the email at thec SES-verified address.
