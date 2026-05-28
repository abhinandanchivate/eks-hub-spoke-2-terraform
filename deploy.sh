#!/usr/bin/env bash
# deploy.sh – Deploy Hub → Spoke1 → Spoke2 → Peering in order
# Usage: ./deploy.sh [plan|apply|destroy]
set -euo pipefail

ACTION="${1:-plan}"
REGION="${AWS_REGION:-ap-south-1}"

# Verify AWS credentials are set
if [[ -z "${AWS_ACCESS_KEY_ID:-}" || -z "${AWS_SECRET_ACCESS_KEY:-}" ]]; then
  echo "ERROR: AWS credentials not set."
  echo "Export AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and AWS_SESSION_TOKEN."
  exit 1
fi

run_tf() {
  local dir="$1"
  echo ""
  echo "========================================="
  echo " Terraform $ACTION → $dir"
  echo "========================================="
  cd "$dir"
  terraform init -upgrade -reconfigure
  if [[ "$ACTION" == "apply" ]]; then
    terraform apply -auto-approve
  elif [[ "$ACTION" == "destroy" ]]; then
    terraform destroy -auto-approve
  else
    terraform plan
  fi
  cd ..
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [[ "$ACTION" == "destroy" ]]; then
  # Destroy in reverse order
  run_tf peering
  run_tf spoke2
  run_tf spoke1
  run_tf hub
else
  run_tf hub
  run_tf spoke1
  run_tf spoke2
  run_tf peering
fi

echo ""
echo "✅ All stacks $ACTION complete."

# Update kubeconfigs after apply
if [[ "$ACTION" == "apply" ]]; then
  echo ""
  echo "Updating kubeconfigs..."
  HUB_CLUSTER=$(cd hub && terraform output -raw cluster_name)
  SPOKE1_CLUSTER=$(cd spoke1 && terraform output -raw cluster_name)
  SPOKE2_CLUSTER=$(cd spoke2 && terraform output -raw cluster_name)

  aws eks update-kubeconfig --region "$REGION" --name "$HUB_CLUSTER"   --alias hub
  aws eks update-kubeconfig --region "$REGION" --name "$SPOKE1_CLUSTER" --alias spoke1
  aws eks update-kubeconfig --region "$REGION" --name "$SPOKE2_CLUSTER" --alias spoke2

  echo ""
  echo "Clusters registered in kubeconfig:"
  echo "  kubectl config use-context hub"
  echo "  kubectl config use-context spoke1"
  echo "  kubectl config use-context spoke2"
fi
