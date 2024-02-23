#!/bin/bash

# Set namespace
NAMESPACE="lens-metrics"

# Create directory if it doesn't exist
mkdir -p "$NAMESPACE"

# Define resources (including serviceaccounts)
RESOURCES=(
  "statefulset.apps/prometheus"
  "deployment.apps/kube-state-metrics"
  "daemonset.apps/node-exporter"
  "service/kube-state-metrics"
  "service/node-exporter"
  "service/prometheus"
  "serviceaccount/kube-state-metrics"
  "serviceaccount/prometheus"
  "configmap/prometheus-config"
  "configmap/prometheus-rules"
  "clusterrole/lens-kube-state-metrics"
  "clusterrole/lens-prometheus"
  "clusterrolebindings/lens-kube-state-metrics"
  "clusterrolebindings/lens-prometheus"
)

# Loop through each resource and get its YAML output
for RESOURCE in "${RESOURCES[@]}"; do
  FILE_NAME="$NAMESPACE/$(echo "$RESOURCE" | tr '/' '-').yaml"
  # For services and service accounts, remove specified fields
  if [[ "$RESOURCE" =~ service/.* || "$RESOURCE" =~ serviceaccount/.* ]]; then
    kubectl get -n "$NAMESPACE" "$RESOURCE" -o yaml | yq eval 'del(.metadata.annotations) | del(.metadata.creationTimestamp) | del(.metadata.finalizers) | del(.metadata.resourceVersion) | del(.metadata.uid) | del(.status) | del(.spec.clusterIP) | del(.spec.clusterIPs) | del(.spec.internalTrafficPolicy) | del(.spec.ipFamilies) | del(.spec.ipFamilyPolicy)' - > "$FILE_NAME"
  else
    # For other resources, remove different fields
    kubectl get -n "$NAMESPACE" "$RESOURCE" -o yaml | yq eval 'del(.metadata.creationTimestamp) | del(.metadata.uid) | del(.metadata.resourceVersion) | del(.metadata.annotations."kubectl.kubernetes.io/last-applied-configuration") | del(.status)' - > "$FILE_NAME"
  fi
  echo "Resource $RESOURCE saved to $FILE_NAME"
done
