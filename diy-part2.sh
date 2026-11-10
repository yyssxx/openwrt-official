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

# 2) 修改默认管理 IP：192.168.1.1 -> 192.168.31.1（AX3000T 既定地址，与 run 20/22 一致）
sed -i 's/192.168.1.1/192.168.31.1/g' package/base-files/files/bin/config_generate

# 3) 注意：lede 版 diy-part2 里给 filogic.mk 打的 factory.ubi 补丁不要带过来——
#    官方树的设备定义自带 ARTIFACTS/initramfs-factory.ubi，构建会原生出 factory.ubi。
