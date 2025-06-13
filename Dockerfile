# this file is derived from build.sh

FROM alpine

WORKDIR /root

# speedup by choosing a different mirror
#RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.bfsu.edu.cn/g' /etc/apk/repositories

RUN apk add gcc make musl-dev ncurses-static
RUN apk add tar xz

RUN mkdir -p /out/vim

ARG VIM_VERSION=v7.2
RUN wget https://github.com/vim/vim/archive/${VIM_VERSION}.tar.gz
RUN tar xf ${VIM_VERSION}.tar.gz
RUN cd vim-* && \
        vim_cv_terminfo=yes LDFLAGS="-static" ./configure \
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
        --with-compiledby='GitHub Actions' \
        --with-features=huge \
        --with-tlib=ncursesw \
        --without-x \
        && sed -E -i 's#.*HAVE_DLOPEN.*#/* & */#' src/auto/config.h \
        && sed -E -i 's#.*HAVE_DLSYM.*#/* & */#' src/auto/config.h \
        && make && make install \
        && cp -r runtime /out/vim/

RUN mkdir -p /out/vim/bin && \
    cp /usr/local/bin/vim /out/vim/bin/ && \
    cp /usr/local/bin/xxd /out/vim/bin/

# set $VIM in entrypoint, otherwise you need to set $VIM manually.
RUN printf '%s\n%s\n%s\n' '#!/bin/sh -e' 'export VIM="$(dirname "$(realpath "$0")")"' 'exec "$VIM"/bin/vim "$@"' > /out/vim/AppRun && chmod +x /out/vim/AppRun

RUN strip /out/vim/bin/vim
RUN chown -R $(id -u):$(id -g) /out/vim

RUN tar -acf /out/vim-${VIM_VERSION}.tar.xz -C /out vim

RUN echo 'run `docker run --rm -i NAME-OF-THIS-IMAGE cat /out/vim-${VIM_VERSION}.tar.xz > OUTPUT-FILENAME.tar.xz` to get result file.'
