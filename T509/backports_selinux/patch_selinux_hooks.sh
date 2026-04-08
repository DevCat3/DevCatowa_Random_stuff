#!/bin/bash
# Backport: security/selinux/hooks.c
# Part I : inode->i_security  -> selinux_inode(inode)
# Part II: cred->security     -> selinux_cred(cred)

echo "======================================"
echo "[*] Patching security/selinux/hooks.c ..."
echo "======================================"

if [ ! -f "security/selinux/hooks.c" ]; then
    echo "[-] security/selinux/hooks.c not found! Run from kernel root."
    exit 1
fi

KERNEL_VERSION=$(head -n 3 Makefile | grep -E 'VERSION|PATCHLEVEL' | awk '{print $3}' | paste -sd '.')
FIRST_VERSION=$(echo "$KERNEL_VERSION" | awk -F '.' '{print $1}')
SECOND_VERSION=$(echo "$KERNEL_VERSION" | awk -F '.' '{print $2}')
echo "[*] Kernel version: $KERNEL_VERSION"

# Already patched check
if grep -q "selinux_inode(inode)" "security/selinux/hooks.c"; then
    echo "[-] Warning: already contains selinux_inode backport"
    grep -n "selinux_inode(inode)" "security/selinux/hooks.c"
    echo "======================================"
fi

if grep -q "selinux_cred(new)" "security/selinux/hooks.c"; then
    echo "[-] Warning: already contains selinux_cred backport"
    grep -n "selinux_cred" "security/selinux/hooks.c"
    echo "======================================"
fi

# ---------- Part I: selinux_inode ----------
if [ "$FIRST_VERSION" -lt 5 ] && [ "$SECOND_VERSION" -lt 20 ] && \
   grep -rq --include="*.c" --include="*.h" "selinux_inode" "drivers/kernelsu/" 2>/dev/null; then

    sed -i 's/struct inode_security_struct \*isec = inode->i_security/struct inode_security_struct *isec = selinux_inode(inode)/g' security/selinux/hooks.c
    sed -i 's/return inode->i_security/return selinux_inode(inode)/g' security/selinux/hooks.c
    sed -i 's/\bisec = inode->i_security;/isec = selinux_inode(inode);/' security/selinux/hooks.c

    if grep -q "selinux_inode(inode)" "security/selinux/hooks.c"; then
        echo "[+] Part I (selinux_inode) Patched!"
        echo "[+] Count: $(grep -c "selinux_inode" "security/selinux/hooks.c")"
    else
        echo "[-] Part I patch FAILED."
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

    sed -i 's/tsec = cred->security;/tsec = selinux_cred(cred);/g' security/selinux/hooks.c
    sed -i 's/const struct task_security_struct \*tsec = cred->security;/const struct task_security_struct *tsec = selinux_cred(cred);/g' security/selinux/hooks.c
    sed -i 's/const struct task_security_struct \*tsec = current_security();/const struct task_security_struct *tsec = selinux_cred(current_cred());/g' security/selinux/hooks.c
    sed -i 's/rc = selinux_determine_inode_label(current_security()/rc = selinux_determine_inode_label(selinux_cred(current_cred())/g' security/selinux/hooks.c
    sed -i 's/old_tsec = current_security();/old_tsec = selinux_cred(current_cred());/g' security/selinux/hooks.c
    sed -i 's/new_tsec = bprm->cred->security;/new_tsec = selinux_cred(bprm->cred);/g' security/selinux/hooks.c
    sed -i 's/rc = selinux_determine_inode_label(old->security/rc = selinux_determine_inode_label(selinux_cred(old)/g' security/selinux/hooks.c
    sed -i 's/tsec = new->security;/tsec = selinux_cred(new);/g' security/selinux/hooks.c
    sed -i 's/tsec = new_creds->security;/tsec = selinux_cred(new_creds);/g' security/selinux/hooks.c
    sed -i 's/old_tsec = old->security;/old_tsec = selinux_cred(old);/g' security/selinux/hooks.c
    sed -i 's/const struct task_security_struct \*old_tsec = old->security;/const struct task_security_struct *old_tsec = selinux_cred(old);/g' security/selinux/hooks.c
    sed -i 's/struct task_security_struct \*tsec = new->security;/struct task_security_struct *tsec = selinux_cred(new);/g' security/selinux/hooks.c
    sed -i 's/__tsec = current_security();/__tsec = selinux_cred(current_cred());/' security/selinux/hooks.c
    sed -i 's/__tsec = __task_cred(p)->security;/__tsec = selinux_cred(__task_cred(p));/' security/selinux/hooks.c

    if grep -q "selinux_cred" "security/selinux/hooks.c"; then
        echo "[+] Part II (selinux_cred) Patched!"
        echo "[+] Count: $(grep -c "selinux_cred" "security/selinux/hooks.c")"
    else
        echo "[-] Part II patch FAILED."
    fi

elif [ "$FIRST_VERSION" == 5 ] && [ "$SECOND_VERSION" == 4 ]; then
    echo "[-] Kernel $KERNEL_VERSION > 5.1 — Part II Skipped."
else
    echo "[-] KernelSU has no selinux_cred — Part II Skipped."
fi

echo "======================================"
