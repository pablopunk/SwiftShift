.PHONY: build open-app run

build:
	xcodebuild -scheme "Swift Shift" build SYMROOT=$(PWD)/build

run-app:
	open "./build/Debug/Swift Shift.app"

run: build run-app

