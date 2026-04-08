#!/bin/bash
# Backport: include/linux/seccomp.h
# Adds: atomic_t filter_count to seccomp struct

echo "======================================"
echo "[*] Patching include/linux/seccomp.h ..."
echo "======================================"

if [ ! -f "include/linux/seccomp.h" ]; then
    echo "[-] include/linux/seccomp.h not found! Run from kernel root."
    exit 1
fi

if grep -q "selinux_inode(inode)" "include/linux/seccomp.h" || \
   grep -q "selinux_cred(new)" "include/linux/seccomp.h"; then
    echo "[-] Warning: include/linux/seccomp.h already contains Backport"
    exit 0
fi

if grep -q "filter_count" "include/linux/seccomp.h"; then
    echo "[-] Detected filter_count already in kernel, Skipped."
else
    sed -i '/#include <linux\/thread_info.h>/a\#include <linux\/atomic.h>' include/linux/seccomp.h
    sed -i '/struct seccomp_filter \*filter;/i\ \tatomic_t filter_count;' include/linux/seccomp.h

    if grep -q "filter_count" "include/linux/seccomp.h"; then
        echo "[+] include/linux/seccomp.h Patched!"
        echo "[+] Count: $(grep -c "filter_count" "include/linux/seccomp.h")"
    else
        echo "[-] include/linux/seccomp.h patch FAILED."
        exit 1
    fi
fi

echo "======================================"
