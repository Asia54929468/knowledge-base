---
title: 技巧与指令
description: 下载、远程连接和软件包处理等常用命令
---

# 技巧与指令

<div class="section-lead">下载、远程连接和软件包处理命令，参数均使用占位符。</div>

## 下载与远程操作

<dl class="knowledge-definitions knowledge-definitions--compact command-reference">
  <dt>GitHub 下载加速</dt>
  <dd markdown>

```bash
curl -L -O "https://ghfast.top/<GitHub 安装包下载链接>"
```

  </dd>
  <dt>Windows：校验文件哈希值</dt>
  <dd markdown>

```bat
certutil -hashfile <文件路径> SHA256
```

  </dd>
  <dt>SSH 连接</dt>
  <dd markdown>

```bash
ssh <用户名>@<服务器地址>
```

  </dd>
  <dt>SCP 文件传输</dt>
  <dd markdown>

```bash
scp <本地文件路径> <用户名>@<服务器地址>:<远程目录>/
```

  </dd>
</dl>

## 脚本与软件包处理

<dl class="knowledge-definitions knowledge-definitions--compact command-reference">
  <dt>执行安装脚本</dt>
  <dd markdown>

```bash
chmod +x <脚本文件>.sh
./<脚本文件>.sh <软件包文件>.deb
```

  </dd>
  <dt>APT 安装本地包</dt>
  <dd markdown>

```bash
sudo apt install ./<软件包文件>.deb
```

  </dd>
  <dt>dpkg 安装</dt>
  <dd markdown>

```bash
sudo dpkg -i <软件包文件>.deb
```

  </dd>
  <dt>修复依赖</dt>
  <dd markdown>

```bash
sudo apt install -f -y
```

  </dd>
  <dt>卸载软件包</dt>
  <dd markdown>

```bash
sudo dpkg -r <软件包名>
```

  </dd>
</dl>
