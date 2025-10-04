#!/bin/bash
# Terraform wrapper script for test environment
# 使用方法: ./tf.sh init|plan|apply|destroy

export AWS_PROFILE=test-account

case "$1" in
  init)
    terraform init -backend-config=backend.hcl "${@:2}"
    ;;
  plan)
    terraform plan -var-file=test.tfvars "${@:2}"
    ;;
  apply)
    terraform apply -var-file=test.tfvars "${@:2}"
    ;;
  destroy)
    terraform destroy -var-file=test.tfvars "${@:2}"
    ;;
  *)
    # 其他所有命令直接透传
    terraform "$@"
    ;;
esac

