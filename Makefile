# Xcode is required at this path. xcode-select points at the Command Line Tools,
# which cannot build or test this project.
export DEVELOPER_DIR := /Applications/Xcode.app/Contents/Developer

PROJECT := RunnerGame.xcodeproj
SCHEME  := RunnerGame
DERIVED := build
APP     := $(DERIVED)/Build/Products/Debug/RunnerGame.app

.PHONY: generate build test run clean

generate:
	xcodegen generate

build: generate
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Debug -derivedDataPath $(DERIVED) build

test: generate
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Debug -derivedDataPath $(DERIVED) test

run: build
	open $(APP)

clean:
	rm -rf $(DERIVED)
