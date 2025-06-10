# ==================================================================================== #
# HELPERS (DO NOT WORK)
# ==================================================================================== #

## help: print this help message
.PHONY: help
help: 
	@echo "Usage:"
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' | sed -e 's/^/ /'
.PHONY: confirm
confirm:
	set /p ans="are you sure [y/n]"
	if "%ans%" == "y" (
		@echo yes)
# ==================================================================================== #
# DEVELOPMENT
# ==================================================================================== #

## run/api: run the cmd/api application
.PHONY: run/api
run/api:
	go run ./cmd/api -db-dsn=${GREENLIGHT_DB_DSN}
## db/psql: connect to the database using psql
.PHONY: db/psql
db/psql:
	psql ${GREENLIGHT_DB_DSN}
## db/migrations/new name=$1: create a new database migration
.PHONY: db/migrations/new
db/migrations/new:
	@echo 'Creating migrations...'
	migrate create -seq -ext .sql -dir ./migrations ${name}
## db/migrations/up: apply all up database migrations
.PHONY: db/migrations/up
db/migrations/up:
	@echo 'Running up migrations...'
	migrate -path ./migrations -database ${GREENLIGHT_DB_DSN} up
# ==================================================================================== #
# QUALITY CONTROL
# ==================================================================================== #

## audit: tidy dependencies and format, vet and test all code
.PHONY: audit
audit: vendor
	@echo "Formatting code"
	go fmt ./...
	@echo "Vetting code"
	go vet ./...
	staticcheck ./...
	@echo "Running tests"
	go test -race -vet=off ./...
.PHONY: vendor
vendor:
	@echo 'Tidying and verifying module dependencies...'
	go mod tidy
	go mod verify
	@echo "Vendoring dependencies"
	go mod vendor
# ==================================================================================== #
# BUILD
# ==================================================================================== #


## build/api: build the cmd/api application
current_time = $(shell echo %date%-%TIME%)
linker_flags = '-s -X main.buildTime=${current_time} -X main.version=${git_description}'
git_description = $(shell git describe --always --dirty --tags --long)
.PHONY: buil/api
build/api:
	@echo "Building cmd/api..."
	go build -ldflags=${linker_flags} -o=./bin/api.exe ./cmd/api