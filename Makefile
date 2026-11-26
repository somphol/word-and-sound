SHELL := /bin/bash
KAIAKI ?= /tmp/kaikki_en.jsonl.gz

.PHONY: data web-data web web-dev build test selftest check app run snapshot clean

data:
	python3 tools/extract_aia.py
	python3 tools/build_corpus.py --kaikki $(KAIAKI)
	python3 tools/build_pattern_lists.py
	cp data/library.json data/phonetics_us.json data/phonetics_uk.json \
		data/provenance.json data/pattern_lists.json data/pattern_report.json \
		data/minimal_pairs.json Sources/WordAndSoundCore/Resources/
	cp data/AppIcon.png Sources/WordAndSoundCore/Resources/AppIcon.png

build:
	swift build

test:
	swift test

selftest:
	swift run wordandsound-selftest

web-data:
	./scripts/sync-web-data.sh

web:
	cd web && npm ci && npm test && npm run build

web-dev:
	cd web && npm run dev

check: test selftest

app:
	./scripts/make_app.sh

run: app
	open build/WordAndSound.app

snapshot:
	mkdir -p docs
	swift run WordAndSound --snapshot docs/screenshot.png

clean:
	rm -rf .build build web/dist web/node_modules
