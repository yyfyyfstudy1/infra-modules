# GitOps Terraform 工作流配置指南

## 🎯 概述

这个 GitOps 工作流实现了企业级的 Terraform 部署流程：
1. **PR 创建** → 自动执行 `terraform plan` 并评论到 PR
2. **PR 合并** → 自动执行 `terraform apply` 部署资源
3. **完整的审计跟踪** → 所有变更都有记录

## 🔧 前置条件

### 1. Jenkins 插件安装

在 Jenkins 中安装以下插件：

```bash
# 必需插件
- GitHub Integration Plugin
- GitHub API Plugin  
- Credentials Binding Plugin
- HTTP Request Plugin

# 可选插件（推荐）
- AnsiColor Plugin
- Timestamper Plugin
```

### 2. GitHub Token 配置

#### 创建 GitHub Personal Access Token：

1. 进入 GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. 点击 "Generate new token (classic)"
3. 设置权限：
   - `repo` (完整仓库访问)
   - `public_repo` (如果是公开仓库)
4. 复制生成的 token

#### 在 Jenkins 中配置凭证：

1. 进入 Jenkins → Manage Jenkins → Credentials
2. 选择适当的域 (Global)
3. 点击 "Add Credentials"
4. 配置：
   - **Kind**: Secret text
   - **Secret**: 粘贴你的 GitHub token
   - **ID**: `github-token`
   - **Description**: `GitHub API Token for PR comments`

### 3. Jenkins 任务配置

#### 创建新的 Pipeline 任务：

1. **新建任务** → 输入名称：`terraform-gitops`
2. **选择类型**：Pipeline
3. **配置 Pipeline**：
   - Definition: Pipeline script from SCM
   - SCM: Git
   - Repository URL: `https://github.com/yyfyyfstudy1/infra-modules`
   - Script Path: `cicd/jenkins-pipelines/Jenkinsfile.gitops`

#### 配置构建触发器：

1. **GitHub hook trigger for GITScm polling** ✅
2. **Poll SCM** (备用): `H/5 * * * *`

## 🚀 工作流程

### 1. 开发流程

```bash
# 1. 创建功能分支
git checkout -b feature/add-new-resource

# 2. 修改 Terraform 代码
# 编辑 infra/envs/dev/main.tf 等文件

# 3. 提交并推送
git add .
git commit -m "Add new S3 bucket for testing"
git push origin feature/add-new-resource

# 4. 创建 Pull Request
# 在 GitHub 上创建 PR: feature/add-new-resource → main
```

### 2. 自动 Plan 阶段

当 PR 创建后：
1. **Jenkins 自动触发** → 检测到 PR
2. **执行 terraform plan** → 生成变更计划
3. **自动评论到 PR** → 显示详细的资源变更

**PR 评论示例：**
```markdown
## 🔍 Terraform Plan - DEV Environment

**构建信息：**
- 环境: `dev`
- 分支: `feature/add-new-resource`
- 提交: `a1b2c3d`

**计划摘要：**
```
Plan: 2 to add, 0 to change, 0 to destroy.

+ aws_s3_bucket.new_bucket
+ aws_s3_bucket_versioning.new_bucket
```

**下一步：**
- ✅ 如果计划正确，请合并此 PR
- 🔄 合并后将自动触发 `terraform apply`
```

### 3. 审批和合并

1. **团队成员 Review** → 检查 plan 结果
2. **确认无误** → 点击 "Approve"
3. **合并 PR** → 触发自动部署

### 4. 自动 Apply 阶段

PR 合并后：
1. **Jenkins 自动触发** → 检测到 main 分支更新
2. **执行 terraform apply** → 实际创建资源
3. **评论结果到原 PR** → 确认部署完成

## 📋 环境配置

### 开发环境 (dev)
- **自动触发**: PR 创建时
- **操作**: plan (评论到 PR)
- **部署**: PR 合并后自动 apply

### 测试环境 (test)
- **自动触发**: dev 环境部署成功后
- **操作**: plan → apply
- **审批**: 可选人工确认

### 生产环境 (prod)
- **自动触发**: test 环境验证通过后
- **操作**: plan → 人工审批 → apply
- **审批**: 强制人工确认

## 🔍 监控和审计

### 构建历史
- Jenkins 保留最近 10 次构建记录
- 每次构建都有详细日志和产物

### 变更跟踪
- 每个 PR 都有完整的 plan/apply 记录
- GitHub 评论提供变更摘要
- 构建日志包含详细执行信息

### 失败处理
- 构建失败时自动评论到 PR
- 包含错误信息和修复建议
- 支持重试机制

## 🛠️ 故障排除

### 常见问题

#### 1. GitHub 评论失败
```bash
# 检查 GitHub token 权限
# 确认 token 有 repo 权限
# 检查网络连接
```

#### 2. Terraform 权限问题
```bash
# 检查 AWS 角色配置
# 确认 AssumeRole 权限
# 验证环境变量
```

#### 3. 构建不触发
```bash
# 检查 GitHub Webhook 配置
# 确认 Jenkins 插件安装
# 验证仓库权限
```

### 调试命令

```bash
# 检查 Jenkins 日志
tail -f /var/log/jenkins/jenkins.log

# 测试 GitHub API 连接
curl -H "Authorization: token $GITHUB_TOKEN" \
     https://api.github.com/repos/yyfyyfstudy1/infra-modules

# 验证 Terraform 配置
terraform validate
```

## 📚 最佳实践

### 1. 分支策略
- `main` - 生产环境代码
- `develop` - 开发环境代码  
- `feature/*` - 功能分支
- `hotfix/*` - 紧急修复

### 2. 提交规范
```bash
# 使用清晰的提交信息
git commit -m "feat: add S3 bucket for user uploads"
git commit -m "fix: resolve Lambda timeout issue"
git commit -m "docs: update deployment guide"
```

### 3. PR 规范
- 提供清晰的 PR 描述
- 包含变更原因和影响范围
- 添加相关截图或文档链接

### 4. 安全考虑
- 定期轮换 GitHub token
- 使用最小权限原则
- 启用构建日志审计
- 设置敏感信息保护

## 🎉 总结

这个 GitOps 工作流提供了：
- ✅ **自动化** - 减少手动操作
- ✅ **安全性** - 强制代码审查
- ✅ **可追溯** - 完整的变更记录
- ✅ **协作性** - 团队透明沟通
- ✅ **可靠性** - 自动化测试和部署

通过这个流程，你的团队可以安全、高效地管理基础设施变更！
