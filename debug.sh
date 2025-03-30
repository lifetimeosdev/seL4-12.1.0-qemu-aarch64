#!/bin/bash

qemu-system-x86_64  -cpu Nehalem,-vme,+pdpe1gb,-xsave,-xsaveopt,-xsavec,-fsgsbase,-invpcid,+syscall,+lm,enforce \
	-nographic -serial mon:stdio -m size=3G  \
	-kernel images/kernel.elf \
	-initrd images/initrd \
	-s -S
