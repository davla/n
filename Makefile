PREFIX ?= /usr/local

install: bin/n
	mkdir -p $(PREFIX)/$(dir $<)
	mkdir -p $(PREFIX)/etc
	cp $< $(PREFIX)/$<

uninstall:
	rm -f $(PREFIX)/bin/n

install-test: bin/n-test
	mkdir -p $(PREFIX)/$(dir $<)
	mkdir -p $(PREFIX)/etc
	cp $< $(PREFIX)/$<

uninstall-test:
	rm -f $(PREFIX)/bin/n-test

.PHONY: install uninstall
