#!/usr/bin/env bash
set -euo pipefail

# Gitee 上缓存的 nvm 文件与版本元数据。
GITEE_RAW_BASE="${NVM_FAST_GITEE_RAW_BASE:-https://gitee.com/totongf/nvm-fast/raw/master}"
NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
NODE_MIRROR="${NVM_NODEJS_ORG_MIRROR:-https://npmmirror.com/mirrors/node}"
NPM_REGISTRY="${NPM_CONFIG_REGISTRY:-https://registry.npmmirror.com}"

json_value() {
    local key="$1"
    sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" | head -n 1
}

warn_if_cache_outdated() {
    local cached_tag official_tag cached_json official_json
    cached_tag=""
    official_tag=""

    if cached_json="$(curl -fsSL "$GITEE_RAW_BASE/metadata/nvm-latest.json" 2>/dev/null)"; then
        cached_tag="$(printf '%s\n' "$cached_json" | json_value tag)"
    fi

    if official_json="$(curl -fsSL "https://api.github.com/repos/nvm-sh/nvm/releases/latest" 2>/dev/null)"; then
        official_tag="$(printf '%s\n' "$official_json" | json_value tag_name)"
    fi

    if [ -n "$cached_tag" ] && [ -n "$official_tag" ] && [ "$cached_tag" != "$official_tag" ]; then
        echo "警告：Gitee 缓存的 nvm 版本是 $cached_tag，官方最新版本是 $official_tag。"
        echo "      请执行刷新脚本更新 Gitee 缓存：bash scripts/update-gitee-nvm.sh"
    fi
}

download_nvm_files() {
    mkdir -p "$NVM_DIR"
    curl -fsSL "$GITEE_RAW_BASE/nvm.sh" -o "$NVM_DIR/nvm.sh"
    curl -fsSL "$GITEE_RAW_BASE/nvm-exec" -o "$NVM_DIR/nvm-exec"
    curl -fsSL "$GITEE_RAW_BASE/bash_completion" -o "$NVM_DIR/bash_completion"
    chmod +x "$NVM_DIR/nvm-exec"
}

append_managed_block() {
    local target_file="$1"
    local managed_block
    managed_block="$(cat <<EOF
# >>> nvm-fast managed block >>>
export NVM_DIR="\$HOME/.nvm"
export NVM_NODEJS_ORG_MIRROR="$NODE_MIRROR"
[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"
[ -s "\$NVM_DIR/bash_completion" ] && \. "\$NVM_DIR/bash_completion"
# <<< nvm-fast managed block <<<
EOF
)"

    mkdir -p "$(dirname "$target_file")"
    touch "$target_file"

    if grep -qF "# >>> nvm-fast managed block >>>" "$target_file"; then
        awk '
          BEGIN {skip=0}
          /^# >>> nvm-fast managed block >>>/ {skip=1; next}
          /^# <<< nvm-fast managed block <<</ {skip=0; next}
          !skip {print}
        ' "$target_file" > "$target_file.tmp"
        mv "$target_file.tmp" "$target_file"
    fi

    printf '\n%s\n' "$managed_block" >> "$target_file"
}

configure_profiles() {
    append_managed_block "$HOME/.profile"
    if [ -n "${SHELL:-}" ]; then
        case "${SHELL##*/}" in
            zsh) append_managed_block "$HOME/.zshrc" ;;
            bash) append_managed_block "$HOME/.bashrc" ;;
        esac
    fi
}

install_node_lts() {
    export NVM_DIR
    export NVM_NODEJS_ORG_MIRROR="$NODE_MIRROR"
    # shellcheck disable=SC1090
    . "$NVM_DIR/nvm.sh"
    nvm install --lts
    nvm alias default 'lts/*'
    npm config set registry "$NPM_REGISTRY"
    npm install -g pnpm yarn
}

echo "========================================="
echo " 安装 nvm + Node.js LTS（国内加速）"
echo "========================================="

warn_if_cache_outdated
download_nvm_files
configure_profiles
install_node_lts

echo
echo "========================================="
echo " 安装完成"
echo "nvm : $(nvm --version)"
echo "Node: $(node -v)"
echo "NPM : $(npm -v)"
echo "PNPM: $(pnpm -v)"
echo "重新打开 shell 或执行：source ~/.profile"
echo "========================================="
