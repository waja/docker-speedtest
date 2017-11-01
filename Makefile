IMAGE_NAME := waja/speedtest

build:
	docker build --rm -t $(IMAGE_NAME) .
	
run:
	@echo docker run --rm -it $(IMAGE_NAME) 
	
shell:
	docker run --rm -it --entrypoint sh $(IMAGE_NAME) -l

test: build
	@if ! [ "$$(docker run --rm -it waja/speedtest -h | head -1 | cut -d' ' -f2)" = "speedtest-cli" ]; then exit 1; fi
