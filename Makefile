.POSIX:
.SUFFIXES:

HARE = hare

SRC = editing.ha main.ha

all: hareimports

hareimports: $(SRC)
	$(HARE) build $(HAREFLAGS) -o $@

test:
	$(HARE) test

clean:
	rm -f hareimports

.PHONY: all clean test
