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
