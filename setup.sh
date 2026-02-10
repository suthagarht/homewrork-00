#!/bin/bash
set -e

# Configuration
CLUSTER_NAME="take-home"
DB_NS="db-namespace"

echo "--------------------------------------------------"
echo "Initializing Local Platform Setup"
echo "--------------------------------------------------"

# 1. Cluster Creation (Skip if exists)
if kind get clusters | grep -q "^$CLUSTER_NAME$"; then
  echo "Cluster '$CLUSTER_NAME' already exists. Skipping creation."
  kubectl config use-context kind-$CLUSTER_NAME
else
  echo "Creating Kind cluster with port mapping (8989 -> 30000)..."
  cat <<EOF | kind create cluster --name $CLUSTER_NAME --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30000
    hostPort: 8989
    listenAddress: "127.0.0.1"
EOF
fi

# 2. Ensure Database Namespace exists
echo "Ensuring $DB_NS exists..."
kubectl create namespace $DB_NS --dry-run=client -o yaml | kubectl apply -f -

# 3. PostgreSQL Credentials
# We check for an existing secret so the password doesn't change on every run.
EXISTING_PASS=$(kubectl get secret -n $DB_NS pg-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 --decode || true)

if [ -z "$EXISTING_PASS" ]; then
  echo "Generating new PostgreSQL credentials..."
  PG_PASS=$(openssl rand -base64 12)
  kubectl create secret generic pg-secret -n $DB_NS --from-literal=password=$PG_PASS
else
  echo "Using existing credentials found in cluster."
  PG_PASS=$EXISTING_PASS
fi

# 4. Deploy PostgreSQL
echo "Deploying/Updating PostgreSQL ..."
helm repo add bitnami https://charts.bitnami.com/bitnami --force-update
helm repo update

helm upgrade --install my-db bitnami/postgresql \
  --namespace $DB_NS \
  --set global.postgresql.auth.password=$PG_PASS \
  --wait

# 5. Deploy http-echo
echo " Deploying http-echo app ..."
kubectl apply -f k8s/echo-app.yaml

echo "--------------------------------------------------"
echo "Setup Complete!"
echo "--------------------------------------------------"
echo "Access Echo App at: http://localhost:8989"
echo "Postgres Password:  $PG_PASS"
echo "--------------------------------------------------"
