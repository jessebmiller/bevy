manager-test:
	/bin/sh ./run-testrpc
	docker build -t bevy:test manager
	docker run --rm --link testrpc bevy:test npm test || true
	docker stop testrpc

manager-local:
	/bin/sh ./run-testrpc
	docker build -t bevy:local manager
	docker run --rm --link testrpc bevy:local truffle migrate

manager-console:
	/bin/sh ./run-testrpc
	docker build -t bevy:local manager
	docker run -it --rm --link testrpc bevy:local truffle console

