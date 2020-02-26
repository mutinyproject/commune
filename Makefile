name = commune
version = 20200226

prefix ?=
bindir ?= $(prefix)/bin
libdir ?= $(prefix)/lib
localstatedir ?= $(prefix)/var

libdir := $(libdir)/$(name)

BINS := $(patsubst %.in, %, $(wildcard bin/*.in))
LIBS := $(patsubst %.in, %, $(wildcard lib/*.in))
MANS := $(patsubst %.adoc, %, $(wildcard man/*.adoc))
HTMLS := $(patsubst %.adoc, %.html, $(wildcard man/*.adoc))

INSTALLS := \
	$(addprefix $(DESTDIR)$(bindir)/,$(BINS:bin/%=%)) \
	$(addprefix $(DESTDIR)$(libdir)/,$(LIBS:lib/%=%))

.PHONY: all
all: bin lib man html

.PHONY: clean
clean:
	rm -f $(BINS) $(LIBS) $(MANS) $(HTMLS)

.PHONY: install
install: $(INSTALLS)

.PHONY: lint
lint:
	printf '%s\n' $(patsubst %,%.in,$(BINS)) $(patsubst %,%.in,$(LIBS)) | xargs shellcheck

.PHONY: test
test: check

.PHONY: check
check: bin lib
	shellspec $(SHELLSPEC_FLAGS)

.PHONY: maint
maint: lint check

.PHONY: bin
bin: $(BINS)

.PHONY: lib
lib: $(LIBS)

.PHONY: man
man: $(MANS)

.PHONY: html
html: $(HTMLS)

bin/%: bin/%.in
	sed \
		-e "s|@@name@@|$(name)|g" \
		-e "s|@@version@@|$(version)|g" \
		-e "s|@@prefix@@|$(prefix)|g" \
		-e "s|@@bindir@@|$(bindir)|g" \
		-e "s|@@libdir@@|$$\{PRAXIS_LIBDIR:-$(libdir)\}|g" \
		-e "s|@@localstatedir@@|$(localstatedir)|g" \
		$< > $@.temp
	chmod +x $@.temp
	mv $@.temp $@

lib/%: lib/%.in
	sed \
		-e "s|@@name@@|$(name)|g" \
		-e "s|@@version@@|$(version)|g" \
		-e "s|@@prefix@@|$(prefix)|g" \
		-e "s|@@bindir@@|$(bindir)|g" \
		-e "s|@@libdir@@|$$\{PRAXIS_LIBDIR:-$(libdir)\}|g" \
		-e "s|@@localstatedir@@|$(localstatedir)|g" \
		$< > $@.temp
	chmod +x $@.temp
	mv $@.temp $@

.DELETE_ON_ERROR: man/%.html
man/%.html: man/%.adoc
	asciidoctor --failure-level=WARNING -b html5 -B $(PWD) -o $@ $<

.DELETE_ON_ERROR: man/%
man/%: man/%.adoc
	asciidoctor --failure-level=WARNING -b manpage -B $(PWD) -d manpage -o $@ $<

$(DESTDIR)$(bindir)/%: bin/%
	install -D $< $@

$(DESTDIR)$(libdir)/%: lib/%
	install -D -m 0644 $< $@

