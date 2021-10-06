FROM fedora:35

RUN dnf install -y \
    /usr/bin/gem \
    gcc \
    gcc-c++ \
    git-core \
    libxml2-devel \
    openssl-devel \
    redhat-rpm-config \
    ruby-devel \
    rubygem-eventmachine \
    rubygem-ffi \
    tinyproxy \
    zlib-devel \
    /usr/bin/nc \
    && dnf clean all

RUN gem install \
    github-pages \
    jekyll \
    webrick

COPY starter /starter
COPY tinyproxy.conf /etc/tinyproxy/tinyproxy.conf

RUN mkdir /the-jekyll-root && \
    chmod 755 /starter

EXPOSE 4000

CMD cd /the-jekyll-root && /starter
