#!/bin/bash
# Backport: fs/namespace.c
# Adds: can_umount() + path_umount()
# ⚠️  Most likely cause of boot loop — patches core mount/umount logic

echo "======================================"
echo "[*] Patching fs/namespace.c ..."
echo "======================================"

if [ ! -f "fs/namespace.c" ]; then
    echo "[-] fs/namespace.c not found! Run from kernel root."
    exit 1
fi

# Skip if already patched
if grep -q "path_umount" "fs/namespace.c"; then
    echo "[-] Warning: fs/namespace.c already contains Backport"
    echo "[+] Code in here:"
    grep -n "path_umount" "fs/namespace.c"
    echo "[-] End of file."
    echo "======================================"
    exit 0
fi

sed -i '/^SYSCALL_DEFINE2(umount, char __user \*, name, int, flags)/i\static int can_umount(const struct path *path, int flags)\n{\n\tstruct mount *mnt = real_mount(path->mnt);\n\tif (!may_mount())\n\t\treturn -EPERM;\n\tif (path->dentry != path->mnt->mnt_root)\n\t\treturn -EINVAL;\n\tif (!check_mnt(mnt))\n\t\treturn -EINVAL;\n\tif (mnt->mnt.mnt_flags \& MNT_LOCKED) \/\* Check optimistically *\/\n\t\treturn -EINVAL;\n\tif (flags \& MNT_FORCE \&\& !capable(CAP_SYS_ADMIN))\n\t\treturn -EPERM;\n\treturn 0;\n}\n\/\/ caller is responsible for flags being sane\nint path_umount(struct path *path, int flags)\n{\n\tstruct mount *mnt = real_mount(path->mnt);\n\tint ret;\n\tret = can_umount(path, flags);\n\tif (!ret)\n\t\tret = do_umount(mnt, flags);\n\t\/\* we mustn'"'"'t call path_put() as that would clear mnt_expiry_mark *\/\n\tdput(path->dentry);\n\tmntput_no_expire(mnt);\n\treturn ret;\n}\n' fs/namespace.c

if grep -q "can_umount" "fs/namespace.c"; then
    echo "[+] fs/namespace.c Patched!"
    echo "[+] Count: $(grep -c "can_umount" "fs/namespace.c")"
else
    echo "[-] fs/namespace.c patch FAILED — check sed output manually."
    exit 1
fi

echo "======================================"
