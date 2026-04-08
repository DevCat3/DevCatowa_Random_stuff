#!/bin/bash
# Backport: mm/maccess.c
# Renames: strncpy_from_unsafe_user -> strncpy_from_user_nofault

echo "======================================"
echo "[*] Patching mm/maccess.c ..."
echo "======================================"

if [ ! -f "mm/maccess.c" ]; then
    echo "[-] mm/maccess.c not found! Run from kernel root."
    exit 1
fi

if grep -q "path_umount" "mm/maccess.c"; then
    echo "[-] Warning: mm/maccess.c already contains Backport"
    grep -n "path_umount" "mm/maccess.c"
    exit 0
fi

if grep -rq --include="*.c" --include="*.h" "strncpy_from_user_nofault" "drivers/kernelsu/" 2>/dev/null; then
    sed -i 's/strncpy_from_unsafe_user/strncpy_from_user_nofault/g' mm/maccess.c

    if grep -q "strncpy_from_user_nofault" "mm/maccess.c"; then
        echo "[+] mm/maccess.c Patched!"
        echo "[+] Count: $(grep -c "strncpy_from_user_nofault" "mm/maccess.c")"
    else
        echo "[-] mm/maccess.c patch FAILED."
        exit 1
    fi
else
    echo "[-] KernelSU has no strncpy_from_user_nofault, Skipped."
fi

echo "======================================"
