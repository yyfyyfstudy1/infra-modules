variable "aws_region" {
  description = "AWS 区域"
  type        = string
  default     = "ap-southeast-2"
}

variable "aws_profile" {
  description = "AWS CLI Profile"
  type        = string
  default     = "dev-account"
}

variable "jenkins_role_arn" {
  description = "Dev 账户中 Jenkins 实例角色 ARN（可信主体）"
  type        = string
}

variable "role_name" {
  description = "要创建的部署角色名称"
  type        = string
  default     = "JenkinsDeployerRole"
}

variable "tags" {
  description = "额外标签"
  type        = map(string)
  default     = {}
}


