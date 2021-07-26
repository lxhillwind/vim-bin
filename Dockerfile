# this file is derived from build.sh

FROM alpine:3.14

WORKDIR /root

# speedup by choosing a different mirror
#RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.bfsu.edu.cn/g' /etc/apk/repositories

RUN apk add gcc make musl-dev ncurses-static
RUN apk add lua5.1 lua5.1-dev

ARG VIM_VERSION=v7.2
RUN wget https://github.com/vim/vim/archive/${VIM_VERSION}.tar.gz
RUN tar xf ${VIM_VERSION}.tar.gz
RUN cd vim-* && \
        LDFLAGS="-static" ./configure \
        --disable-gtktest \
        --disable-gui \
        --disable-netbeans \
        --disable-nls \
        --disable-selinux \
        --disable-smack \
        --disable-sysmouse \
        --disable-xsmp \
        --enable-gpm \
        --enable-multibyte \
        --enable-luainterp=yes \
        --with-compiledby='GitHub Actions' \
        --with-features=huge \
        --with-tlib=ncursesw \
        --without-x \
        && make && make install

RUN mkdir -p /out/vim
RUN cp -r /usr/local/* /out/vim

# set $VIM in entrypoint, otherwise you need to set $VIM manually.
RUN cd /out/vim/share/vim && ln -s vim* vim-current
RUN printf '%s\n%s\n%s\n' '#!/bin/sh -e' 'cwd="$(dirname "$(realpath "$0")")"' 'exec env VIM="$cwd"/share/vim/vim-current "$cwd"/bin/vim "$@"' > /out/vim/AppRun && chmod +x /out/vim/AppRun

RUN strip /out/vim/bin/vim
RUN chown -R $(id -u):$(id -g) /out/vim

RUN apk add tar xz
RUN tar -acf /out/vim-${VIM_VERSION}.tar.xz -C /out vim

RUN echo 'run `docker run --rm -i NAME-OF-THIS-IMAGE cat /out/vim-${VIM_VERSION}.tar.xz > OUTPUT-FILENAME.tar.xz` to get result file.'
