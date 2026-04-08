#!/bin/bash
# Backport: kernel/trace/trace_kprobe.c
# Renames: strncpy_from_unsafe_user -> strncpy_from_user_nofault

echo "======================================"
echo "[*] Patching kernel/trace/trace_kprobe.c ..."
echo "======================================"

if [ ! -f "kernel/trace/trace_kprobe.c" ]; then
    echo "[-] kernel/trace/trace_kprobe.c not found! Run from kernel root."
    exit 1
fi

if grep -q "path_umount" "kernel/trace/trace_kprobe.c"; then
    echo "[-] Warning: kernel/trace/trace_kprobe.c already contains Backport"
    grep -n "path_umount" "kernel/trace/trace_kprobe.c"
    exit 0
fi

if grep -rq --include="*.c" --include="*.h" "strncpy_from_user_nofault" "drivers/kernelsu/" 2>/dev/null; then
    sed -i 's/strncpy_from_unsafe_user/strncpy_from_user_nofault/g' kernel/trace/trace_kprobe.c

    if grep -q "strncpy_from_user_nofault" "kernel/trace/trace_kprobe.c"; then
        echo "[+] kernel/trace/trace_kprobe.c Patched!"
        echo "[+] Count: $(grep -c "strncpy_from_user_nofault" "kernel/trace/trace_kprobe.c")"
    else
        echo "[-] kernel/trace/trace_kprobe.c patch FAILED."
        exit 1
    fi
else
    echo "[-] KernelSU has no strncpy_from_user_nofault, Skipped."
fi

echo "======================================"
