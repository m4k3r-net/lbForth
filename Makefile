TARGET = c
TDIR = targets/$(TARGET)
TMAKE = $(MAKE) -f$(TDIR)/forth.mk
FORTH = $(TDIR)/run.sh ./forth
DEPS = kernel.fth dictionary.fth $(TDIR)/nucleus.fth

GREP = grep -a
ERROR_PATTERNS = -e 'INCORRECT RESULT' -e 'WRONG NUMBER'
EXPECTED_ERRORS = 77


all: forth

forth: .bootstrap $(DEPS)
	$(TMAKE) $@ DEPS="$(DEPS)"

.bootstrap:
	$(MAKE) -ftargets/c/bootstrap.mk
	touch .bootstrap


check: test-errors test-assembler test-image test-exe test-lib
	test `cat $<` -eq $(EXPECTED_ERRORS)

test-errors: test-output
	$(GREP) $(ERROR_PATTERNS) $< | wc -l > $@

test-output: test/test-input smoke-test
	$(FORTH) < $< > $@
	$(GREP) Test-OK $@

test-assembler: test/test-asm.fth targets/x86/asm.fth forth
	echo 'include $< .( Asm-OK )' | $(FORTH) > $@
	$(GREP) Asm-OK $@

smoke-test: forth
	echo 'words cr .( Smoke-OK )' | $(FORTH) > $@
	$(GREP) Smoke-OK $@

test-image: test/test-image.fth lib/image.fth
	echo 'include $< .( Image-OK )' | $(FORTH) > $@
	$(GREP) Image-OK $@

test-exe: test/test-exe.sh test/test-elf.fth test/test-pe.fth targets/x86/asm.fth
	TDIR=$(TDIR) ./test/test-exe.sh > $@
	$(GREP) 42 $@

test-lib: test/test-lib.sh
	sh test/test-lib.sh

test-meta: targets/x86/meta.fth targets/x86/nucleus.fth kernel.fth
	echo 'include $<' | $(FORTH) | tail -n+3 > $@
	chmod a+x $@

clean:
	$(TMAKE) clean
	rm -f .bootstrap smoke-test test-*
