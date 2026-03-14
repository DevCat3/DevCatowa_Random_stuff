#!/bin/sh

# cd ~/android_kernel_samsung_sm6115

# Repo Clone
curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh" | bash -s v3.1.0-legacy-susfs

# Download required patches
wget https://raw.githubusercontent.com/JackA1ltman/NonGKI_Kernel_Build_2nd/refs/heads/mainline/Patches/Patch/susfs_patch_to_4.19.patch
wget https://raw.githubusercontent.com/JackA1ltman/NonGKI_Kernel_Build_2nd/refs/heads/mainline/Patches/susfs_inline_hook_patches.sh
wget https://raw.githubusercontent.com/DevCat3/android_kernel_samsung_sm6115/refs/heads/lineage-23.2/build_kernel.sh
wget https://raw.githubusercontent.com/JackA1ltman/NonGKI_Kernel_Build_2nd/refs/heads/mainline/Patches/backport_selinux_patches.sh
wget https://raw.githubusercontent.com/JackA1ltman/NonGKI_Kernel_Build_2nd/refs/heads/mainline/Patches/backport_patches.sh
wget https://raw.githubusercontent.com/rksuorg/kernel_patches/refs/heads/master/manual_hook/kernel-4.19_5.4.patch

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
echo CONFIG_KSU_MULTI_MANAGER_SUPPORT=y >> arch/arm64/configs/gta4l_eur_open_defconfig

# make scripts read , write , executable
chmod +xrw susfs_inline_hook_patches.sh
chmod +xrw susfs_patch_to_4.19.patch
chmod +xrw build_kernel.sh
chmod +xrw backport_patches.sh
chmod +xrw backport_selinux_patches.sh

# applying patch
patch -p1 < susfs_patch_to_4.19.patch
patch -p1 < susfs_inline_hook_patches.sh
bash backport_patches.sh
bash backport_selinux_patches.sh


# Make all modules build inline
sed -i 's/CONFIG_LOCALVERSION="-perf"/CONFIG_LOCALVERSION="-BlackCat"/' arch/arm64/configs/gta4l_eur_open_defconfig
sed -i 's/CONFIG_QCA_CLD_WLAN=m/CONFIG_QCA_CLD_WLAN=y/' arch/arm64/configs/gta4l_eur_open_defconfig
sed -i 's/=m/=y/g' techpack/audio/config/bengalauto.conf
sed -i 's/default m/default y/g' techpack/data/drivers/rmnet/shs/Kconfig
sed -i 's/default m/default y/g' techpack/data/drivers/rmnet/perf/Kconfig
sed -i '18s/.*/default y/' drivers/video/backlight/Kconfig
sed -i '/P85946-qrd-overlay\.dtbo-base := bengal\.dtb/d' arch/arm64/boot/dts/vendor/qcom/Makefile
sed -i '/P85946-qrd-overlay\.dtbo/d' arch/arm64/boot/dts/vendor/qcom/Makefile
sed -i '150d' arch/arm64/boot/dts/vendor/qcom/Makefile

# Fix build errors
python3 << 'EOF'
lines = open('fs/susfs.c').readlines()
new_code = '/* try_umount */\n'
new_code += '#ifdef CONFIG_KSU_SUSFS_TRY_UMOUNT\n'
new_code += 'static DEFINE_SPINLOCK(susfs_spin_lock_try_umount);\n'
new_code += 'extern void try_umount(const char *mnt, int flags);\n'
new_code += 'static LIST_HEAD(LH_TRY_UMOUNT_PATH);\n'
new_code += 'void susfs_add_try_umount(void __user **user_info) {\n'
new_code += '\tstruct st_susfs_try_umount info = {0};\n'
new_code += '\tstruct st_susfs_try_umount_list *new_list = NULL;\n'
new_code += '\n'
new_code += '\tif (copy_from_user(&info, (struct st_susfs_try_umount __user*)*user_info, sizeof(info))) {\n'
new_code += '\t\tinfo.err = -EFAULT;\n'
new_code += '\t\tgoto out_copy_to_user;\n'
new_code += '\t}\n'
new_code += '\n'
new_code += '\tif (info.mnt_mode == TRY_UMOUNT_DEFAULT) {\n'
new_code += '\t\tinfo.mnt_mode = 0;\n'
new_code += '\t} else if (info.mnt_mode == TRY_UMOUNT_DETACH) {\n'
new_code += '\t\tinfo.mnt_mode = MNT_DETACH;\n'
new_code += '\t} else {\n'
new_code += '\t\tSUSFS_LOGE("Unsupported mnt_mode: %d\\n", info.mnt_mode);\n'
new_code += '\t\tinfo.err = -EINVAL;\n'
new_code += '\t\tgoto out_copy_to_user;\n'
new_code += '\t}\n'
new_code += '\n'
new_code += '\tnew_list = kmalloc(sizeof(struct st_susfs_try_umount_list), GFP_KERNEL);\n'
new_code += '\tif (!new_list) {\n'
new_code += '\t\tinfo.err = -ENOMEM;\n'
new_code += '\t\tgoto out_copy_to_user;\n'
new_code += '\t}\n'
new_code += '\n'
new_code += '\tmemcpy(&new_list->info, &info, sizeof(info));\n'
new_code += '\n'
new_code += '\tINIT_LIST_HEAD(&new_list->list);\n'
new_code += '\tspin_lock(&susfs_spin_lock_try_umount);\n'
new_code += '\tlist_add_tail(&new_list->list, &LH_TRY_UMOUNT_PATH);\n'
new_code += '\tspin_unlock(&susfs_spin_lock_try_umount);\n'
new_code += '\tSUSFS_LOGI("target_pathname: \'%s\', umount options: %d, is successfully added to LH_TRY_UMOUNT_PATH\\n", new_list->info.target_pathname, new_list->info.mnt_mode);\n'
new_code += '\tinfo.err = 0;\n'
new_code += 'out_copy_to_user:\n'
new_code += '\tif (copy_to_user(&((struct st_susfs_try_umount __user*)*user_info)->err, &info.err, sizeof(info.err))) {\n'
new_code += '\t\tinfo.err = -EFAULT;\n'
new_code += '\t}\n'
new_code += '\tSUSFS_LOGI("CMD_SUSFS_ADD_TRY_UMOUNT -> ret: %d\\n", info.err);\n'
new_code += '}\n'
new_code += '\n'
new_code += 'void susfs_try_umount(uid_t uid) {\n'
new_code += '\tstruct st_susfs_try_umount_list *cursor = NULL;\n'
new_code += '\n'
new_code += '\t// We should umount in reversed order\n'
new_code += '\tlist_for_each_entry_reverse(cursor, &LH_TRY_UMOUNT_PATH, list) {\n'
new_code += '\t\tSUSFS_LOGI("umounting \'%s\' for uid: %u\\n", cursor->info.target_pathname, uid);\n'
new_code += '\t\ttry_umount(cursor->info.target_pathname, cursor->info.mnt_mode);\n'
new_code += '\t}\n'
new_code += '}\n'
new_code += '#endif // #ifdef CONFIG_KSU_SUSFS_TRY_UMOUNT\n'
lines.insert(450, new_code)
open('fs/susfs.c', 'w').writelines(lines)
print("Done!")
EOF

python3 << 'EOF'
lines = open('fs/susfs.c').readlines()
new_code = '#ifdef CONFIG_KSU_SUSFS_TRY_UMOUNT\n'
new_code += '\tinfo->err = copy_config_to_buf("CONFIG_KSU_SUSFS_TRY_UMOUNT\\n", buf_ptr, &copied_size, SUSFS_ENABLED_FEATURES_SIZE);\n'
new_code += '\tif (info->err) goto out_copy_to_user;\n'
new_code += '\tbuf_ptr = info->enabled_features + copied_size;\n'
new_code += '#endif\n'
lines.insert(839, new_code)
open('fs/susfs.c', 'w').writelines(lines)
print("Done!")
EOF

python3 << 'EOF'
lines = open('include/linux/susfs.h').readlines()
new_code = '/* try_umount */\n'
new_code += '#ifdef CONFIG_KSU_SUSFS_TRY_UMOUNT\n'
new_code += 'struct st_susfs_try_umount {\n'
new_code += '\tchar                                    target_pathname[SUSFS_MAX_LEN_PATHNAME];\n'
new_code += '\tint                                     mnt_mode;\n'
new_code += '\tint                                     err;\n'
new_code += '};\n'
new_code += '\n'
new_code += 'struct st_susfs_try_umount_list {\n'
new_code += '\tstruct list_head                        list;\n'
new_code += '\tstruct st_susfs_try_umount              info;\n'
new_code += '};\n'
new_code += '#endif\n'
lines.insert(79, new_code)
open('include/linux/susfs.h', 'w').writelines(lines)
print("Done!")
EOF

python3 << 'EOF'
lines = open('include/linux/susfs.h').readlines()
new_code = '/* try_umount */\n'
new_code += '#ifdef CONFIG_KSU_SUSFS_TRY_UMOUNT\n'
new_code += 'void susfs_add_try_umount(void __user **user_info);\n'
new_code += 'void susfs_try_umount(uid_t uid);\n'
new_code += '#endif // #ifdef CONFIG_KSU_SUSFS_TRY_UMOUNT\n'
lines.insert(188, new_code)
open('include/linux/susfs.h', 'w').writelines(lines)
print("Done!")
EOF

# patch -p1 < kernel-4.19_5.4.patch