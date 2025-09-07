#!/bin/bash

# --- 配置 ---
# 定义 nvidia-patch 项目的根目录
NVIDIA_PATCH_DIR="/mnt/pool/system/patch/nvidia-patch"
# nvidia-patch 项目的 Git 仓库地址
GIT_REPO_URL="https://github.com/keylase/nvidia-patch.git"

# --- 脚本开始 ---

# 1. 检查核心工具: git
if ! command -v git &> /dev/null; then
    echo "错误：核心依赖 'git' 未安装，请先安装 git。"
    exit 1
fi

# 2. 准备 nvidia-patch 目录
# 检查目录是否存在
if [ ! -d "${NVIDIA_PATCH_DIR}" ]; then
    echo "目录 '${NVIDIA_PATCH_DIR}' 不存在，正在从 GitHub 克隆仓库..."
    # 使用 git clone 克隆项目
    git clone "${GIT_REPO_URL}" "${NVIDIA_PATCH_DIR}"
    if [ $? -ne 0 ]; then
        echo "错误：git clone 失败。请检查网络连接或仓库地址是否正确。"
        exit 1
    fi
else
    echo "目录 '${NVIDIA_PATCH_DIR}' 已存在。"
    # 检查它是否是一个有效的 git 仓库
    if [ ! -d "${NVIDIA_PATCH_DIR}/.git" ]; then
        echo "错误：'${NVIDIA_PATCH_DIR}' 存在但不是一个有效的 git 仓库。"
        exit 1
    fi
fi

# 3. 更新仓库并查找补丁
# 进入 nvidia-patch 目录
cd "${NVIDIA_PATCH_DIR}" || exit

# 保存当前所在的分支名称，以便最后切回来
ORIGINAL_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "当前所在分支: ${ORIGINAL_BRANCH}"

# 更新仓库，获取最新的分支和提交
echo "正在更新仓库 (git fetch)..."
git fetch --all
echo "正在拉取最新变更 (git pull)..."
git pull origin "${ORIGINAL_BRANCH}"

# 4. 检查 NVIDIA 驱动并执行补丁
# 检查 nvidia-smi 是否可用
if ! command -v nvidia-smi &> /dev/null; then
    echo "错误：'nvidia-smi' 命令不存在。"
    echo "请确保已正确安装 NVIDIA 驱动，并且 'nvidia-smi' 在您的 PATH 环境变量中。"
    # 切换回原来的分支
    git checkout "${ORIGINAL_BRANCH}" >/dev/null 2>&1
    exit 1
fi

# 获取本地安装的 NVIDIA 驱动版本号
LOCAL_DRIVER_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader)

if [ -z "$LOCAL_DRIVER_VERSION" ]; then
    echo "错误：无法获取本地 NVIDIA 驱动版本号。"
    # 切换回原来的分支
    git checkout "${ORIGINAL_BRANCH}" >/dev/null 2>&1
    exit 1
fi

echo "检测到本地 NVIDIA 驱动版本为: ${LOCAL_DRIVER_VERSION}"

# 开始在所有分支中寻找匹配的补丁
PATCH_FOUND=false
BRANCH_FOUND_IN=""

# 获取所有远程分支的列表，并移除 'origin/HEAD -> ...' 这一行
BRANCHES=$(git branch -r | grep -v 'HEAD')

# 首先检查当前分支
echo "正在检查当前分支 '${ORIGINAL_BRANCH}'..."
if grep -q "\[\"${LOCAL_DRIVER_VERSION}\"\]" patch.sh && grep -q "\[\"${LOCAL_DRIVER_VERSION}\"\]" patch-fbc.sh; then
    echo "在当前分支 '${ORIGINAL_BRANCH}' 中找到匹配的补丁。"
    PATCH_FOUND=true
    BRANCH_FOUND_IN="${ORIGINAL_BRANCH}"
else
    echo "在当前分支中未找到补丁，开始搜索其他所有分支..."
    for branch in $BRANCHES; do
        # 切换到远程分支的本地副本 (例如 origin/master -> master)
        local_branch_name=$(echo "$branch" | sed 's|origin/||')
        echo "正在检查分支 '${local_branch_name}'..."
        git checkout "${local_branch_name}" >/dev/null 2>&1
        
        # 在新分支下检查补丁是否存在
        if [ -f "patch.sh" ] && [ -f "patch-fbc.sh" ] && \
           grep -q "\[\"${LOCAL_DRIVER_VERSION}\"\]" patch.sh && \
           grep -q "\[\"${LOCAL_DRIVER_VERSION}\"\]" patch-fbc.sh; then
            echo "在分支 '${local_branch_name}' 中找到匹配的补丁！"
            PATCH_FOUND=true
            BRANCH_FOUND_IN="${local_branch_name}"
            break # 找到后退出循环
        fi
    done
fi

# 5. 应用补丁或报告失败
if [ "$PATCH_FOUND" = true ]; then
    echo "已在分支 '${BRANCH_FOUND_IN}' 中定位到补丁，开始应用..."
    
    echo "正在运行 patch.sh..."
    bash patch.sh

    echo "正在运行 patch-fbc.sh..."
    bash patch-fbc.sh

    echo "补丁应用完成。"
else
    echo "--------------------------------------------------------------------------"
    echo "错误：搜索了所有分支，仍未找到适用于您本地驱动 (${LOCAL_DRIVER_VERSION}) 的补丁。"
    echo "请考虑升级或降级您的 NVIDIA 驱动到一个受支持的版本。"
    echo "脚本已停止运行。"
    echo "--------------------------------------------------------------------------"
fi

# 6. 清理：无论成功与否，最后都切换回原来的分支
echo "操作完成，正在切换回 '${ORIGINAL_BRANCH}' 分支..."
git checkout "${ORIGINAL_BRANCH}" >/dev/null 2>&1

if [ "$PATCH_FOUND" = false ]; then
    exit 1
fi

exit 0
