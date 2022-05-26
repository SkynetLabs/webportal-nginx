# Running tests locally

`docker run -v $(pwd)/nginx/libs:/usr/local/openresty/site/lualib --rm -it $(docker build -q testing)`
