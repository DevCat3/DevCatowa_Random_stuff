#!/bin/bash
# Backport: include/linux/uaccess.h
# Renames: strncpy_from_unsafe_user -> strncpy_from_user_nofault (declaration)

echo "======================================"
echo "[*] Patching include/linux/uaccess.h ..."
echo "======================================"

if [ ! -f "include/linux/uaccess.h" ]; then
    echo "[-] include/linux/uaccess.h not found! Run from kernel root."
    exit 1
fi

if grep -q "path_umount" "include/linux/uaccess.h"; then
    echo "[-] Warning: include/linux/uaccess.h already contains Backport"
    grep -n "path_umount" "include/linux/uaccess.h"
    exit 0
fi

if grep -rq --include="*.c" --include="*.h" "strncpy_from_user_nofault" "drivers/kernelsu/" 2>/dev/null; then
    sed -i 's/^extern long strncpy_from_unsafe_user/long strncpy_from_user_nofault/' include/linux/uaccess.h

    if grep -q "strncpy_from_user_nofault" "include/linux/uaccess.h"; then
        echo "[+] include/linux/uaccess.h Patched!"
        echo "[+] Count: $(grep -c "strncpy_from_user_nofault" "include/linux/uaccess.h")"
    else
        echo "[-] include/linux/uaccess.h patch FAILED."
        exit 1
    fi
else
    echo "[-] KernelSU has no strncpy_from_user_nofault, Skipped."
fi

echo "======================================"
