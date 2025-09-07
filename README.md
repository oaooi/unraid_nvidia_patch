# unraid_nvidia_patch
A simple script to auto apply NVENC and NvFBC patch on unraid

-----

# NVIDIA Patcher 自动化脚本

这是一个用于自动为 NVIDIA Linux 驱动打补丁的脚本，主要目的是解除消费级显卡（GeForce, Quadro）的 NVENC 并发编码会话数量限制。

脚本整合了 `nvidia-patch` 项目的核心功能，并在此基础上实现了完全自动化，简化了整个流程。

## 主要功能

  * **一键式操作**: 只需运行一个脚本，即可完成所有操作。
  * **自动准备**: 如果指定的 `nvidia-patch` 目录不存在，脚本会自动从 GitHub 克隆项目。
  * **自动更新**: 每次运行脚本时，都会自动执行 `git pull` 来获取最新的补丁，确保您使用的是社区最新版本。
  * **本地驱动优先**: 脚本会通过 `nvidia-smi` 自动检测您系统中当前安装的驱动版本，并以此为准进行匹配，避免了网络问题和版本不兼容的风险。
  * **全分支智能搜索**: 如果在默认分支中找不到与您驱动版本匹配的补丁，脚本会自动遍历 `nvidia-patch` 仓库的所有分支进行搜索，大大提高了成功率。
  * **安全可靠**: 在执行任何操作前，脚本会检查 `git` 和 `nvidia-smi` 等核心依赖是否存在。操作结束后，会自动切回原来的 Git 分支，不影响您的工作区。

## 依赖组件

在运行此脚本之前，请确保您的系统已安装以下组件：

  * `git`: 用于克隆和更新 `nvidia-patch` 仓库。
  * `bash`: 脚本的运行环境。
  * `nvidia-smi`: 用于检测本地驱动版本，通常在安装 NVIDIA 官方驱动后会自动安装。

## 如何使用

1.  **下载脚本**
    将我们编写好的脚本文件保存到您的系统中，例如命名为 `autonvpatch.sh`。

2.  **配置脚本**
    用文本编辑器打开脚本文件，根据您的实际情况修改脚本头部的两个配置变量：

    ```bash
    # --- 配置 ---
    # 定义 nvidia-patch 项目的根目录
    NVIDIA_PATCH_DIR="/mnt/pool/system/patch/nvidia-patch"
    # nvidia-patch 项目的 Git 仓库地址 (一般无需修改)
    GIT_REPO_URL="https://github.com/keylase/nvidia-patch.git"
    ```

    您需要将 `NVIDIA_PATCH_DIR` 的值修改为您希望存放 `nvidia-patch` 项目的路径。

3.  **授予执行权限**
    在终端中，给脚本文件添加可执行权限：

    ```bash
    chmod +x autonvpatch.sh
    ```

4.  **运行脚本**
    由于修改 NVIDIA 驱动文件需要管理员权限，请使用 `sudo` 来运行此脚本：

    ```bash
    sudo ./autonvpatch.sh
    ```

之后，脚本将自动完成所有检查、更新和打补丁的工作。您只需根据终端的输出信息，确认操作是否成功即可。
