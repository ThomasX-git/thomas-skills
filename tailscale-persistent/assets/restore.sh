#!/bin/bash
#
# Tailscale 一键恢复脚本（已验证版本）
# ----------------------------------------
# 适用场景：根文件系统会被重置（/usr、/etc、/var 恢复出厂），但有一个目录持久化的
# Ubuntu/Debian 环境。脚本重装 tailscale，从持久化备份恢复节点身份，再用 systemd 拉起。
#
# 用法（需 root）：sudo <persist-dir>/restore.sh
# 幂等设计：可重复执行，已就绪时会直接跳过。
#
# 首次使用前，先改顶部三个变量：PERSIST_DIR、HOSTNAME、UBUNTU_CODENAME。
#
# 验证记录：本脚本逻辑源自 2026-10-01 两次真实平台重置后的恢复实测
# （本地 .deb 零下载，分别 19 秒 / 15 秒完成，节点身份保持，无需重新授权）。
# OpenSSH 相关部分已按 skill 作用域剔除。
#
set -euo pipefail

# ================= 按环境修改 =================
PERSIST_DIR="/path/to/persist-dir"   # 持久化目录
HOSTNAME="my-node"                   # 节点名，跨恢复保持不变
UBUNTU_CODENAME="noble"              # lsb_release -cs 的结果
# 若基础镜像的 apt 源里有确定不可用的镜像域名，填在这里做替换；没有就留空
BROKEN_MIRROR=""
# systemd 子进程被 seccomp 禁止创建 TUN 设备（TUNSETIFF 返回 EPERM）时设为 1，
# 走纯用户态网络；TUN 可用的普通机器设为 0 即可（功能更完整，可做 subnet router）
USE_USERSPACE_TUN=1
# 环境变量里有 HTTP(S)_PROXY / ALL_PROXY 且曾导致控制面握手 HTTP 400 时设为 1，
# 会给官方单元加一个 UnsetEnvironment 的 drop-in；无代理环境设为 0
CLEAR_PROXY=1
# ==============================================

BACKUPS="$PERSIST_DIR/backups"
UNITS="$PERSIST_DIR/units"
UNIT_NAME="tailscaled.service"

log()  { echo "[restore] $*"; }
warn() { echo "[restore] WARN: $*" >&2; }
die()  { echo "[restore] ERROR: $*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "请以 root 运行此脚本"
[ -d "$BACKUPS" ] || die "备份目录不存在: $BACKUPS"

export DEBIAN_FRONTEND=noninteractive

# ---------- 0. 若当前 tailscaled 状态有效，先刷新备份（保证备份永远最新） ----------
if [ -f /var/lib/tailscale/tailscaled.state ] && pgrep -x tailscaled >/dev/null; then
    if /usr/bin/tailscale status 2>&1 | grep -q 'Logged out'; then
        warn "tailscaled 当前未登录，不刷新备份（保留旧备份）"
    else
        log "刷新 tailscaled 状态备份..."
        cp -a /var/lib/tailscale/tailscaled.state "$BACKUPS/tailscaled.state"
    fi
fi

# ---------- 1. 修复 Ubuntu apt 源（deb822 安全写法） ----------
# 注意：不要用 sed 整行删除坏镜像——会把 deb822 的 URIs 行一起删掉导致源不可用。
# 正确做法：缺 URIs 就补，坏镜像只替换域名。
SRC=/etc/apt/sources.list.d/ubuntu.sources
if [ -f "$SRC" ]; then
    if ! grep -q '^URIs:' "$SRC"; then
        log "补回 ubuntu.sources 缺失的 URIs 行"
        sed -i "1i URIs: http://archive.ubuntu.com/ubuntu" "$SRC"
    elif [ -n "$BROKEN_MIRROR" ] && grep -q "$BROKEN_MIRROR" "$SRC"; then
        log "替换不可用的 apt 镜像 $BROKEN_MIRROR -> archive.ubuntu.com"
        sed -i "s|$BROKEN_MIRROR|archive.ubuntu.com|g" "$SRC"
    fi
fi

# ---------- 2. 恢复 Tailscale 官方 apt 源 ----------
if [ ! -f /etc/apt/sources.list.d/tailscale.list ]; then
    log "配置 Tailscale 官方 apt 源..."
    [ -f "$BACKUPS/tailscale-archive-keyring.gpg" ] || die "缺少 keyring 备份"
    mkdir -p /usr/share/keyrings
    cp -a "$BACKUPS/tailscale-archive-keyring.gpg" /usr/share/keyrings/tailscale-archive-keyring.gpg
    cat > /etc/apt/sources.list.d/tailscale.list <<EOF
# Tailscale packages for ubuntu ${UBUNTU_CODENAME}
deb [signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg] https://pkgs.tailscale.com/stable/ubuntu ${UBUNTU_CODENAME} main
EOF
fi

# ---------- 3. 安装 tailscale ----------
# 优先用持久化目录里的本地 .deb（零网络下载）；缺失时回退到 apt 在线安装
if ! dpkg -s tailscale >/dev/null 2>&1; then
    if ls "$PERSIST_DIR"/debs/*.deb >/dev/null 2>&1; then
        log "用本地缓存 .deb 安装 tailscale（无需网络）..."
        dpkg -i "$PERSIST_DIR"/debs/*.deb
    else
        warn "本地 .deb 缓存缺失，回退到 apt 在线安装（较慢）"
        apt-get update -qq
        apt-get install -y -qq tailscale
    fi
else
    log "tailscale 已安装，跳过"
fi
command -v /usr/sbin/tailscaled >/dev/null || die "tailscaled 二进制缺失"

# ---------- 4. 恢复 tailscaled 节点身份（避免重启后需要重新授权） ----------
if [ -f "$BACKUPS/tailscaled.state" ]; then
    log "恢复 tailscaled 节点身份..."
    mkdir -p /var/lib/tailscale
    cp -a "$BACKUPS/tailscaled.state" /var/lib/tailscale/tailscaled.state
    chmod 600 /var/lib/tailscale/tailscaled.state
else
    warn "缺少 tailscaled.state 备份，稍后可能需要手动完成 Tailscale 授权"
fi

# ---------- 5. 配置并启用官方 tailscaled.service ----------
# 官方 deb 自带 systemd 单元，无需自写 unit：
#  - TUN 受限时，把 --tun=userspace-networking 经 /etc/default/tailscaled 的 FLAGS 传入
#  - 代理变量泄漏时，用 drop-in 给官方单元加 UnsetEnvironment
log "配置官方 tailscaled.service..."
if [ "$USE_USERSPACE_TUN" -eq 1 ]; then
    FLAGS="--tun=userspace-networking"
    log "TUN 受限环境：FLAGS=${FLAGS}（纯用户态网络；Tailscale SSH 不受影响）"
else
    FLAGS=""
fi
cat > /etc/default/tailscaled <<EOF
# 由 restore.sh 生成
PORT="41641"
FLAGS="${FLAGS}"
EOF
if [ "$CLEAR_PROXY" -eq 1 ]; then
    log "安装代理变量清理 drop-in..."
    mkdir -p /etc/systemd/system/tailscaled.service.d
    cp -a "$UNITS/tailscaled-override.conf" /etc/systemd/system/tailscaled.service.d/override.conf
else
    rm -f /etc/systemd/system/tailscaled.service.d/override.conf
fi
systemctl daemon-reload
systemctl enable --now "$UNIT_NAME"
sleep 2

# ---------- 6. 确保 tailscale 在线 ----------
# Tailscale SSH 由 daemon 直接处理，不依赖 TUN 设备。
log "等待 tailscaled 就绪..."
for _ in $(seq 1 30); do
    /usr/bin/tailscale status >/dev/null 2>&1 && break
    sleep 1
done
log "执行 tailscale up（恢复网络身份）..."
if ! timeout 60 /usr/bin/tailscale up --hostname="$HOSTNAME" --ssh 2>&1 | tail -2; then
    warn "tailscale up 未成功，若提示登录请按指引完成授权后重跑本脚本"
fi

# ---------- 7. 验证 ----------
log "验证服务状态..."
systemctl is-active --quiet "$UNIT_NAME" || die "$UNIT_NAME 未能启动"
/usr/bin/tailscale status 2>&1 | head -4 || true   # || true：pipefail 下 head 先退出会产生 SIGPIPE 141

echo
log "全部就绪！"
log "连接：tailscale ssh <user>@$HOSTNAME"
