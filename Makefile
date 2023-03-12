# all target set in CheckEnvs.makefile
APP_IMAGE="fujisanmagazine/docker-openvpn"

include CheckEnvs.makefile

.PHONY: init

docker_image:
	docker build -t $(APP_IMAGE) .

init: docker_image
	docker volume create --name $(OVPN_DATA)
	docker run -v $(OVPN_DATA):/etc/openvpn --rm $(APP_IMAGE) ovpn_genconfig -u $(OVPN_URL)
	docker run -v $(OVPN_DATA):/etc/openvpn --rm -it $(APP_IMAGE) ovpn_initpki

start:
	docker run -v $(OVPN_DATA):/etc/openvpn -d -p 1194:1194/udp --cap-add=NET_ADMIN $(APP_IMAGE)

genclient:
	docker run -v $(OVPN_DATA):/etc/openvpn --rm -it $(APP_IMAGE) easyrsa build-client-full $(OVPN_CLIENTNAME) nopass

getclient:
	docker run -v $(OVPN_DATA):/etc/openvpn --rm $(APP_IMAGE) ovpn_getclient $(OVPN_CLIENTNAME) > $(OVPN_CLIENTNAME).ovpn
