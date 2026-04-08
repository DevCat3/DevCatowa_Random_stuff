#!/bin/bash
# Backport: fs/internal.h
# Adds: path_umount declaration

echo "======================================"
echo "[*] Patching fs/internal.h ..."
echo "======================================"

if [ ! -f "fs/internal.h" ]; then
    echo "[-] fs/internal.h not found! Run from kernel root."
    exit 1
fi

if grep -q "path_umount" "fs/internal.h"; then
    echo "[-] Warning: fs/internal.h already contains Backport"
    echo "[+] Code in here:"
    grep -n "path_umount" "fs/internal.h"
    echo "[-] End of file."
    echo "======================================"
    exit 0
fi

sed -i '/^extern void __init mnt_init(void);$/a\int path_umount(struct path *path, int flags);' fs/internal.h

if grep -q "path_umount" "fs/internal.h"; then
    echo "[+] fs/internal.h Patched!"
    echo "[+] Count: $(grep -c "path_umount" "fs/internal.h")"
else
    echo "[-] fs/internal.h patch FAILED."
    exit 1
fi

echo "======================================"
