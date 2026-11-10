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

# 1c) lede 独有的 LuCI 小应用（官方 luci 与四个源都没有）：从 coolsnowwolf/luci 的
#     openwrt-25.12 分支（lede 现行 feeds 用的就是这个分支，不是 master）稀疏克隆，
#     把种子里选了的几个拷进 package/feeds/ledeapps/——与 feeds 链接同级，
#     defconfig 可见，各应用自带的 po 中文包会随 LUCI_LANG_zh_Hans 自动生成。
#     依赖均已核过：arpbind→ip-full、autoreboot→luci、filetransfer→luci-compat、
#     oui→luci-base、rclone→rclone-config、vlmcsd 面板→vlmcsd 本体（1b 已链）。
#     luci-app-vsftpd 没拉：它依赖的 vsftpd-alt 找不到干净来源，先放弃。
git clone --depth 1 --filter=blob:none --sparse --branch openwrt-25.12 https://github.com/coolsnowwolf/luci.git /tmp/lede-luci
git -C /tmp/lede-luci sparse-checkout set applications/luci-app-arpbind applications/luci-app-autoreboot applications/luci-app-filetransfer applications/luci-app-oui applications/luci-app-rclone applications/luci-app-vlmcsd
mkdir -p package/feeds/ledeapps
for app in luci-app-arpbind luci-app-autoreboot luci-app-filetransfer luci-app-oui luci-app-rclone luci-app-vlmcsd; do
  cp -r "/tmp/lede-luci/applications/$app" package/feeds/ledeapps/
done

# 2) 修改默认管理 IP：192.168.1.1 -> 192.168.31.1（AX3000T 既定地址，与 run 20/22 一致）
sed -i 's/192.168.1.1/192.168.31.1/g' package/base-files/files/bin/config_generate

# 3) 注意：lede 版 diy-part2 里给 filogic.mk 打的 factory.ubi 补丁不要带过来——
#    官方树的设备定义自带 ARTIFACTS/initramfs-factory.ubi，构建会原生出 factory.ubi。