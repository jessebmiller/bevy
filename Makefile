test: .
	/bin/sh ./run-testrpc
	docker build -t bevy:test .
	docker run --rm --link testrpc bevy:test npm test




