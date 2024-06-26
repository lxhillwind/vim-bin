# vim build

## feature

- linux
    - x64 build;
    - do not depend on system libc;
    - provides a `vim/AppRun` script to make the build "portable" (you can put
      the directory anywhere, then simply `ln -s path-to-AppRun desired-path`);

- win32
    - x86 / x64 build;
    - no OLE (so portable);
    - you can create a desktop shortcut to `vim/gvim.exe`; or just add the
      directory to `$PATH`;

directory structure:

```console
# win32 build
vim/
vim/runtime/
vim/gvim.exe
vim/tee.exe
vim/vim.exe
vim/vim32.dll
vim/vimrun.exe
vim/xxd.exe

# linux build
vim/
vim/AppRun
vim/bin/
vim/bin/xxd
vim/bin/vim
vim/runtime/
```

<details>

<summary>
about build script
</summary>

For linux,
[archive/build.sh](archive/build.sh) is from <https://github.com/dtschan/vim-static>,
[modified](Dockerfile) to be used in docker.

For win32,
[archive/build.bat](archive/build.bat) is from <https://github.com/vim/vim-win32-installer>.

(But now I use [mingw 32bit](Dockerfile.mingw-x86) / [mingw 64bit](Dockerfile.mingw-x64) to compile instead; instruction can be found in
<https://github.com/vim/vim/blob/master/src/INSTALLpc.txt>
)

</details>

## note for Windows

winpty is not included; download it manually from
<https://github.com/rprichard/winpty/releases>.

```sh
# example for x86:
curl -L https://github.com/rprichard/winpty/releases/download/0.4.3/winpty-0.4.3-msys2-2.7.0-ia32.tar.gz -o winpty.tar.gz
tar --strip-components=1 -xf winpty.tar.gz
cp bin/winpty.dll $VIMRUNTIME/winpty32.dll
cp bin/winpty-agent.exe $VIMRUNTIME/
```

**winpty32.dll / winpty64.dll** (instead of default filename winpty.dll):
required to make git-for-bash work in vim embedded terminal.

## how to build on your own host

```sh
# linux build
docker build --build-arg VIM_VERSION=v8.2.2845 -t build-vim-8 .

# win32 x86 build
docker build --build-arg VIM_VERSION=v8.2.2845 -f Dockerfile.mingw-x86 -t build-vim-win32-x86 .
```

`VIM_VERSION` is tag name in <https://github.com/vim/vim>.

## about x86 build for Windows XP

The (officially) newest version running on Windows XP: v9.0.0495;
patch [v9.0.0496](https://github.com/vim/vim/commit/27b53be3a6a340f1858bcd31233fe2efc86f8e15) drops Windows XP support.

Version after it may work, but the compilation process requires patch (see
[Dockerfile.mingw-x86](Dockerfile.mingw-x86)); otherwise it won't even compile.

[legacy icon](./legacy-icon.ico) is from
<https://github.com/vim/vim/blob/v8.2.4544/src/vim.ico>; it is viewable in
Windows XP, though low resolution.
