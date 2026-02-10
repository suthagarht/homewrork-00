# Local Kubernetes Platform Setup
We are going to set-up a simple environment using `kind`.

## Prerequisites

Before running the setup, ensure you have the following installed on your macOS (with Docker Desktop running):

* **Kind**: `brew install kind`
* **Kubectl**: `brew install kubectl`
* **Helm**: `brew install helm`

---

## Quick Start
Repository - https://github.com/suthagarht/homewrork-00

1.  **Clone the repository** and enter the project directory.
2.  **Make the script executable**:
    ```bash
    chmod +x setup.sh
    ```
3.  **Run the automated setup**:
    ```bash
    ./setup.sh
    ```
4.  **Verify the Application**:
    Once the script finishes, visit the custom application at:
     [http://localhost:8989](http://localhost:8989)

---

## Architecture & Decisions

### **1. Infrastructure (Kind)**
The cluster is provisioned via `kind`. To avoid the need for manual `kubectl port-forward` commands, the cluster configuration uses `extraPortMappings` to map host port **8989** directly to the Kubernetes **NodePort 30000**.
```bash
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30000
    hostPort: 8989
    listenAddress: "127.0.0.1"
```

### **2. Namespaces**
* **`apps` Namespace**: Contains the `http-echo` custom deployment.
* **`db-namespace`**: Contains the PostgreSQL Helm release.

### **3. Checks**
* **Cluster Check**: Only creates the cluster if it doesn't already exist.
* **Credential**: The script checks if a PostgreSQL password secret already exists. If found, it reuses it; otherwise, it generates a fresh secure string.
---

## Access the cluster
You can change context and access the cluster.
```bash
kubectl config use-context kind-take-home
```
---

## Production Recommendations

**What I would change for a production or customer-hosted deployment:**

1.  **Ingress & TLS**: Instead of using `NodePort`, I would deploy an **Ingress Controller** (like NGINX). This would allow for hostname-based routing (e.g., `app.example.com`) and automated SSL/TLS certificate management via **cert-manager**.

2.  **External Secrets**: For production, I would move away from generating passwords in scripts. I would use the **External Secrets Operator** to pull credentials securely from a managed vault (like HashiCorp Vault, AWS Secrets Manager)

3.  **Monitoring & Observability**: I would include a **Prometheus and Grafana** stack to monitor the health and performance of the workloads, utilizing the resource limits defined in the manifests to trigger alerts.
---

### **Cleanup**
To remove the environment entirely, simply run:
```bash
kind delete cluster --name take-home
```
