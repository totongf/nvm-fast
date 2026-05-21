# nvm-fast 文档

## 快速开始

```sh
curl -LsSf https://gitee.com/totongf/nvm-fast/raw/master/install.sh | bash
```

安装完成后重新打开终端，或执行：

```sh
source ~/.profile
```

验证：

```sh
nvm --version
node -v
npm -v
pnpm -v
npm config get registry
```

## 架构

```text
GitHub Actions / Gitee Go / 本机脚本
  -> scripts/update-gitee-nvm.sh
  -> 查询 nvm-sh/nvm 最新 release
  -> 下载 nvm.sh、nvm-exec、bash_completion
  -> 写回 Gitee nvm-fast
  -> 国内机器通过 Gitee raw 安装
```

## 安装脚本行为

`install.sh` 会：

1. 从 Gitee raw 下载 nvm 缓存文件。
2. 写入 `~/.nvm`。
3. 写入 profile 受管块。
4. 加载 nvm。
5. 通过 npmmirror 安装 Node.js LTS。
6. 设置 npm registry。
7. 全局安装 `pnpm` 和 `yarn`。

受管块：

```sh
# >>> nvm-fast managed block >>>
export NVM_DIR="$HOME/.nvm"
export NVM_NODEJS_ORG_MIRROR="https://npmmirror.com/mirrors/node"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
# <<< nvm-fast managed block <<<
```

## 环境变量

覆盖 Gitee raw 地址：

```sh
NVM_FAST_GITEE_RAW_BASE=https://gitee.com/yourname/nvm-fast/raw/master \
  bash -c "$(curl -LsSf https://gitee.com/yourname/nvm-fast/raw/master/install.sh)"
```

覆盖 Node 镜像：

```sh
NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node \
  bash -c "$(curl -LsSf https://gitee.com/totongf/nvm-fast/raw/master/install.sh)"
```

覆盖 npm registry：

```sh
NPM_CONFIG_REGISTRY=https://registry.npmmirror.com \
  bash -c "$(curl -LsSf https://gitee.com/totongf/nvm-fast/raw/master/install.sh)"
```

## 自动更新

推荐使用 GitHub Actions：

```text
github/.github/workflows/update-gitee-nvm.yml
```

需要 Secret：

```text
GITEE_TOKEN
```

也可以使用 Gitee Go：

```text
gitee/.workflow/update-gitee-nvm.yml
```

需要私密变量：

```text
NVM_GITEE_TOKEN
```

## 手动刷新

```sh
GITEE_TOKEN=你的令牌 bash scripts/update-gitee-nvm.sh
```

## 故障排查

检查 Gitee 缓存：

```sh
curl -fsSL https://gitee.com/totongf/nvm-fast/raw/master/metadata/nvm-latest.json
curl -I https://gitee.com/totongf/nvm-fast/raw/master/nvm.sh
```

检查官方版本：

```sh
curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest | ruby -rjson -e 'puts JSON.parse(STDIN.read)["tag_name"]'
```

检查 Node 镜像：

```sh
curl -I https://npmmirror.com/mirrors/node/
```

如果 `nvm` 命令不存在：

```sh
source ~/.profile
```

如果仍不存在：

```sh
ls -l ~/.nvm/nvm.sh ~/.nvm/nvm-exec ~/.nvm/bash_completion
```
