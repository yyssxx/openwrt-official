#!/bin/bash
#
# diy-part2.sh（官方 OpenWrt 24.10 树专用）：feeds install 之后、defconfig 之前执行

# 1) 把 golang + xray-core 换成 coolsnowwolf/packages 的版本（-f 强制替换已装的同名包）。
#    这是本构建唯一动官方源选包的地方，验收时查 config.buildinfo：
#    CONFIG_XRAY_CORE_NAIVE=y 必须在，且 manifest 里 xray-core 应为 26.10.31。
./scripts/feeds install -f -p cswpackages golang
./scripts/feeds install -f -p cswpackages xray-core

# 2) 修改默认管理 IP：192.168.1.1 -> 192.168.31.1（AX3000T 既定地址，与 run 20/22 一致）
sed -i 's/192.168.1.1/192.168.31.1/g' package/base-files/files/bin/config_generate

# 3) 注意：lede 版 diy-part2 里给 filogic.mk 打的 factory.ubi 补丁不要带过来——
#    官方树的设备定义自带 ARTIFACTS/initramfs-factory.ubi，构建会原生出 factory.ubi。
