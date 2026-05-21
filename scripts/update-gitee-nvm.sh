#!/usr/bin/env bash
set -euo pipefail

# 一键刷新 Gitee nvm 缓存。
# 使用前设置：
#   export GITEE_TOKEN="你的 Gitee 私人令牌"

OWNER="${GITEE_OWNER:-totongf}"
REPO="${GITEE_REPO:-nvm-fast}"
BRANCH="${GITEE_BRANCH:-master}"

if [ -z "${GITEE_TOKEN:-}" ]; then
    echo "错误：请先设置 GITEE_TOKEN"
    exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

echo "查询官方 nvm 最新版本..."
official_json="$tmp_dir/github-latest.json"
curl -fsSL "https://api.github.com/repos/nvm-sh/nvm/releases/latest" -o "$official_json"
nvm_tag="$(ruby -rjson -e 'puts JSON.parse(File.read(ARGV[0]))["tag_name"]' "$official_json")"

if [ -z "$nvm_tag" ]; then
    echo "错误：无法解析官方 nvm 最新版本"
    exit 1
fi

echo "官方最新版本：$nvm_tag"

download_cached_file() {
    local path="$1"
    local output="$2"
    local raw_url="https://raw.githubusercontent.com/nvm-sh/nvm/$nvm_tag/$path"
    local gitee_url="https://gitee.com/mirrors/nvm/raw/$nvm_tag/$path"

    if curl --connect-timeout 10 --max-time 60 -fsSL "$raw_url" -o "$output"; then
        return
    fi

    echo "GitHub raw 下载 $path 失败，回退到 Gitee mirror..."
    curl --connect-timeout 10 --max-time 60 -fsSL "$gitee_url" -o "$output"
}

echo "下载官方 nvm 文件..."
download_cached_file "nvm.sh" "$tmp_dir/nvm.sh"
download_cached_file "nvm-exec" "$tmp_dir/nvm-exec"
download_cached_file "bash_completion" "$tmp_dir/bash_completion"

mkdir -p "$tmp_dir/metadata"
cat > "$tmp_dir/metadata/nvm-latest.json" <<EOF
{
  "tag": "$nvm_tag",
  "nvm_sh": "https://gitee.com/$OWNER/$REPO/raw/$BRANCH/nvm.sh",
  "nvm_exec": "https://gitee.com/$OWNER/$REPO/raw/$BRANCH/nvm-exec",
  "bash_completion": "https://gitee.com/$OWNER/$REPO/raw/$BRANCH/bash_completion",
  "updated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

put_file() {
    local path="$1"
    local file="$2"
    local message="$3"
    local encoded status sha meta

    encoded="$(base64 < "$file" | tr -d '\n')"
    meta="$tmp_dir/meta-$(printf '%s' "$path" | tr '/.' '__').json"
    status="$(
        curl -sS -o "$meta" -w '%{http_code}' \
            "https://gitee.com/api/v5/repos/$OWNER/$REPO/contents/$path?access_token=$GITEE_TOKEN&ref=$BRANCH"
    )"

    if [ "$status" = "200" ]; then
        sha="$(ruby -rjson -e 'obj=JSON.parse(File.read(ARGV[0])); puts obj.is_a?(Hash) ? obj["sha"] : ""' "$meta")"
        if [ -n "$sha" ]; then
            curl -fsS -X PUT "https://gitee.com/api/v5/repos/$OWNER/$REPO/contents/$path" \
                --data-urlencode "access_token=$GITEE_TOKEN" \
                --data-urlencode "content=$encoded" \
                --data-urlencode "message=$message" \
                --data-urlencode "branch=$BRANCH" \
                --data-urlencode "sha=$sha" \
                >/dev/null
            return
        fi
    fi

    curl -fsS -X POST "https://gitee.com/api/v5/repos/$OWNER/$REPO/contents/$path" \
        --data-urlencode "access_token=$GITEE_TOKEN" \
        --data-urlencode "content=$encoded" \
        --data-urlencode "message=$message" \
        --data-urlencode "branch=$BRANCH" \
        >/dev/null
}

echo "更新 Gitee 缓存文件..."
put_file "nvm.sh" "$tmp_dir/nvm.sh" "更新 nvm.sh 到 $nvm_tag"
put_file "nvm-exec" "$tmp_dir/nvm-exec" "更新 nvm-exec 到 $nvm_tag"
put_file "bash_completion" "$tmp_dir/bash_completion" "更新 bash_completion 到 $nvm_tag"
put_file "metadata/nvm-latest.json" "$tmp_dir/metadata/nvm-latest.json" "更新 nvm 版本元数据到 $nvm_tag"

echo "完成：$OWNER/$REPO 已刷新到 $nvm_tag"
