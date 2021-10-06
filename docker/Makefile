run: build
	rm -f ../Gemfile.lock
	jekyll_root=$${JEKYLL_ROOT-`pwd`/..} ; \
	podman run --rm -ti -p 4000:4000 -v $$jekyll_root:/the-jekyll-root:z github-jekyll


build:
	podman build . -t github-jekyll
