#!/bin/bash
# Backport: security/selinux/selinuxfs.c
# Replaces: (struct inode_security_struct *)inode->i_security -> selinux_inode(inode)

echo "======================================"
echo "[*] Patching security/selinux/selinuxfs.c ..."
echo "======================================"

if [ ! -f "security/selinux/selinuxfs.c" ]; then
    echo "[-] security/selinux/selinuxfs.c not found! Run from kernel root."
    exit 1
fi

KERNEL_VERSION=$(head -n 3 Makefile | grep -E 'VERSION|PATCHLEVEL' | awk '{print $3}' | paste -sd '.')
FIRST_VERSION=$(echo "$KERNEL_VERSION" | awk -F '.' '{print $1}')
SECOND_VERSION=$(echo "$KERNEL_VERSION" | awk -F '.' '{print $2}')
echo "[*] Kernel version: $KERNEL_VERSION"

if grep -q "selinux_inode(inode)" "security/selinux/selinuxfs.c"; then
    echo "[-] Warning: already contains selinux_inode backport"
    grep -n "selinux_inode(inode)" "security/selinux/selinuxfs.c"
    echo "======================================"
    exit 0
fi

if [ "$FIRST_VERSION" -lt 5 ] && [ "$SECOND_VERSION" -lt 20 ] && \
   grep -rq --include="*.c" --include="*.h" "selinux_inode" "drivers/kernelsu/" 2>/dev/null; then

    sed -i 's/(struct inode_security_struct \*)inode->i_security/selinux_inode(inode)/g' security/selinux/selinuxfs.c

    if grep -q "selinux_inode(inode)" "security/selinux/selinuxfs.c"; then
        echo "[+] security/selinux/selinuxfs.c Patched!"
        echo "[+] Count: $(grep -c "selinux_inode" "security/selinux/selinuxfs.c")"
    else
        echo "[-] security/selinux/selinuxfs.c patch FAILED."
        exit 1
    fi

elif [ "$FIRST_VERSION" == 5 ] && [ "$SECOND_VERSION" == 4 ]; then
    echo "[-] Kernel $KERNEL_VERSION > 5.1 — Skipped."
else
    echo "[-] KernelSU has no selinux_inode — Skipped."
fi

echo "======================================"
