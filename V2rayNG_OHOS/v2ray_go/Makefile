.PHONY: all clean arm64 arm32 x64

all: arm64 arm32 x64

OHOS_NDK ?= $(OHOS_NDK_HOME)

arm64:
	@echo "Building for arm64-v8a..."
	GOOS=linux GOARCH=arm64 CGO_ENABLED=1 \
	CC=$(OHOS_NDK)/toolchains/llvm/bin/aarch64-linux-ohos21-clang \
	CXX=$(OHOS_NDK)/toolchains/llvm/bin/aarch64-linux-ohos21-clang++ \
	go build -buildmode=c-archive -ldflags="-s -w" \
		-o libs/arm64-v8a/libv2ray_core.a .

arm32:
	@echo "Building for armeabi-v7a..."
	GOOS=linux GOARCH=arm CGO_ENABLED=1 GOARM=7 \
	CC=$(OHOS_NDK)/toolchains/llvm/bin/arm-linux-ohos21-clang \
	CXX=$(OHOS_NDK)/toolchains/llvm/bin/arm-linux-ohos21-clang++ \
	go build -buildmode=c-archive -ldflags="-s -w" \
		-o libs/armeabi-v7a/libv2ray_core.a .

x64:
	@echo "Building for x86_64..."
	GOOS=linux GOARCH=amd64 CGO_ENABLED=1 \
	CC=$(OHOS_NDK)/toolchains/llvm/bin/x86_64-linux-ohos21-clang \
	CXX=$(OHOS_NDK)/toolchains/llvm/bin/x86_64-linux-ohos21-clang++ \
	go build -buildmode=c-archive -ldflags="-s -w" \
		-o libs/x86_64/libv2ray_core.a .

clean:
	rm -rf libs/
