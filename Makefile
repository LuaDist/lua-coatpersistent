
LUA     := lua
VERSION := $(shell cd src && $(LUA) -e "require [[Coat.Persistent]]; print(Coat.Persistent._VERSION)")
TARBALL := lua-coatpersistent-$(VERSION).tar.gz
ifndef REV
  REV   := 1
endif

ifndef DESTDIR
  DESTDIR := /usr/local
endif
LIBDIR  := $(DESTDIR)/share/lua/5.1

install:
	mkdir -p $(LIBDIR)/Coat/Persistent
	cp src/Coat/Persistent.lua      $(LIBDIR)/Coat
	cp src/Coat/Persistent/Meta.lua $(LIBDIR)/Coat/Persistent

uninstall:
	rm -f $(LIBDIR)/Coat/Persistent.lua
	rm -f $(LIBDIR)/Coat/Persistent/Meta.lua

manifest_pl := \
use strict; \
use warnings; \
my @files = qw{MANIFEST}; \
while (<>) { \
    chomp; \
    next if m{^\.}; \
    next if m{^doc/\.}; \
    next if m{^doc/google}; \
    next if m{^rockspec/}; \
    push @files, $$_; \
} \
print join qq{\n}, sort @files;

rockspec_pl := \
use strict; \
use warnings; \
use Digest::MD5; \
open my $$FH, q{<}, q{$(TARBALL)} \
    or die qq{Cannot open $(TARBALL) ($$!)}; \
binmode $$FH; \
my %config = ( \
    version => q{$(VERSION)}, \
    rev     => q{$(REV)}, \
    md5     => Digest::MD5->new->addfile($$FH)->hexdigest(), \
); \
close $$FH; \
while (<>) { \
    s{@(\w+)@}{$$config{$$1}}g; \
    print; \
}

version:
	@echo $(VERSION)

CHANGES:
	perl -i.bak -pe "s{^$(VERSION).*}{q{$(VERSION)  }.localtime()}e" CHANGES

tag:
	git tag -a -m 'tag release $(VERSION)' $(VERSION)

doc:
	git read-tree --prefix=doc/ -u remotes/origin/gh-pages

MANIFEST: doc
	git ls-files | perl -e '$(manifest_pl)' > MANIFEST

$(TARBALL): MANIFEST
	[ -d lua-CoatPersistent-$(VERSION) ] || ln -s . lua-CoatPersistent-$(VERSION)
	perl -ne 'print qq{lua-CoatPersistent-$(VERSION)/$$_};' MANIFEST | \
	    tar -zc -T - -f $(TARBALL)
	rm lua-CoatPersistent-$(VERSION)
	rm -rf doc
	git rm doc/*

dist: $(TARBALL)

rockspec: $(TARBALL)
	perl -e '$(rockspec_pl)' rockspec.in > rockspec/lua-coatpersistent-$(VERSION)-$(REV).rockspec

install-rock: clean dist rockspec
	perl -pe 's{http://cloud.github.com/downloads/fperrad/lua-CoatPersistent/}{};' \
	    rockspec/lua-coatpersistent-$(VERSION)-$(REV).rockspec > lua-coatpersistent-$(VERSION)-$(REV).rockspec
	luarocks install lua-coatpersistent-$(VERSION)-$(REV).rockspec

ifdef LUA_PATH
  export LUA_PATH:=$(LUA_PATH);../test/?.lua
else
  export LUA_PATH=;;../test/?.lua
endif
#export GEN_PNG=1

check: test

test:
	cd src && prove --exec=$(LUA) ../test/*.t

coverage:
	rm -f src/luacov.stats.out src/luacov.report.out
	cd src && prove --exec="$(LUA) -lluacov" ../test/*.t
	cd src && luacov

clean:
	rm -rf doc
	rm -f MANIFEST *.bak *.db src/luacov.*.out src/*.db src/*.png test/*.png *.rockspec

.PHONY: test rockspec CHANGES

