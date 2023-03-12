# load vars from .env if it exists
ifneq ($(wildcard .env), "")
include .env
export
endif

APP_IMAGE="fujisanmagazine/docker-openvpn"

# check required vars
ifeq (,$(OVPN_ENV))
MISSING_VAR=$(MISSING_VARS)" OVPN_ENV"
endif

ifeq (,$(OVPN_URL))
MISSING_VAR="$(MISSING_VARS) OVPN_URL"
endif

ifneq (, $(MISSING_VAR))
$(info $(MISSING_VAR) not set)
all:
else
# setup env vars
OVPN_DATA="ovpn-data-$(OVPN_ENV)"

all:
endif

.PHONY: init start genclient getclient

docker_image:
	docker build -t $(APP_IMAGE) .

init: docker_image
	# TODO: handle shared network drive scenario
	docker volume create --name $(OVPN_DATA)
	docker run -v $(OVPN_DATA):/etc/openvpn --rm $(APP_IMAGE) ovpn_genconfig -u $(OVPN_URL)
	docker run -v $(OVPN_DATA):/etc/openvpn --rm -it $(APP_IMAGE) ovpn_initpki

start:
	docker run -v $(OVPN_DATA):/etc/openvpn -d -p 1194:1194/udp --cap-add=NET_ADMIN $(APP_IMAGE)

genclient:
	@if [ "" != "$(OVPN_CLIENTNAME)" ]; then \
		docker run -v $(OVPN_DATA):/etc/openvpn --rm -it $(APP_IMAGE) easyrsa build-client-full $(OVPN_CLIENTNAME) nopass ;\
	else \
		echo "OVPN_CLIENTNAME not set" ; \
	 fi

getclient:
	@if [ "" != "$(OVPN_CLIENTNAME)" ]; then \
		docker run -v $(OVPN_DATA):/etc/openvpn --rm $(APP_IMAGE) ovpn_getclient $(OVPN_CLIENTNAME) > $(OVPN_CLIENTNAME).ovpn ;\
	else \
		echo "OVPN_CLIENTNAME not set" ; \
	 fi