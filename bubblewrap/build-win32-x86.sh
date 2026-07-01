#!/bin/bash

# copied from ../Dockerfile.mingw-x86, modified.

set -e

if ! [[ "$(readlink /proc/1/exe)" =~ bwrap ]]; then
    cd "$(dirname "$0")"
    mkdir -p out
    bwrap_args=(
        # env:
        --clearenv
        # basic
        --setenv PATH /bin:/usr/bin:/usr/local/bin #--setenv USER "$USER" --setenv HOME ~

        --symlink usr/lib64 /lib64
        --symlink usr/lib /lib
        --symlink usr/bin /bin
        --symlink usr/sbin /sbin
        --ro-bind /usr /usr

        # proc, sys, dev
        --proc /proc
        # --ro-bind /sys /sys; see https://wiki.archlinux.org/title/Bubblewrap
        --ro-bind /sys/dev/char /sys/dev/char
        --ro-bind /sys/devices/pci0000:00 /sys/devices/pci0000:00
        --ro-bind /sys/bus/pci /sys/bus/pci
        --dev /dev

        # app
        --tmpfs /usr/local/bin  # for "windres tweak"
        --bind out/ /out/
        --bind vim-src/ vim-src/
        --tmpfs /tmp
        --ro-bind ../legacy-icon.ico /tmp/vim.ico
        --ro-bind ./build-win32-x86.sh /tmp/main.sh

        # network.
        --unshare-all --share-net

        # security
        --new-session
        --die-with-parent

        bash -e /tmp/main.sh
        )
    exec bwrap "${bwrap_args[@]}"
    exit 2  # unreachable
fi

ARCH=i686

mkdir -p /out/vim

# windres tweak
printf '%s\n%s\n' '#!/bin/sh' 'exec /usr/bin/'$ARCH'-w64-mingw32-windres "$@"' > /usr/local/bin/windres && chmod +x /usr/local/bin/windres

# `echo $ARCH | tr _ -`: x86_64 -> x86-64.
cd vim-*/src && \
        sed -i -E 's/^CROSS=.+/CROSS=yes/' Make_cyg_ming.mak && \
        sed -i -E 's/^CSCOPE=.+/CSCOPE=no/' Make_cyg_ming.mak && \
        sed -i -E 's/^NETBEANS=.+/NETBEANS=no/' Make_cyg_ming.mak && \
        sed -i -E 's/^GETTEXT=.+/GETTEXT=no/' Make_cyg_ming.mak && \
    { if [ "$ARCH" = i686 ]; then \
        cp /tmp/vim.ico ../runtime/bitmaps/ && \
        cp /tmp/vim.ico ./ && \
        sed -i '1 i#define GetFinalPathNameByHandleW(a, b, c, d) 0' os_mswin.c && \
        sed -i '1 i#define GetConsoleScreenBufferInfoEx(a, b) ;' os_win32.c && \
        sed -i '1 i#define SetConsoleScreenBufferInfoEx(a, b) ;' os_win32.c && \
        sed -i 's/GetCurrentConsoleFontEx/XP_Not_Support_GetCurrentConsoleFontEx/g' os_win32.c && \
        sed -i '1 i#define XP_Not_Support_GetCurrentConsoleFontEx(a, b, c) 0' os_win32.c && \
        sed -i '1 i#define MOUSE_HWHEELED 0x8  /* only defined for NT6.0+ */' os_win32.c && \
        printf '%s\n%s\n%s\n%s\n' '#ifdef _WIN32' 'int is_cygpty(int fd) { return 0; }' 'int is_cygpty_used(void) { return 0; }' '#endif' > iscygpty.c && \
        sed -i '1 i#define wcscpy_s(a, b, c) ;' os_mswin.c && \
        sed -i -E '/^DEFINES \+= -DHAVE_INET_NTOP$/d' Make_cyg_ming.mak && \
        sed -i -E 's/^.*-lstdc.*/LIB += -static-libstdc++ -static-libgcc/' Make_cyg_ming.mak; \
    fi; } && \
        env VIMDLL=yes WINVER=$(if [ "$ARCH" = i686 ]; then echo 0x0501; else echo 0x0601; fi) ARCH=$(echo $ARCH | tr _ -) CROSS_COMPILE=$ARCH-w64-mingw32- STATIC_STDCPLUS=yes STATIC_WINPTHREAD=yes \
        make -j8 -f Make_ming.mak gvim.exe vim.exe tee/tee.exe xxd/xxd.exe vimrun.exe && \
        mv vim*.dll gvim.exe vim.exe tee/tee.exe xxd/xxd.exe vimrun.exe /out/vim/

cd -
cp -r vim-*/runtime /out/vim
