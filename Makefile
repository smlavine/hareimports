.POSIX:
.SUFFIXES:

HARE = hare

all: hareimports

hareimports:
	$(HARE) build $(HAREFLAGS) -o $@

check:
	$(HARE) test

clean:
	rm -f hareimports

.PHONY: all clean hareimports
