#!/bin/bash
#
# diy-part1.sh（官方 OpenWrt 24.10 树专用）：feeds update 之前执行
#
# 与 lede 版的区别：lede 树自带 helloworld 源，官方树没有，必须自己加；
# passwall 两源与 lede 版 diy-part1 的决定相同，保留。

# helloworld：SSR Plus 本体。它现在自带全套小包（naiveproxy、chinadns-ng、
# dns2socks、dns2tcp、ipt2socks、redsocks2、microsocks、tcping、lua-neturl，
# 以及构建用的 gn、upx），不需要再从 immortalwrt 补包。
echo 'src-git helloworld https://github.com/fw876/helloworld.git' >> feeds.conf.default

# PassWall2（2026-11-06 Yu 决定与 SSR Plus 共存，沿用）
echo 'src-git passwall_packages https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git' >> feeds.conf.default
echo 'src-git passwall2 https://github.com/Openwrt-Passwall/openwrt-passwall2.git' >> feeds.conf.default

# coolsnowwolf/packages：只作 golang + xray-core 两个包的覆盖源
# （在 diy-part2 里用 feeds install -f 指定安装）。
# 官方源 xray-core 是素版（2026-11-09 拆 24.10.4 的 ipk 实证：二进制无 naive/cronet）；
# coolsnowwolf 版带 CONFIG_XRAY_CORE_NAIVE 开关（cronet），且其 xray 26.10.31
# 需要新版 golang，故 golang（coolsnowwolf 版 1.27）一并覆盖——lede 里的同款组合，d2 已验证。
# 整源追加在 feeds.conf 最后：install -a 阶段同名包以官方源优先，不扰动默认选择。
echo 'src-git cswpackages https://github.com/coolsnowwolf/packages.git' >> feeds.conf.default

# ledeapps：lede 独有的 LuCI 小应用，官方 luci 与四个源都没有，只能从
# coolsnowwolf/luci 的 openwrt-25.12 分支（lede 现行 feeds 用的分支）取。
# run 6 时是六个（arpbind、autoreboot、filetransfer、oui、rclone、vlmcsd 面板）；
# run 7 起按 Yu 2026-11-12 的取舍只留三个：autoreboot、filetransfer、luci-app-vlmcsd
# （砍 arpbind、oui、rclone——rclone 本体约 23MB，是 run 6 超重主因之一）。
# 以 src-link 本地源登记进 feeds.conf，让 feeds update/install 走正规流程：
# install 生成的符号链接指向克隆目录内的真实路径，这一点是成败关键——
# 这六个应用的 Makefile 都是相对引用 `include ../../luci.mk`，只有当应用的
# 物理路径是 <luci 仓库>/applications/<应用> 时，../../ 才正好落在仓库根的
# luci.mk 上。v2（自创 ledeapps 目录 cp -r）与 v3（cp -r 进 cswpackages）
# 两次失败都是死在这里：物理路径变了，luci.mk 找不到，Makefile 解析失败，
# 包在 defconfig 前就静默消失（run 4 / run 5 两炉 buildinfo 实证）。
# 稀疏克隆只取留下的三个应用 + build 目录（luci.mk 生成翻译时可能用到）；
# cone 模式下仓库根目录的文件（含 luci.mk）会自动带出。
git clone --depth 1 --filter=blob:none --sparse --branch openwrt-25.12 https://github.com/coolsnowwolf/luci.git /tmp/lede-luci
git -C /tmp/lede-luci sparse-checkout set applications/luci-app-autoreboot applications/luci-app-filetransfer applications/luci-app-vlmcsd build
# 硬校验：关键文件不在就当场判死这一步，别再让失败静默滑到 defconfig。
test -f /tmp/lede-luci/luci.mk || { echo "ERROR: /tmp/lede-luci/luci.mk 不存在，稀疏克隆不完整"; exit 1; }
for app in luci-app-autoreboot luci-app-filetransfer luci-app-vlmcsd; do
  test -f "/tmp/lede-luci/applications/$app/Makefile" || { echo "ERROR: $app 的 Makefile 不存在"; exit 1; }
done
echo 'src-link ledeapps /tmp/lede-luci' >> feeds.conf.default
