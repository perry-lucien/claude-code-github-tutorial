# 中国网络环境下连接 GitHub 优化指南

> 针对中国大陆用户，解决 GitHub 连接不稳定问题。

---

## 网络症状对照

| 现象 | 原因 | 解决方案 |
|------|------|----------|
| `git push` 显示 `Connection was reset` | HTTPS 被阻断 | 改用 SSH 协议 |
| 浏览器能打开 GitHub，命令行不行 | 代理环境变量未配置 | 设置 `http_proxy` / `https_proxy` |
| `gh auth login` 打开空白页 | OAuth 网页被墙 | 使用 Token 方式登录 |
| `git clone` 极慢 | 国内 CDN 连接差 | 使用镜像或 SSH |

---

## 解决方案

### 方案一：全程使用 SSH 协议（推荐）

```bash
# 1. 生成 SSH 密钥（如果还没有）
ssh-keygen -t ed25519 -C "your-email@example.com"

# 2. 添加公钥到 GitHub
cat ~/.ssh/id_ed25519.pub
# 复制输出，粘贴到: https://github.com/settings/keys

# 3. 全局配置 Git 始终使用 SSH
git config --global url."git@github.com:".insteadOf "https://github.com/"

# 4. 测试
ssh -T git@github.com
```

### 方案二：配置 Git 代理

```bash
# 如果你有代理工具（如 Clash、v2ray、SSR），设置环境变量：

# Windows (CMD)
set HTTP_PROXY=http://127.0.0.1:7890
set HTTPS_PROXY=http://127.0.0.1:7890

# Windows (PowerShell)
$env:HTTP_PROXY="http://127.0.0.1:7890"
$env:HTTPS_PROXY="http://127.0.0.1:7890"

# macOS / Linux
export HTTP_PROXY=http://127.0.0.1:7890
export HTTPS_PROXY=http://127.0.0.1:7890

# 为 Git 单独设置代理（不污染全局环境变量）
git config --global http.proxy http://127.0.0.1:7890
git config --global https.proxy http://127.0.0.1:7890

# 取消代理
git config --global --unset http.proxy
git config --global --unset https.proxy
```

### 方案三：使用镜像加速

```bash
# 使用镜像站克隆（仅限克隆，推送仍需 SSH 或原地址）
git clone https://github.com.cnpmjs.org/用户名/仓库名.git

# 或使用 fastgit 镜像
git clone https://hub.fastgit.xyz/用户名/仓库名.git
```

---

## 实际测试数据

在中国 Windows 11 网络环境下的实测结果：

| 协议 | gh repo create | git clone | git push | git fetch |
|------|:---:|:---:|:---:|:---:|
| HTTPS | ✅ 正常 | ❌ 超时 | ❌ 连接重置 | ❌ 连接重置 |
| SSH | N/A | ✅ 正常 | ✅ 正常 | ✅ 正常 |
| HTTPS + 代理 | ✅ 正常 | ✅ 正常 | ✅ 正常 | ✅ 正常 |

> **结论**：在中国网络环境下，**SSH 协议比 HTTPS 更稳定**。建议将 GitHub CLI 用于 API 操作（创建仓库、查询等），Git 推送使用 SSH。
