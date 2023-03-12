# load vars from .env if it exists
ifneq ($(wildcard .env), "")
include .env
export
endif

# setup variables
APP_IMAGE="fujisanmagazine/docker-openvpn"

ifeq ($(OVPN_ENV), "")
OVPN_ENV="local"
endif

# load vars from conf if it exists
# from: https://stackoverflow.com/posts/73509979/edit
ROOT_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

ifneq ($(wildcard conf/$(OVPN_ENV).conf), "")
include $(ROOTDIR)/conf/$(OVPN_ENV).conf
export
endif

# TODO: handle shared network drive scenario
OVPN_DATA="ovpn-data-$(OVPN_ENV)"

.PHONY: init start genclient getclient

docker_image:
	docker build -t $(APP_IMAGE) .

init: docker_image
	@if [ "" != "$(OVPN_URL)" ]; then \
		docker volume create --name $(OVPN_DATA) ; \
		docker run -v $(OVPN_DATA):/etc/openvpn --rm $(APP_IMAGE) ovpn_genconfig $(OVPN_SERVERCONFIG) -u $(OVPN_URL) ; \
		docker run -v $(OVPN_DATA):/etc/openvpn --rm -it $(APP_IMAGE) ovpn_initpki ; \
	else \
		echo "OVPN_URL not set" ; \
	fi

update_config:
	@if [ "" != "$(OVPN_URL)" ]; then \
		docker run -v $(OVPN_DATA):/etc/openvpn --rm $(APP_IMAGE) ovpn_genconfig $(OVPN_SERVERCONFIG) -u $(OVPN_URL) ; \
	else \
		echo "OVPN_URL not set" ; \
	fi

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

debug:
	docker run  -v $(OVPN_DATA):/etc/openvpn --rm -it $(APP_IMAGE) bash -l