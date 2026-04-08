#!/bin/bash
# Backport: security/selinux/include/objsec.h
# Part I : adds selinux_inode() inline function
# Part II: adds selinux_cred() inline function

echo "======================================"
echo "[*] Patching security/selinux/include/objsec.h ..."
echo "======================================"

if [ ! -f "security/selinux/include/objsec.h" ]; then
    echo "[-] security/selinux/include/objsec.h not found! Run from kernel root."
    exit 1
fi

KERNEL_VERSION=$(head -n 3 Makefile | grep -E 'VERSION|PATCHLEVEL' | awk '{print $3}' | paste -sd '.')
FIRST_VERSION=$(echo "$KERNEL_VERSION" | awk -F '.' '{print $1}')
SECOND_VERSION=$(echo "$KERNEL_VERSION" | awk -F '.' '{print $2}')
echo "[*] Kernel version: $KERNEL_VERSION"

# ---------- Part I: selinux_inode ----------
if [ "$FIRST_VERSION" -lt 5 ] && [ "$SECOND_VERSION" -lt 20 ] && \
   grep -rq --include="*.c" --include="*.h" "selinux_inode" "drivers/kernelsu/" 2>/dev/null; then

    if grep -q "selinux_inode" "security/selinux/include/objsec.h"; then
        echo "[-] selinux_inode already in objsec.h — Part I Skipped."
    else
        sed -i '/#endif \/\* _SELINUX_OBJSEC_H_ \*\//i\static inline struct inode_security_struct *selinux_inode(\n\t\t\t\t\t\tconst struct inode *inode)\n{\n\treturn inode->i_security;\n}\n' security/selinux/include/objsec.h

        if grep -q "selinux_inode" "security/selinux/include/objsec.h"; then
            echo "[+] Part I (selinux_inode) Patched!"
            echo "[+] Count: $(grep -c "selinux_inode" "security/selinux/include/objsec.h")"
        else
            echo "[-] Part I patch FAILED."
        fi
    fi

elif [ "$FIRST_VERSION" == 5 ] && [ "$SECOND_VERSION" == 4 ]; then
    echo "[-] Kernel $KERNEL_VERSION > 5.1 — Part I Skipped."
else
    echo "[-] KernelSU has no selinux_inode — Part I Skipped."
fi

echo "======================================"

# ---------- Part II: selinux_cred ----------
if [ "$FIRST_VERSION" -lt 5 ] && [ "$SECOND_VERSION" -lt 20 ] && \
   grep -rq --include="*.c" --include="*.h" "selinux_cred" "drivers/kernelsu/" 2>/dev/null; then

    if grep -q "selinux_cred" "security/selinux/include/objsec.h"; then
        echo "[-] selinux_cred already in objsec.h — Part II Skipped."
    else
        sed -i '/#endif \/\* _SELINUX_OBJSEC_H_ \*\//i\static inline struct task_security_struct *selinux_cred(const struct cred *cred)\n{\n\treturn cred->security;\n}\n' security/selinux/include/objsec.h

        if grep -q "selinux_cred" "security/selinux/include/objsec.h"; then
            echo "[+] Part II (selinux_cred) Patched!"
            echo "[+] Count: $(grep -c "selinux_cred" "security/selinux/include/objsec.h")"
        else
            echo "[-] Part II patch FAILED."
        fi
    fi

elif [ "$FIRST_VERSION" == 5 ] && [ "$SECOND_VERSION" == 4 ]; then
    echo "[-] Kernel $KERNEL_VERSION > 5.1 — Part II Skipped."
else
    echo "[-] KernelSU has no selinux_cred — Part II Skipped."
fi

echo "======================================"
