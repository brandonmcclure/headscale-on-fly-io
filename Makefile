ifeq ($(OS),Windows_NT)
	SHELL := pwsh.exe
else
	SHELL := pwsh
endif

.SHELLFLAGS := -NoProfile -Command

getcommitid: 
	$(eval COMMITID = $(shell git log -1 --pretty=format:"%H"))
getbranchname:
	$(eval BRANCH_NAME = $(shell (git branch --show-current ) -replace '/','.'))


.PHONY: all clean test act
all: test

REGISTRY_NAME := registry.mcd.com
REPOSITORY_NAME := bmcclure89/
IMAGE_NAME := headscale
TAG := :latest
FLY_LOGLEVEL := LOG_LEVEL=debug 
FLY_API_TOKEN := secret
FLY_APP_NAME :=  headscale
FLY_ORG_NAME := personal
FLY_REGION := den

# Run Options
RUN_PORTS := -p 8086:8080 -p 9090:9090

build: getcommitid getbranchname
	docker build -t $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(TAG) -t $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME):$(BRANCH_NAME) -t $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME):$(BRANCH_NAME)_$(COMMITID) .


run: build
	docker run -d $(RUN_PORTS) $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(TAG)

run_it:
	docker run -it $(RUN_PORTS) $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(TAG)

package:
	$$PackageFileName = "$$("$(IMAGE_NAME)" -replace "/","_").tar"; docker save $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(TAG) -o $$PackageFileName

size:
	docker inspect -f "{{ .Size }}" $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(TAG)
	docker history $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(TAG)

publish:
	docker login; docker push $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(TAG); docker logout
# Act/github workflows
ACT_ARTIFACT_PATH := /workspace/.act 
act: 

fly_create:
	-fly apps create $(FLY_APP_NAME) -o $(FLY_ORG_NAME)
	#flyctl volumes create persistent --size 1 --region ${FLY_REGION}
fly_deploy: build_variable_substition_for_toml fly_create
	fly deploy

set_env := [System.Environment]::SetEnvironmentVariable('FLY_API_TOKEN','$(FLY_API_TOKEN)'),[System.Environment]::SetEnvironmentVariable('FLY_REGION','$(FLY_REGION)'),[System.Environment]::SetEnvironmentVariable('FLY_APP_NAME','$(FLY_APP_NAME)');
build_variable_substition_for_toml:
	$(set_env) Get-Content fly.template.toml | envsubst | tee fly.toml