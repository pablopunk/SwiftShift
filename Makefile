.PHONY: build open-app run appcast generate-keys

build:
	xcodebuild -scheme "Swift Shift" build SYMROOT=$(PWD)/build

run-app:
	open "./build/Debug/Swift Shift.app"

run: build run-app

appcast:
	@$(eval ARGS := $(filter-out $@,$(MAKECMDGOALS)))
	./scripts/generate-appcast.sh $(ARGS)

generate-keys:
	@$(eval ARGS := $(filter-out $@,$(MAKECMDGOALS)))
	./scripts/generate-keys.sh $(ARGS)

%:
	@:

