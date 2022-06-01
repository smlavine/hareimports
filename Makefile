.POSIX:
.SUFFIXES:

HARE = hare

MODULE = cmd/hareimports/

all: hareimports

hareimports: $(SRC)
	$(HARE) build $(HAREFLAGS) -o $@ $(MODULE)

check:
	$(HARE) test $(MODULE)

clean:
	rm -f hareimports

.PHONY: all check clean
