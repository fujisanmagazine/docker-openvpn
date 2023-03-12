# load vars from .env if it exists
ifneq ($(wildcard .env), "")
include .env
export
endif

ifeq (,$(OVPN_ENV))
MISSING_VAR=$(MISSING_VARS)" OVPN_ENV"
endif

ifeq (,$(OVPN_URL))
MISSING_VAR="$(MISSING_VARS) OVPN_URL"
endif

ifeq (,$(OVPN_CLIENTNAME))
MISSING_VAR="$(MISSING_VARS) OVPN_CLIENTNAME"
endif

ifneq (, $(MISSING_VAR))
$(info $(MISSING_VAR) not set)
all:
else
# setup env vars
OVPN_DATA="ovpn-data-$(OVPN_ENV)"

all: init
endif

