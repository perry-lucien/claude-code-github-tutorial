# Claude Code 连接 GitHub 完全教程

> 手把手教你让 Claude Code 操作你的 GitHub 仓库

---

## 目录

1. [前置准备](#1-前置准备)
2. [方案一：GitHub CLI（推荐）](#2-方案一github-cli推荐)
3. [方案二：Personal Access Token](#3-方案二personal-access-token)
4. [配置 SSH 密钥（中国网络推荐）](#4-配置-ssh-密钥中国网络推荐)
5. [实战：创建并推送一个仓库](#5-实战创建并推送一个仓库)
6. [实战：修改已有仓库的代码](#6-实战修改已有仓库的代码)
7. [实战：启用 GitHub Pages](#7-实战启用-github-pages)
8. [常见问题排错](#8-常见问题排错)
9. [总结 Cheat Sheet](#9-总结-cheat-sheet)

---

## 1. 前置准备

### 1.1 注册 GitHub 账号

访问 [github.com](https://github.com) 注册一个账号。已有账号请跳过此步。

### 1.2 安装 Git

```bash
# Windows - 下载安装 https://git-scm.com/download/win
# macOS
brew install git

# Ubuntu/Debian
sudo apt install git

# 配置基本信息
git config --global user.name "你的用户名"
git config --global user.email "你的邮箱@example.com"
```

### 1.3 验证 Git 安装

```bash
git --version
# 输出示例: git version 2.45.0
```

---

## 2. 方案一：GitHub CLI（推荐）

这是**最推荐**的方式，一行命令即可完成认证。

### 2.1 安装 GitHub CLI

```bash
# Windows - 下载安装 https://cli.github.com/ 或使用 winget
winget install --id GitHub.cli

# macOS
brew install gh

# Ubuntu/Debian
sudo apt install gh

# 验证安装
gh --version
# 输出示例: gh version 2.52.0
```

### 2.2 创建 Token

> 🔒 推荐使用 **Fine-grained PAT（细粒度令牌）**，可以精确控制权限范围，只给本次需要的仓库和操作授权。
> 相比之下，Classic Token 的 `repo` 作用域会放权给**你名下所有仓库**，风险较高。

#### 2.2.1 创建 Fine-grained PAT（推荐）

1. 打开 [Fine-grained tokens 设置页面](https://github.com/settings/tokens?type=beta)
2. 点击 **Generate new token**
3. 填写以下信息：

   | 字段 | 建议值 |
   |------|--------|
   | **Token name** | `claude-code` 或描述性名称 |
   | **Expiration** | 30~90 天（建议选 `Custom` 设定具体天数） |
   | **Description** | 可选，方便日后识别 |

4. **Repository access** → 选择 **Only select repositories**
   - 在弹出的搜索框中勾选 Claude Code 需要操作的仓库
   - > ⚠️ 如果涉及 `gh repo create` 新建仓库，需要临时选择 **All repositories**（因为仓库还没创建出来，无法预先勾选），用完后换回限制模式
5. **Permissions** → 设置精细权限：

   | 权限分类 | 权限级别 | 用途 |
   |---------|---------|------|
   | **Contents** | Read and write | 读写仓库代码（推送必备） |
   | **Metadata** | Read（自动勾选） | 读取仓库元数据（必选） |
   | **Pull requests** | Read and write | 管理 PR（按需） |
   | **Issues** | Read and write | 管理 Issue（按需） |
   | **Workflows** | Read and write | 推送 `.github/workflows/` 变更（按需） |

6. 点击 **Generate new token**
7. **立即复制 Token**（以 `github_pat_` 开头，关闭页面后无法再次查看）

#### 2.2.2 使用 Classic Token（备选，权限较高）

> 仅在国内网络 `gh auth login` 网页认证失败时使用。Classic Token 的 `repo` 作用域会访问**所有仓库**，建议用完后吊销。

```bash
# 打开 Token 设置页面
# https://github.com/settings/tokens

# GitHub CLI 的 gh auth login 在某些网络环境可能打不开网页
# 备选方案：使用 Classic Token 认证（虽然权限偏高但兼容性好）
```

1. 打开 [Classic Token 设置页面](https://github.com/settings/tokens)
2. 点击 **Generate new token** → **Generate new token (classic)**
3. 填写 Note（如 `claude-code-token`）
4. 勾选以下权限作用域：
   - `repo` —— 完全控制私有仓库（**必须**，注意这会给你**所有仓库**的完全权限）
   - `read:org` —— 读取组织信息（可选）
   - `workflow` —— 管理 GitHub Actions（按需）
5. 点击 **Generate token**
6. **立即复制并保存**（关闭后无法再次查看，以 `ghp_` 开头）

![Classic Token 权限选择示意](https://docs.github.com/assets/cb-34501/images/help/token/gh-token-repo-perms.png)

### 2.3 登录认证

Fine-grained PAT（`github_pat_`）和 Classic Token（`ghp_`）的认证方式一样：

```bash
# 使用 Token 登录（推荐，国内网络友好）
gh auth login --with-token < 你的Token文件路径
# 或手动输入
echo "你的_Token" | gh auth login --with-token

# 验证登录状态
gh auth status
# ✓ Logged in to github.com account your-username (GITHUB_TOKEN)
# ✓ Active account: true
# ✓ Git operations protocol: https
# ✓ Token: ghp_************************************ 或 github_pat_************
# ✓ Token scopes: 'repo'
```

### 2.4 配置 Git 凭据助手

```bash
gh auth setup-git
# 这会自动配置 git 使用 gh 作为凭据管理器
```

---

## 3. 方案二：直接使用 Token（不安装 gh）

如果你不想安装 GitHub CLI，也可以直接用 Token 操作 Git。

> ⚠️ 注意：Fine-grained PAT 和 Classic Token 都可用于此方案。
> Fine-grained PAT 以 `github_pat_` 开头，Classic Token 以 `ghp_` 开头。

### 3.1 环境变量方式

将 Token 设置为系统环境变量 `GITHUB_TOKEN`，这样 `gh`、Git、以及其他工具都能自动读取。

#### Windows（图形界面）

<details>
<summary>点击展开详细步骤</summary>

1. 按键盘 **Win** 键，搜索 **"环境变量"**
2. 选择 **"编辑系统环境变量"**
3. 在弹出的"系统属性"窗口中，点击右下角的 **"环境变量..."** 按钮
4. 在 **"用户变量"** 区域，点击 **"新建"**
5. 填写变量信息：
   - **变量名**：`GITHUB_TOKEN`
   - **变量值**：`github_pat_你的_超长_令牌_字符串`
6. 一路点击 **"确定"** 保存所有窗口
7. **重启你的终端或 VS Code**，否则新变量不会生效

> 💡 如果想验证是否设置成功，打开新终端执行：
> ```cmd
> echo %GITHUB_TOKEN%
> ```
> 如果能正常输出你的 Token，说明配置成功。

</details>

#### macOS

<details>
<summary>点击展开详细步骤</summary>

**方式一：通过 `.zshrc` 永久配置（推荐）**

```bash
# 1. 编辑 shell 配置文件
echo 'export GITHUB_TOKEN="github_pat_你的_超长_令牌_字符串"' >> ~/.zshrc

# 2. 重新加载配置
source ~/.zshrc

# 3. 验证
echo $GITHUB_TOKEN
```

**方式二：通过 `~/.config/.env` 统一管理环境变量**

```bash
# 1. 创建或编辑配置文件
echo 'export GITHUB_TOKEN="github_pat_你的_超长_令牌_字符串"' >> ~/.config/.env

# 2. 在 .zshrc 中加载
echo 'source ~/.config/.env' >> ~/.zshrc

# 3. 重新加载
source ~/.zshrc
```

> 💡 重启终端或执行 `source ~/.zshrc` 后，新变量才会生效。

</details>

#### Linux

<details>
<summary>点击展开详细步骤</summary>

**方式一：通过 `.bashrc` 永久配置（推荐）**

```bash
# 1. 编辑 shell 配置文件（根据你的 shell 选择）
echo 'export GITHUB_TOKEN="github_pat_你的_超长_令牌_字符串"' >> ~/.bashrc
# 如果使用 zsh
echo 'export GITHUB_TOKEN="github_pat_你的_超长_令牌_字符串"' >> ~/.zshrc

# 2. 重新加载配置
source ~/.bashrc  # 或 source ~/.zshrc

# 3. 验证
echo $GITHUB_TOKEN
```

**方式二：写入 `/etc/environment`（全局生效，需要 sudo）**

```bash
# 所有用户都能读取（谨慎使用）
echo 'GITHUB_TOKEN="github_pat_你的_超长_令牌_字符串"' | sudo tee -a /etc/environment

# 重启后生效
```

> 💡 重启终端或执行 `source` 后，新变量才会生效。

</details>

#### 临时设置（所有系统，仅当前会话有效）

```bash
# Windows (CMD)
set GITHUB_TOKEN=github_pat_你的Token

# Windows (PowerShell)
$env:GITHUB_TOKEN="github_pat_你的Token"

# macOS / Linux
export GITHUB_TOKEN="github_pat_你的Token"
```

### 3.2 Git 凭据方式

```bash
# 全局配置（Token 会被明文存储，注意安全）
git config --global credential.helper store

# 也可以使用 manager 模式（Windows 推荐，凭据加密存储）
git config --global credential.helper manager-core
```

### 3.3 Fine-grained PAT vs Classic Token 对比

| 对比项 | Fine-grained PAT | Classic Token |
|--------|:-:|:-:|
| 前缀 | `github_pat_` | `ghp_` |
| 权限粒度 | 分类级别精细控制 | 粗粒度作用域 |
| 仓库范围 | 可限制到特定仓库 | 全部仓库 |
| 过期时间 | 强制设置 | 可选 |
| 推荐程度 | ⭐ 推荐 | ⚠️ 备选 |

---

## 4. 配置 SSH 密钥（中国网络推荐）

> 🔥 **重要**：在中国大陆网络环境中，HTTPS 连接 GitHub 可能不稳定或被阻断。**强烈建议配置 SSH**，连接更稳定。

### 4.1 生成 SSH 密钥

```bash
# 使用 ed25519 算法（推荐，更安全更高效）
ssh-keygen -t ed25519 -C "你的邮箱@example.com"

# 或使用 RSA（兼容性更好）
ssh-keygen -t rsa -b 4096 -C "你的邮箱@example.com"
```

按提示操作：
- 默认路径 `~/.ssh/id_ed25519` 直接回车即可
- 可以设置 Passphrase（可选，建议设一个）

### 4.2 查看并添加公钥到 GitHub

```bash
# 查看公钥
cat ~/.ssh/id_ed25519.pub
# 输出类似: ssh-ed25519 AAAAC3... 你的邮箱@example.com
```

1. 打开 [GitHub SSH Keys 设置](https://github.com/settings/keys)
2. 点击 **New SSH Key**
3. Title 填 `Claude Code` 或任意名称
4. Key type 选择 **Authentication Key**
5. 将上面 `cat` 命令输出的公钥粘贴进去
6. 点击 **Add SSH Key**

### 4.3 测试 SSH 连接

```bash
ssh -T git@github.com
# 成功输出: Hi your-username! You've successfully authenticated, but GitHub does not provide shell access.
```

### 4.4 让 Git 使用 SSH 协议

```bash
# 方式一：克隆时使用 SSH URL
git clone git@github.com:用户名/仓库名.git

# 方式二：修改已有仓库的远程地址
git remote set-url origin git@github.com:用户名/仓库名.git

# 方式三：配置全局替换（所有 HTTPS 自动转 SSH）
git config --global url."git@github.com:".insteadOf "https://github.com/"
```

---

## 5. 实战：创建并推送一个仓库

以下是完整的操作流程，从零开始创建一个仓库并推送到 GitHub。

### 5.1 创建本地项目

```bash
# 创建项目目录
mkdir my-project
cd my-project

# 初始化 Git
git init

# 创建一些文件
echo "# My Project" > README.md
echo "console.log('Hello GitHub!');" > index.js

# 提交
git add -A
git commit -m "Initial commit"
```

### 5.2 创建远程仓库并推送

```bash
# 使用 gh 一键创建仓库并推送（最方便）
gh repo create my-project --public --source=. --remote=origin --push

# 参数说明：
#   --public    创建公开仓库（也可用 --private）
#   --source=.  使用当前目录作为本地源
#   --remote    自动添加名为 origin 的远程
#   --push      创建后自动推送
```

### 5.3 分步操作（如果你想手动控制）

```bash
# 1. 仅创建远程仓库（空仓库）
gh repo create my-project --public

# 2. 添加远程
git remote add origin git@github.com:用户名/my-project.git

# 3. 推送
git push -u origin main
```

### 5.4 验证

```bash
# 查看远程仓库信息
gh repo view 用户名/my-project --json name,url,createdAt
```

---

## 6. 实战：修改已有仓库的代码

### 6.1 克隆已有仓库

```bash
# SSH 方式（推荐）
git clone git@github.com:用户名/仓库名.git
cd 仓库名

# HTTPS 方式
git clone https://github.com/用户名/仓库名.git
```

### 6.2 修改 → 提交 → 推送

```bash
# 修改文件
echo "新内容" >> README.md

# 添加并提交
git add -A
git commit -m "feat: 更新 README"

# 推送
git push origin main
```

### 6.3 在 Claude Code 中操作

在 Claude Code 会话中，可以直接对它说：

> "帮我修改 README.md，增加使用说明"
> "提交并推送到 GitHub"

它会自动执行 `git add`、`git commit`、`git push`。

---

## 7. 实战：启用 GitHub Pages

想要让项目变成一个可访问的网页？GitHub Pages 可以免费托管静态网站。

### 7.1 准备网页文件

在仓库根目录创建 `index.html`：

```html
<!DOCTYPE html>
<html>
<head><title>我的页面</title></head>
<body>
  <h1>Hello, GitHub Pages!</h1>
</body>
</html>
```

### 7.2 通过 gh 启用 Pages

```bash
# 方式一：使用 GitHub API
echo '{"source":{"branch":"main","path":"/"}}' | \
  gh api repos/用户名/仓库名/pages --input -

# 方式二：在网页端设置
# 仓库 → Settings → Pages → 选择 main 分支 → Save
```

### 7.3 访问页面

```
https://用户名.github.io/仓库名/
```

部署通常需要 **1-2 分钟**，可以用以下命令检查状态：

```bash
gh api repos/用户名/仓库名/pages --jq '.status'
# building → deployed
```

### 7.4 在 README 中添加链接

```markdown
🌐 **在线演示**: [https://用户名.github.io/仓库名/](https://用户名.github.io/仓库名/)
```

---

## 8. 常见问题排错

### ❌ 问题：`Recv failure: Connection was reset`

**原因**：在中国大陆网络环境中，HTTPS 连接 GitHub 被阻断。

**解决**：
```bash
# 切换到 SSH 协议
git remote set-url origin git@github.com:用户名/仓库名.git
git push origin main
```

### ❌ 问题：`gh auth login` 打开网页后无法认证

**原因**：认证页面被网络拦截。

**解决**：使用 Token 方式登录
```bash
gh auth login --with-token < token.txt
```

### ❌ 问题：`Missing required token scopes: 'read:org'`

**原因**：Token 缺少组织读取权限。

**解决**：
```bash
# 刷新 Token 补充权限
gh auth refresh -h github.com --scopes "repo,read:org"

# 或去 GitHub 设置页面重新生成 Token
```

### ❌ 问题：`Permission denied (publickey)`

**原因**：SSH 密钥未正确配置。

**解决**：
```bash
# 1. 确认密钥存在
ls -la ~/.ssh/

# 2. 确认公钥已添加到 GitHub
cat ~/.ssh/id_ed25519.pub

# 3. 测试连接
ssh -T git@github.com

# 4. 如果仍有问题，指定密钥连接
ssh -i ~/.ssh/id_ed25519 -T git@github.com
```

### ❌ 问题：`gh repo create 报错`

**原因**：仓库名已存在或 API 限流。

**解决**：
```bash
# 检查是否已有同名仓库
gh repo list --json name

# 换个名字再试，或用 --private
gh repo create my-project-new-name --private --source=. --push
```

### ❌ 问题：`refusing to merge unrelated histories`

**原因**：本地和远程有无关的提交历史。

**解决**：
```bash
git pull origin main --allow-unrelated-histories
# 解决冲突后
git push origin main
```

---

## 9. 总结 Cheat Sheet

```bash
# ===== 认证相关 =====
gh auth status                          # 查看登录状态
gh auth login --with-token < token.txt  # Token 登录（支持 fine-grained 和 classic）
gh auth setup-git                       # 配置 Git 凭据
ssh -T git@github.com                   # 测试 SSH 连接

# ===== Token 管理（网页端） =====
# Fine-grained PAT: https://github.com/settings/tokens?type=beta
# Classic Token:    https://github.com/settings/tokens

# ===== 仓库操作 =====
gh repo create 仓库名 --public --source=. --push
gh repo list --limit 50                 # 列出仓库
gh repo view 用户名/仓库名               # 查看仓库详情

# ===== Git 操作 =====
git init                                # 初始化仓库
git add -A                              # 暂存所有文件
git commit -m "message"                 # 提交
git push origin main                    # 推送到远程
git remote set-url origin SSH地址       # 切换到 SSH 协议

# ===== GitHub Pages =====
echo '{"source":{"branch":"main","path":"/"}}' | \
  gh api repos/用户名/仓库名/pages --input -
gh api repos/用户名/仓库名/pages --jq '.status'

# ===== 有用的 API 查询 =====
gh api repos/用户名/仓库名 --jq '.description'
gh api repos/用户名/仓库名/readme --jq '.content' | base64 -d
```

---

> 📖 **关于本教程**
>
> 本教程由 [Claude Code](https://claude.ai) 自动生成，基于在 Windows 11 + 中国网络环境下的实际测试经验编写。
>
> 教程仓库: [https://github.com/perry-lucien/claude-code-github-tutorial](https://github.com/perry-lucien/claude-code-github-tutorial)
