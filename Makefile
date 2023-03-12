# load vars from .env if it exists
ifneq ($(wildcard .env), "")
include .env
export
endif

APP_IMAGE="fujisanmagazine/docker-openvpn"
# TODO: handle shared network drive scenario
OVPN_DATA="ovpn-data-officemx"

.PHONY: init start genclient getclient

docker_image:
	docker build -t $(APP_IMAGE) .

init: docker_image
	@if [ "" != "$(OVPN_URL)" ]; then \
		docker volume create --name $(OVPN_DATA) ; \
		docker run -v $(OVPN_DATA):/etc/openvpn --rm $(APP_IMAGE) ovpn_genconfig -u $(OVPN_URL) ; \
		docker run -v $(OVPN_DATA):/etc/openvpn --rm -it $(APP_IMAGE) ovpn_initpki ; \
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