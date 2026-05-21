# nvm-fast

`nvm-fast` 是一个面向国内网络环境的 nvm + Node.js LTS 快速安装入口。

目标安装命令：

```sh
curl -LsSf https://gitee.com/totongf/nvm-fast/raw/master/install.sh | bash
```

安装脚本会：

- 从 Gitee 缓存下载 `nvm.sh`、`nvm-exec`、`bash_completion`
- 安装前对比 Gitee 缓存版本和官方最新版本，不一致时给出警告
- 设置 `NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node`
- 安装 Node.js LTS
- 设置 npm registry 为 `https://registry.npmmirror.com`
- 全局安装 `pnpm` 和 `yarn`

## 为什么需要 nvm-fast

当前 `安装脚本/nvm.sh` 已经使用了：

```text
https://gitee.com/mirrors/nvm.git
https://npmmirror.com/mirrors/node
https://registry.npmmirror.com
```

这个方向是对的，但仍有几个可改进点：

- `git fetch --tags` 依赖 git 网络链路，慢或失败时会影响安装。
- 只写 `~/.bashrc`，对 zsh 和通用 profile 不够友好。
- 没有版本缓存元数据，也没有版本落后告警。
- 没有在线自动刷新方案。

`nvm-fast` 改成无 git clone 安装，直接缓存 nvm 必需文件。

## 目录

```text
nvm-fast/
  install.sh
  scripts/
    update-gitee-nvm.sh
  github/
    .github/workflows/update-gitee-nvm.yml
  gitee/
    .workflow/update-gitee-nvm.yml
  docs/
```

## 手动刷新 Gitee 缓存

```sh
GITEE_TOKEN=你的令牌 bash scripts/update-gitee-nvm.sh
```

刷新后 Gitee 仓库会出现：

```text
nvm.sh
nvm-exec
bash_completion
metadata/nvm-latest.json
```

## GitHub Actions 自动刷新

把 `github/.github/workflows/update-gitee-nvm.yml` 放到 GitHub 仓库 `.github/workflows/update-gitee-nvm.yml`。

添加 Secret：

```text
GITEE_TOKEN=你的 Gitee 私人令牌
```

默认每天北京时间 `04:25` 自动刷新。

## Gitee Go 自动刷新

把 `gitee/.workflow/update-gitee-nvm.yml` 放到 Gitee 仓库 `.workflow/update-gitee-nvm.yml`。

添加私密变量：

```text
NVM_GITEE_TOKEN=你的 Gitee 私人令牌
```

## 常用验证

```sh
nvm --version
node -v
npm -v
pnpm -v
npm config get registry
```

## 安全

- 不要把令牌写进仓库文件。
- GitHub 使用 Secrets。
- Gitee Go 使用私密变量。
- 建议单独创建只用于 `nvm-fast` 的 Gitee 令牌。
