FROM barebuild/el:8
WORKDIR /app
ARG PKGR_VERSION

RUN curl -GLs https://buildcurl.com -d recipe=pkgr -d version="$PKGR_VERSION" -d target="$TARGET" -o - | tar xzf - -C /usr/local
ENTRYPOINT ["/usr/local/bin/pkgr", "package", ".", "--clean", "--auto", "--compile-cache-dir", "/cache"]
