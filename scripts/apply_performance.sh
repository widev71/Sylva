#!/bin/bash
# ── Witya Performance Optimizer ───────────────────────────────────
# Run: bash ~/.config/hypr/scripts/apply_performance.sh
# ──────────────────────────────────────────────────────────────────
# NOTE: intel_pstate (active mode) only supports 'performance' or 'powersave'.
#       We use 'powersave' + EPP 'balance_performance' for i3-1005G1:
#       - Still scales up quickly when needed
#       - Does NOT run at max freq when idle (unlike 'performance')

echo "🚀 Applying performance optimizations..."

# ── 1. Kernel sysctl tuning ──
sudo tee /etc/sysctl.d/99-performance.conf > /dev/null << 'SYSCTL'
# Lower swappiness: prefer RAM over swap (default 60 → 10)
vm.swappiness = 10

# Keep filesystem cache longer (default 100 → 50)
vm.vfs_cache_pressure = 50

# Reduce IO flush frequency (less CPU interrupts)
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
vm.dirty_writeback_centisecs = 1500
vm.dirty_expire_centisecs = 3000

# Higher file handle limits for Electron/Spotify/browser
fs.file-max = 2097152
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 1024

# Desktop scheduler responsiveness
kernel.sched_min_granularity_ns = 3000000
kernel.sched_wakeup_granularity_ns = 500000
SYSCTL

sudo sysctl --system > /dev/null 2>&1
echo "  ✅ Kernel sysctl applied"

# ── 2. CPU Governor → powersave + EPP balance_performance ──
# intel_pstate active mode only allows: performance | powersave
# EPP controls the actual scaling aggressiveness within powersave
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo powersave | sudo tee "$cpu" > /dev/null
done
for epp in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
    echo balance_performance | sudo tee "$epp" > /dev/null
done
echo "  ✅ CPU governor: powersave + EPP=balance_performance"

# ── 3. Power profile (skip - conflicts with manual governor/EPP above) ──
# powerprofilesctl overwrites our EPP settings, so we skip it
echo "  ℹ️  power-profiles-daemon: skipped (manual EPP is more precise)"

# ── 4. Intel iGPU - disable power gating ──
if [ -f /sys/class/drm/card1/device/power/control ]; then
    echo "on" | sudo tee /sys/class/drm/card1/device/power/control > /dev/null
    echo "  ✅ Intel GPU: always-on (no power gating)"
fi

# ── 5. Apply sysctl instantly (no reboot needed) ──
sudo sysctl vm.swappiness=10 > /dev/null
sudo sysctl vm.vfs_cache_pressure=50 > /dev/null
sudo sysctl fs.inotify.max_user_watches=524288 > /dev/null

# ── 6. Reload Hyprland for new env vars ──
hyprctl reload > /dev/null 2>&1 && echo "  ✅ Hyprland reloaded (GPU env vars active)"

echo ""
echo "✅ Done! Status:"
echo "  CPU governor  : $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"
echo "  CPU freq      : $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq | awk '{printf "%.0f MHz\n", $1/1000}')"
echo "  Power profile : $(powerprofilesctl get 2>/dev/null || echo 'N/A')"
echo "  Swappiness    : $(cat /proc/sys/vm/swappiness)"
echo "  Cache pressure: $(cat /proc/sys/vm/vfs_cache_pressure)"
