#!/bin/bash
#
# diy-part2.sh（官方 OpenWrt 24.10 树专用）：feeds install 之后、defconfig 之前执行

# 1) 把 golang + xray-core 换成 coolsnowwolf/packages 的版本。
#    教训（2026-11-10）：./scripts/feeds install -f -p 在本流程里实测无效——首跑
#    run 42725891719 的日志显示实际编译的是 feeds/packages 的官方 xray-core，
#    WSL 本地同样复现（-f 无声无息不换链接）。改用手动符号链接：先摘掉官方源的
#    同名链接，再把 csw 的链进 package/feeds/cswpackages/，与 feeds install 生成
#    的链接完全一致（WSL 已验证：defconfig 后 CONFIG_XRAY_CORE_NAIVE=y）。
#    验收标准不变：config.buildinfo 里 CONFIG_XRAY_CORE_NAIVE=y 必须在，
#    且 manifest 里 xray-core 应为 26.10.31。
rm -f package/feeds/packages/xray-core package/feeds/packages/golang
mkdir -p package/feeds/cswpackages
ln -sf ../../../feeds/cswpackages/net/xray-core package/feeds/cswpackages/xray-core
ln -sf ../../../feeds/cswpackages/lang/golang package/feeds/cswpackages/golang
# 1b) cswpackages 里还有两个包同样进不了 install -a 的账本（run 42780589138 的
#     buildinfo 里双双缺席），一并手动链接——种子里都选了：
#     vlmcsd（KMS 本体）、luci-app-iptv（藏在 pon/ 目录下，依赖 luci-base +
#     firewall4 + kmod-nft-bridge，官方树全有）。
ln -sf ../../../feeds/cswpackages/net/vlmcsd package/feeds/cswpackages/vlmcsd
ln -sf ../../../feeds/cswpackages/pon/luci-app-iptv package/feeds/cswpackages/luci-app-iptv

# 1c) lede 独有的六个 LuCI 小应用已改走 diy-part1 登记的 ledeapps 本地源
#     （src-link），feeds install 会把它们链进 package/feeds/ledeapps/，
#     这里不再做任何拷贝——v2/v3 在此处 cp -r 的两次失败教训见 diy-part1
#     里 ledeapps 段的注释（相对引用 ../../luci.mk 与物理路径的问题）。

# 2) 修改默认管理 IP：192.168.1.1 -> 192.168.31.1（AX3000T 既定地址，与 run 20/22 一致）
sed -i 's/192.168.1.1/192.168.31.1/g' package/base-files/files/bin/config_generate

# 3) 注意：lede 版 diy-part2 里给 filogic.mk 打的 factory.ubi 补丁不要带过来——
#    官方树的设备定义自带 ARTIFACTS/initramfs-factory.ubi，构建会原生出 factory.ubi。
