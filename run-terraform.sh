#!/usr/bin/env bash
set -euo pipefail

cd terraform
terraform init
terraform apply -auto-approve