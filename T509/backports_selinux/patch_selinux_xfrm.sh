#!/bin/bash
# Backport: security/selinux/xfrm.c
# Replaces: current_security() -> selinux_cred(current_cred())

echo "======================================"
echo "[*] Patching security/selinux/xfrm.c ..."
echo "======================================"

if [ ! -f "security/selinux/xfrm.c" ]; then
    echo "[-] security/selinux/xfrm.c not found! Run from kernel root."
    exit 1
fi

KERNEL_VERSION=$(head -n 3 Makefile | grep -E 'VERSION|PATCHLEVEL' | awk '{print $3}' | paste -sd '.')
FIRST_VERSION=$(echo "$KERNEL_VERSION" | awk -F '.' '{print $1}')
SECOND_VERSION=$(echo "$KERNEL_VERSION" | awk -F '.' '{print $2}')
echo "[*] Kernel version: $KERNEL_VERSION"

if grep -q "selinux_cred(new)" "security/selinux/xfrm.c"; then
    echo "[-] Warning: already contains selinux_cred backport"
    grep -n "selinux_cred" "security/selinux/xfrm.c"
    echo "======================================"
    exit 0
fi

if [ "$FIRST_VERSION" -lt 5 ] && [ "$SECOND_VERSION" -lt 20 ] && \
   grep -rq --include="*.c" --include="*.h" "selinux_cred" "drivers/kernelsu/" 2>/dev/null; then

    sed -i 's/const struct task_security_struct \*tsec = current_security();/const struct task_security_struct *tsec = selinux_cred(current_cred());/g' security/selinux/xfrm.c

    if grep -q "selinux_cred" "security/selinux/xfrm.c"; then
        echo "[+] security/selinux/xfrm.c Patched!"
        echo "[+] Count: $(grep -c "selinux_cred" "security/selinux/xfrm.c")"
    else
        echo "[-] security/selinux/xfrm.c patch FAILED."
        exit 1
    fi

elif [ "$FIRST_VERSION" == 5 ] && [ "$SECOND_VERSION" == 4 ]; then
    echo "[-] Kernel $KERNEL_VERSION > 5.1 — Skipped."
else
    echo "[-] KernelSU has no selinux_cred — Skipped."
fi

echo "======================================"
