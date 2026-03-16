---
description: How to safely deploy Kubernetes applications in the merchant repository using Helm
---

# Deploy Kubernetes Application Workflow

When requested to deploy or update the Merchant API application to a specific environment (`$ENV`), deploy using our strictly configured Helm setup. Do not use plain `kubectl apply`.

1.  Navigate to the repository origin directly containing the Helm Chart.
2.  Execute the `helm upgrade --install` command natively into the `$ENV` namespace.
3.  You **must** pass the environment-specific values file found inside `environments/` using the `-f` flag. This correctly toggles between CPU Autoscaling (lower environments) and Datadog external latency HPA (Production).
    ```bash
    helm upgrade --install merchant-core-api ./merchant-core-api-chart \
        -f ./merchant-core-api-chart/environments/$ENV.yaml \
        --namespace "$ENV" \
        --create-namespace
    ```
4.  Confirm rollout availability.
    ```bash
    kubectl rollout status deployment/merchant-core-api -n "$ENV"
    ```
