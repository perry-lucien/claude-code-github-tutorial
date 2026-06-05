#!/bin/bash
# ==============================================
# Claude Code GitHub 连接 — 快速初始化脚本
# 用法: bash quick-start.sh
# ==============================================
set -e

echo "========================================="
echo " Claude Code × GitHub 快速初始化"
echo "========================================="
echo ""

# 1. 检查 Git
if ! command -v git &> /dev/null; then
    echo "❌ 未安装 Git，请先安装: https://git-scm.com/downloads"
    exit 1
fi
echo "✅ Git: $(git --version)"

# 2. 检查 GitHub CLI
if ! command -v gh &> /dev/null; then
    echo "❌ 未安装 GitHub CLI，请先安装: https://cli.github.com/"
    exit 1
fi
echo "✅ gh: $(gh --version | head -1)"

# 3. 检查登录状态
if gh auth status &> /dev/null; then
    echo "✅ GitHub CLI 已登录"
    echo "   账户: $(gh api user --jq '.login')"
else
    echo ""
    echo "⚠️  GitHub CLI 未登录，请选择登录方式:"
    echo ""
    echo "   [1] 使用 Token 登录（推荐，中国网络友好）"
    echo "   [2] 打开浏览器登录"
    echo ""
    read -p "   请选择 [1/2]: " choice
    case $choice in
        1)
            read -sp "   请输入你的 GitHub Token: " token
            echo
            echo "$token" | gh auth login --with-token
            ;;
        2)
            gh auth login
            ;;
        *)
            echo "❌ 无效选择"
            exit 1
            ;;
    esac
fi

# 4. 检查 SSH 连接
echo ""
echo "--- 测试 SSH 连接 ---"
if ssh -T git@github.com 2>&1 | grep -q "successfully"; then
    echo "✅ SSH 连接正常"
else
    echo ""
    echo "⚠️  SSH 连接异常，请检查密钥配置。"
    echo "   参考: ssh-keygen -t ed25519 -C 你的邮箱"
    echo "   并添加公钥到 https://github.com/settings/keys"
fi

# 5. 配置 Git 凭据
echo ""
echo "--- 配置 Git 凭据 ---"
gh auth setup-git 2>/dev/null || true
echo "✅ Git 凭据已配置"

# 6. 统计信息
echo ""
echo "========================================="
echo " 🎉 初始化完成！"
echo "========================================="
echo ""
echo "你的仓库列表:"
gh repo list --limit 10 --json name,visibility --jq '.[] | "  \(.name) (\(.visibility))"'
echo ""
echo "快速命令备忘:"
echo "  gh repo create 仓库名 --public --source=. --push  创建并推送"
echo "  gh repo list                                       列出仓库"
echo "  ssh -T git@github.com                              测试 SSH"
echo ""
