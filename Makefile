# Local and CI use the same commands. See README "Running Tests".
.PHONY: deps analyze fmt test-fast test-all coverage-baseline prerelease

deps:
	flutter pub get

analyze:
	flutter analyze --no-fatal-infos

## fmt: not yet a CI gate — 58 of 203 files predate any formatting discipline.
fmt:
	dart format lib test

## test-fast: the inner-loop command. No coverage, no JUnit.
test-fast:
	flutter test

## test-all: everything CI runs on a pull request.
## Needs: dart pub global activate junitreport
test-all: analyze
	mkdir -p reports
	set -o pipefail; flutter test --machine --coverage | tojunit --output reports/junit.xml
	python3 scripts/coverage_ratchet.py

## coverage-baseline: re-record the ratchet baseline after intentional changes.
coverage-baseline:
	flutter test --coverage
	python3 scripts/coverage_ratchet.py --write

## prerelease: the pre-release security/quality gate (needs gitleaks).
prerelease:
	scripts/prerelease_check.sh
