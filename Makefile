.PHONY: bootstrap project check clean

bootstrap:
	./bootstrap.command

project:
	xcodegen generate --spec project.yml

check:
	./Scripts/check_architecture.sh

clean:
	rm -rf ModularBank.xcodeproj DerivedData

