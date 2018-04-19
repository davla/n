PREFIX ?= /usr/local

install: bin/n
	mkdir -p $(PREFIX)/$(dir $<)
	mkdir -p $(PREFIX)/etc
	cp $< $(PREFIX)/$<

uninstall:
	rm -rf $(PREFIX)/n
	rm -f $(PREFIX)/bin/n
	rm -f $(PREFIX)/etc/npmrc

use: bin/n-use.sh
	cp $< ~/.n-use.sh
	echo -e '# n use command\n\nsource ~/.n-use.sh' >> ~/.bashrc

unuse:
	rm ~/.n-use.sh
	sed -i -E '/n(-| )use/d' ~/.bashrc

test: bin/n-test
	mkdir -p $(PREFIX)/$(dir $<)
	mkdir -p $(PREFIX)/etc
	ln -s $(PWD)/$< $(PREFIX)/$<

untest:
	rm -rf $(PREFIX)/n-test
	rm -f $(PREFIX)/bin/n-test
	rm -f $(PREFIX)/etc/npmrc

.PHONY: install uninstall use unuse test untest
