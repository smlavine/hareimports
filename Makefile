.POSIX:

include config.mk

NAME = hareimports
SRC = editing.ha main.ha

all: $(NAME)

$(NAME): $(SRC)
	$(HARE) build $(HAREFLAGS) -o $(NAME)

check:
	$(HARE) test

install: $(NAME)
	cp $(NAME) $(DESTDIR)$(PREFIX)/bin

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/$(NAME)

clean:
	rm -f $(NAME)

.PHONY: all check clean install uninstall
