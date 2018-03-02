FRAMAC_SHARE := $(shell frama-c-config -print-share-path)
FRAMAC_LIBDIR := $(shell frama-c-config -print-libpath)
PLUGIN_NAME := Forgetful
PLUGIN_CMO := options helper visit forgetful_plugin
PLUGIN_DEPENDENCIES := Value
include $(FRAMAC_SHARE)/Makefile.dynamic
