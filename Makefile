
ifeq ($(OS),Windows_NT)
  SHELL := pwsh.exe
else
  SHELL := pwsh
endif

.SHELLFLAGS := -NoProfile -Command



REGISTRY_NAME := registry.mcd.com
REPOSITORY_NAME := bmcclure89/
IMAGE_NAME := headscale
TAG := :latest

# Run Options
RUN_PORTS := -p 8080:8080 -p 9090:9090
PLATFORMS := linux/amd64,linux/arm64,linux/arm/v7

getcommitid: 
	$(eval COMMITID = $(shell git log -1 --pretty=format:"%H"))
getbranchname:
	$(eval BRANCH_NAME = $(shell (git branch --show-current ) -replace '/','.'))

build: getcommitid getbranchname
	docker build -t $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(TAG) -t $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME):$(BRANCH_NAME) -t $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME):$(BRANCH_NAME)_$(COMMITID) .

build_multiarch:
	docker buildx build -t $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(TAG) --platform $(PLATFORMS) .

run: build
	docker run --name headscale -v ${pwd}/persistent:/persistent -d $(RUN_PORTS) $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(TAG)


package:
	$$PackageFileName = "$$("$(IMAGE_NAME)" -replace "/","_").tar"; docker save $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(TAG) -o $$PackageFileName

size:
	docker inspect -f "{{ .Size }}" $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(TAG)
	docker history $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(TAG)

publish:
	docker login; docker push $(REGISTRY_NAME)$(REPOSITORY_NAME)$(IMAGE_NAME)$(TAG); docker logout

headscale_new_namespace_%:
	docker exec headscale headscale namespace create $*

headscale_register_machine_for_namespace_%:
	docker exec headscale headscale --namespace $* preauthkeys create --reusable --expiration 24h
	echo 'to register a machine with this auth key, run the following: tailscale up --login-server <YOUR_HEADSCALE_URL> --authkey <YOUR_AUTH_KEY>'