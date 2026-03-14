#!/bin/sh

curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh" | bash -s v3.1.0-legacy-susfs
# curl -LSs "https://raw.githubusercontent.com/ReSukiSU/ReSukiSU/main/kernel/setup.sh" | bash

wget https://raw.githubusercontent.com/LineageOS/android_kernel_samsung_sm6115/refs/heads/lineage-20/arch/arm64/configs/gta4l_eur_open_defconfig
wget https://raw.githubusercontent.com/JackA1ltman/NonGKI_Kernel_Build_2nd/refs/heads/mainline/Patches/Patch/susfs_patch_to_4.19.patch
wget https://raw.githubusercontent.com/JackA1ltman/NonGKI_Kernel_Build_2nd/refs/heads/mainline/Patches/susfs_inline_hook_patches.sh
wget https://raw.githubusercontent.com/JackA1ltman/NonGKI_Kernel_Build_2nd/refs/heads/mainline/Patches/backport_selinux_patches.sh
wget https://raw.githubusercontent.com/JackA1ltman/NonGKI_Kernel_Build_2nd/refs/heads/mainline/Patches/backport_patches.sh
wget https://raw.githubusercontent.com/DevCat3/android_kernel_samsung_sm6115/refs/heads/lineage-20/build_kernel.sh

chmod +xrw susfs_inline_hook_patches.sh
chmod +xrw gta4l_eur_open_defconfig
chmod +xrw susfs_patch_to_4.19.patch
chmod +xrw build_kernel.sh
chmod +xrw backport_patches.sh
chmod +xrw backport_selinux_patches.sh

mv gta4l_eur_open_defconfig arch/arm64/configs/

# KSU Configs
echo CONFIG_KSU=y >> arch/arm64/configs/gta4l_eur_open_defconfig
echo CONFIG_KSU_MANUAL_HOOK=y >> arch/arm64/configs/gta4l_eur_open_defconfig
echo CONFIG_KSU_SUSFS=y  >> arch/arm64/configs/gta4l_eur_open_defconfig
echo CONFIG_KSU_SUSFS_SUS_MOUNT=y >> arch/arm64/configs/gta4l_eur_open_defconfig
echo CONFIG_KSU_SUSFS_SUS_KSTAT=y >> arch/arm64/configs/gta4l_eur_open_defconfig
echo CONFIG_KSU_SUSFS_TRY_UMOUNT=y >> arch/arm64/configs/gta4l_eur_open_defconfig
echo CONFIG_KSU_SUSFS_SPOOF_UNAME=y >> arch/arm64/configs/gta4l_eur_open_defconfig
echo CONFIG_KSU_SUSFS_ENABLE_LOG=y >> arch/arm64/configs/gta4l_eur_open_defconfig
echo CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS=y >> arch/arm64/configs/gta4l_eur_open_defconfig
echo CONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG=y >> arch/arm64/configs/gta4l_eur_open_defconfig
echo CONFIG_KSU_SUSFS_OPEN_REDIRECT=y >> arch/arm64/configs/gta4l_eur_open_defconfig
echo CONFIG_KSU_SUSFS_SUS_MAP=y >> arch/arm64/configs/gta4l_eur_open_defconfig
# echo CONFIG_KSU_MULTI_MANAGER_SUPPORT=y >> arch/arm64/configs/gta4l_eur_open_defconfig
echo "" > localversion-st
echo "" > localversion-cip

# patch -p1 < susfs_patch_to_4.19.patch
patch -p1 < susfs_patch_to_4.19.patch
patch -p1 < susfs_inline_hook_patches.sh
bash backport_patches.sh
bash backport_selinux_patches.sh

sed -i 's/CONFIG_LOCALVERSION="-perf"/CONFIG_LOCALVERSION="-BlackCat"/' arch/arm64/configs/gta4l_eur_open_defconfig
sed -i 's/CONFIG_QCA_CLD_WLAN=m/CONFIG_QCA_CLD_WLAN=y/' arch/arm64/configs/gta4l_eur_open_defconfig
sed -i 's/=m/=y/g' techpack/audio/config/bengalauto.conf
sed -i 's/default m/default y/g' techpack/data/drivers/rmnet/shs/Kconfig
sed -i 's/default m/default y/g' techpack/data/drivers/rmnet/perf/Kconfig
sed -i '18s/.*/default y/' drivers/video/backlight/Kconfig
sed -i '/P85946-qrd-overlay\.dtbo-base := bengal\.dtb/d' arch/arm64/boot/dts/vendor/qcom/Makefile
sed -i '/P85946-qrd-overlay\.dtbo/d' arch/arm64/boot/dts/vendor/qcom/Makefile
sed -i '150d' arch/arm64/boot/dts/vendor/qcom/Makefile