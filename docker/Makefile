run: build
	rm -f ../Gemfile.lock
	docker run --rm -ti -p 4000 -v `pwd`/..:/the-jekyll-root:z github-jekyll

build:
	docker build . -t github-jekyll
