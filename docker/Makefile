services-run:
	docker compose --env-file ./.env -p pepaswap_local up --build -d

services-clean:
	docker compose -p pepaswap_local down --rmi local -v --remove-orphans

services-run-test:
	docker compose --env-file ./.env.test -p pepaswap_test up --build -d

services-clean-test:
	docker compose -p pepaswap_test down --rmi local -v --remove-orphans
