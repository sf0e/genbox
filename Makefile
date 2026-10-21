# genbox ISO build
#
# Targets:
#   make stage3     download + extract the Gentoo stage3
#   make rootfs     build the genbox root filesystem (chroot emerge)
#   make initramfs  build the BusyBox initramfs
#   make iso        assemble dist/genbox.iso
#   make test       boot dist/genbox.iso in QEMU
#   make check      run the test suite
#   make clean      remove build artifacts
#
# Everything is configurable from the command line, e.g.
#   make iso STAGE3_URL=... JOBS=8

SHELL := /bin/bash
.DEFAULT_GOAL := iso

# --- configuration -----------------------------------------------------------

ARCH            ?= amd64
STAGE3_DATE     ?= 20261018T124555Z
STAGE3_BUILD    ?= stage3-amd64-openrc-$(STAGE3_DATE)
STAGE3_URL      ?= https://distfiles.gentoo.org/releases/amd64/autobuilds/$(STAGE3_DATE)/$(STAGE3_BUILD).tar.xz
JOBS            ?= $(shell nproc)
# live environment kernel: "source" (sys-kernel/gentoo-kernel) or
# "bin" (sys-kernel/gentoo-kernel-bin, much faster to build)
LIVE_KERNEL     ?= source
DIST            ?= dist
BUILD           ?= build

# --- derived paths -----------------------------------------------------------

ROOT            := $(BUILD)/rootfs
STAGE3_TARBALL  := $(BUILD)/stage3.tar.xz
INITRAMFS       := $(BUILD)/initramfs.cpio.gz
ISO             := $(DIST)/genbox.iso

# --- phony -------------------------------------------------------------------

.PHONY: all iso stage3 rootfs initramfs test check checksums clean distclean help

all: iso

iso: $(ISO)

help:
	@echo "genbox build targets:"
	@echo "  stage3     download and extract the stage3"
	@echo "  rootfs     build the genbox root filesystem"
	@echo "  initramfs  build the BusyBox initramfs"
	@echo "  iso        assemble $(ISO)"
	@echo "  test       boot $(ISO) in QEMU"
	@echo "  check      run tests"
	@echo "  checksums  write $(ISO).sha256"
	@echo "  clean      remove $(BUILD) and $(DIST)"

# --- stage3 ------------------------------------------------------------------

stage3: $(STAGE3_TARBALL)

$(STAGE3_TARBALL):
	@scripts/fetch-stage3.sh "$(STAGE3_URL)" "$@"

# --- rootfs ------------------------------------------------------------------

rootfs: $(ROOT)/.built

$(ROOT)/.built: $(STAGE3_TARBALL)
	sudo GENBOX_REUSE_ROOTFS="$${GENBOX_REUSE_ROOTFS:-0}" scripts/build-rootfs.sh "$(STAGE3_TARBALL)" "$(ROOT)" "$(CURDIR)" "$(JOBS)" "$(LIVE_KERNEL)"

# --- initramfs ---------------------------------------------------------------

initramfs: $(INITRAMFS)

$(INITRAMFS): $(ROOT)/.built
	sudo scripts/build-initramfs.sh "$(ROOT)" "$@"

# --- iso ---------------------------------------------------------------------

$(ISO): $(ROOT)/.built $(INITRAMFS)
	sudo scripts/build-iso.sh "$(ROOT)" "$(INITRAMFS)" "$@" "$(CURDIR)"

# --- test --------------------------------------------------------------------

test: $(ISO)
	scripts/test-qemu.sh "$(ISO)"

check:
	tests/run-tests.sh

checksums: $(ISO)
	cd "$(DIST)" && sha256sum "$(notdir $(ISO))" > "$(notdir $(ISO)).sha256"
	@cat "$(DIST)/$(notdir $(ISO)).sha256"

# --- clean -------------------------------------------------------------------

clean:
	-sudo rm -rf "$(BUILD)" "$(DIST)"

distclean: clean
