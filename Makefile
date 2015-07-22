##
## JIRA Service Desk
##
JIRA_VERSION:=6.4.8
JIRA_TARBALL:=atlassian-jira-$(JIRA_VERSION).tar.gz
JIRA_LOCATION:=https://www.atlassian.com/software/jira/downloads/binary
JIRA_ROOT:=atlassian-jira-standalone
DOCKER_TAG:=tekii/jira-service-desk:$(JIRA_VERSION)
##
## M4
##
M4= $(shell which m4)
M4_FLAGS= -P \
	-D __JIRA_VERSION__=$(JIRA_VERSION) \
	-D __JIRA_ROOT__=$(JIRA_ROOT) \
	-D __DOCKER_TAG__=$(DOCKER_TAG)

$(JIRA_TARBALL):
	wget $(JIRA_LOCATION)/$(JIRA_TARBALL)
#	md5sum --check $(JDK_TARBALL).md5

$(JIRA_ROOT): $(JIRA_TARBALL) config.patch
	mkdir -p $@
	tar zxvf $(JIRA_TARBALL) -C $@ --strip-components=1
	patch -p0 -i config.patch

#.SECONDARY
Dockerfile: Dockerfile.m4 Makefile
	$(M4) $(M4_FLAGS) $< >$@


PHONY += update-patch
update-patch:
	diff -ruN $(JIRA_ROOT)/ aux/ > config.patch

PHONY += image
image: $(JIRA_TARBALL) Dockerfile $(JIRA_ROOT)
	docker build -t $(DOCKER_TAG) .

PHONY+= run
run: image
	docker run -p 8080:8080  -v $(shell pwd)/volume:/home/jira $(DOCKER_TAG)

PHONY+= push-to-docker
push-to-docker: image
	docker push $(DOCKER_TAG)

PHONY += push-to-google
push-to-google: image
	docker tag $(DOCKER_TAG) gcr.io/test-teky/jira-service-desk:$(JIRA_VERSION)
	gcloud docker push gcr.io/test-teky/jira-service-desk:$(JIRA_VERSION)

PHONY += clean
clean:
	rm -f $(JIRA_TARBALL)

PHONY += realclean
realclean: clean
	rm -f Dokerfile

PHONY += all
all: $(JDK_TARBALL)

.PHONY: $(PHONY)
.DEFAULT_GOAL := all