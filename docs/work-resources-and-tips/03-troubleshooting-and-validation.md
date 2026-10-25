---
title: 排障与验证
description: 网络、Linux、客户端和硬件排障命令与路径
---

# 排障与验证

<div class="section-lead">网络、系统、客户端和硬件排障命令与操作路径。</div>

## 使用 Clumsy 模拟弱网

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

## Linux 常用排障

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
  <dt>systemd：查询服务名</dt>
  <dd markdown>

```bash
systemctl --user list-unit-files --type=service
```

  </dd>
  <dt>systemd：重启服务</dt>
  <dd markdown>

```bash
systemctl --user restart <服务名>.service
```

  </dd>
  <dt>systemd：查看状态</dt>
  <dd markdown>

```bash
systemctl --user status <服务名>.service
```

  </dd>
  <dt>systemd：查看日志</dt>
  <dd markdown>

```bash
journalctl --user -u <服务名>.service -f
```

  </dd>
</dl>

## 图形客户端与输入设备

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
  <dt>查看键盘和鼠标事件</dt>
  <dd markdown>

```bash
DISPLAY=<X11显示地址> xev
```

  </dd>
  <dt>查看显示器配置</dt>
  <dd markdown>

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
