.PHONY: build test open-app run appcast generate-keys release

build:
	xcodebuild -scheme "Swift Shift" build SYMROOT=$(PWD)/build \
		CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

run-app:
	open "./build/Debug/Swift Shift Dev.app"

test:
	xcodebuild test \
		-project "Swift Shift.xcodeproj" \
		-scheme "Swift Shift" \
		-destination "platform=macOS" \
		-only-testing:SwiftShiftTests \
		-enableCodeCoverage NO \
		CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

run: build run-app

appcast:
	@$(eval ARGS := $(filter-out $@,$(MAKECMDGOALS)))
	./scripts/generate-appcast.sh $(ARGS)

generate-keys:
	@$(eval ARGS := $(filter-out $@,$(MAKECMDGOALS)))
	./scripts/generate-keys.sh $(ARGS)

release:
	./scripts/release.sh $(VERSION)

%:
	@:

