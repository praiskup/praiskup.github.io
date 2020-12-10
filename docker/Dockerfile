FROM fedora:33

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
    zlib-devel \
    && dnf clean all

RUN gem install jekyll github-pages

RUN mkdir /the-jekyll-root

EXPOSE 4000

CMD cd /the-jekyll-root && bundler exec jekyll serve --drafts
