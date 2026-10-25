---
title: 常用命令与测试方法
description: 下载、网络调试、远程连接、Linux 系统、客户端和硬件验证的常用命令与测试方法
---

# 常用命令与测试方法

<div class="section-lead">下载、网络调试、远程连接、Linux 系统、客户端和硬件验证的常用命令、测试步骤与操作路径。</div>

## 下载与文件校验

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
</dl>

## 网络测试与远程操作

### 使用 Clumsy 模拟弱网

测试前确认不会影响远程会话或其他关键连接。

1. 查询目标程序使用的 UDP 端口：

    ```bat
    netstat -ano -p udp
    ```

2. 根据 PID 在任务管理器中定位目标进程。
3. 在 [Clumsy](https://github.com/jagt/clumsy) 中设置过滤条件：

    ```text
    udp and (udp.SrcPort == <端口号> or udp.DstPort == <端口号>)
    ```

4. 配置延迟、丢包、乱序或限速并执行测试。

<dl class="knowledge-definitions knowledge-definitions--compact command-reference">
  <dt>SSH 远程操作</dt>
  <dd markdown>

<p><strong>SSH 连接</strong></p>

```bash
ssh <用户名>@<服务器地址>
```

<p><strong>SCP 文件传输</strong></p>

```bash
scp <本地文件路径> <用户名>@<服务器地址>:<远程目录>/
```

  </dd>
</dl>

## Linux 系统、服务与设备

<dl class="knowledge-definitions knowledge-definitions--compact command-reference">
  <dt>查看 USB/IP 连接状态</dt>
  <dd markdown>

```bash
sudo watch -n 1 -x usbip port
```

  </dd>
  <dt>实时查看内核日志</dt>
  <dd markdown>

```bash
sudo dmesg -T -w
```

  </dd>
  <dt>systemd 用户服务</dt>
  <dd markdown>

<p><strong>查询服务名</strong></p>

```bash
systemctl --user list-unit-files --type=service
```

<p><strong>重启服务</strong></p>

```bash
systemctl --user restart <服务名>.service
```

<p><strong>查看状态</strong></p>

```bash
systemctl --user status <服务名>.service
```

<p><strong>查看日志</strong></p>

```bash
journalctl --user -u <服务名>.service -f
```

  </dd>
  <dt>执行安装脚本</dt>
  <dd markdown>

```bash
chmod +x <脚本文件>.sh
./<脚本文件>.sh <软件包文件>.deb
```

  </dd>
  <dt>Debian/Ubuntu 软件包管理</dt>
  <dd markdown>

<p><strong>APT 安装本地包</strong></p>

```bash
sudo apt install ./<软件包文件>.deb
```

<p><strong>dpkg 安装</strong></p>

```bash
sudo dpkg -i <软件包文件>.deb
```

<p><strong>修复依赖</strong></p>

```bash
sudo apt install -f -y
```

<p><strong>卸载软件包</strong></p>

```bash
sudo dpkg -r <软件包名>
```

  </dd>
</dl>

## 客户端、显示与输入设备

<dl class="knowledge-definitions knowledge-definitions--compact command-reference">
  <dt>使用 GDB 调试客户端</dt>
  <dd markdown>

```bash
export DISPLAY=<X11显示地址>
export LD_LIBRARY_PATH="<动态库目录>${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
gdb ./<客户端程序>
```

进入 GDB 后执行：

```gdb
run
```

  </dd>
  <dt>X11 查看工具</dt>
  <dd markdown>

<p><strong>查看键盘和鼠标事件</strong></p>

```bash
DISPLAY=<X11显示地址> xev
```

<p><strong>查看显示器配置</strong></p>

```bash
DISPLAY=<X11显示地址> xrandr
```

  </dd>
</dl>

## 系统与硬件验证

<dl class="knowledge-definitions knowledge-definitions--compact command-reference">
  <dt>查看 NVIDIA 显卡实时占用</dt>
  <dd markdown>

```bat
nvidia-smi dmon
```

  </dd>
  <dt>Android：验证 Activity 状态恢复</dt>
  <dd>开发者选项 → 开启“不保留活动” → 执行目标场景 → 检查重建与状态恢复。</dd>
  <dt>Windows：拖动时显示窗口内容</dt>
  <dd>设置 → 关于 → 高级系统设置 → 高级 → 性能设置 → 勾选“拖动时显示窗口内容”。</dd>
  <dt>Windows：查看网卡连接持续时间</dt>
  <dd>网络连接 → 更改适配器选项 → 目标网卡 → 状态 → 查看持续时间。</dd>
</dl>
