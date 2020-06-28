FROM alpine:latest as builder

ENV TMUX_VERSION=3.1b
ENV NCURSES_VERSION=6.1
ENV LIBEVENT_VERSION=2.1.11

ENV BASEDIR=/tmp/tmux
ENV TMUXTARGET=${BASEDIR}/local

ENV PKG_CONFIG_PATH="${TMUXTARGET}/lib/pkgconfig"

WORKDIR ${BASEDIR}

RUN apk add -U ca-certificates libc-dev bash make wget gcc && mkdir -p ${TMUXTARGET}
RUN wget -O libevent-${LIBEVENT_VERSION}-stable.tar.gz https://github.com/libevent/libevent/releases/download/release-${LIBEVENT_VERSION}-stable/libevent-${LIBEVENT_VERSION}-stable.tar.gz
RUN wget -O ncurses-${NCURSES_VERSION}.tar.gz http://ftp.gnu.org/gnu/ncurses/ncurses-${NCURSES_VERSION}.tar.gz
RUN wget -O tmux-${TMUX_VERSION}.tar.gz https://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz

RUN tar -xzf libevent-${LIBEVENT_VERSION}-stable.tar.gz && \
    cd ${BASEDIR}/libevent-${LIBEVENT_VERSION}-stable && \
    ./configure --prefix=$TMUXTARGET --disable-shared && \
    make && make install && \
    cd ${BASEDIR} && \
    tar -xzf ncurses-${NCURSES_VERSION}.tar.gz && \
    cd ${BASEDIR}/ncurses-${NCURSES_VERSION} && \
    ./configure --prefix=$TMUXTARGET --with-default-terminfo-dir=/usr/share/terminfo --with-terminfo-dirs="/etc/terminfo:/lib/terminfo:/usr/share/terminfo" && \
    make && make install && \
    cd ${BASEDIR} && \
    tar -xzf tmux-${TMUX_VERSION}.tar.gz && \
    cd tmux-${TMUX_VERSION} && \
    ./configure --prefix=$TMUXTARGET --enable-static CFLAGS="-I${TMUXTARGET}/include -I${TMUXTARGET}/include/ncurses" LDFLAGS="-L${TMUXTARGET}/lib -L${TMUXTARGET}/include -L${TMUXTARGET}/include/ncurses" LIBEVENT_CFLAGS="-I${TMUXTARGET}/include" LIBEVENT_LIBS="-L${TMUXTARGET}/lib -levent" LIBNCURSES_CFLAGS="-I${TMUXTARGET}/include" LIBNCURSES_LIBS="-L${TMUXTARGET}/lib -lncurses" && \
    make && make install && \
    $TMUXTARGET/bin/tmux -V

FROM alpine:latest
ENV BASEDIR=/tmp/tmux
ENV TMUXTARGET=${BASEDIR}/local

COPY --from=builder ${TMUXTARGET}/bin/tmux /usr/local/bin
RUN apk add -U --no-cache ncurses-terminfo-base
CMD tmux
