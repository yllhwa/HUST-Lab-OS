#!/bin/bash

obj-m += main.o

KDIR := /usr/src/linux-headers-5.4.0-113

PWD ?= $(shell pwd)

all:
	make -C $(KDIR) M=$(PWD) modules

clean:
	make -C $(KDIR) M=$(PWD) clean
