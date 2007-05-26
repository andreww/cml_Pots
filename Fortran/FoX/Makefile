#!/bin/make
#
default: objsdir wxml_lib wcml_lib sax_lib examples_build
	touch .FoX
#
objsdir:
	mkdir -p objs/lib objs/finclude
#
examples_build:
	(cd examples; make)
#
check: dom_check sax_check wxml_check wcml_check
#
include arch.make
#---------------------------
INCFLAGS=-Iobjs/finclude
#
#
#
dom_lib: sax_lib wxml_lib
	(cd dom; $(MAKE))
dom_lib_clean:
	(cd dom; $(MAKE) clean)
#
sax_lib: common_lib fsys_lib
	(cd sax; $(MAKE))
sax_lib_clean:
	(cd sax; $(MAKE) clean)
#
wxml_lib: common_lib fsys_lib 
	(cd wxml; $(MAKE))
wxml_lib_clean:
	(cd wxml; $(MAKE) clean)
#
wcml_lib: wxml_lib
	(cd wcml; $(MAKE))
wcml_lib_clean: 
	(cd wcml; $(MAKE) clean)
#
common_lib: fsys_lib
	(cd common; $(MAKE))
common_lib_clean:
	(cd common; $(MAKE) clean)
#
fsys_lib: objsdir
	(cd fsys; $(MAKE))
fsys_lib_clean:
	(cd fsys; $(MAKE) clean)
#
dom_example: dom_lib dom_example.o
	$(FC) -o $@ dom_example.o $$(./FoX-config --libs --dom)
#
sax_example.o: m_handlers.o
sax_example: sax_lib m_handlers.o sax_example.o
	$(FC) -o $@ sax_example.o m_handlers.o $$(./FoX-config --libs --sax)
#
wxml_example: wxml_lib wxml_example.o 
	$(FC) -o $@ wxml_example.o $$(./FoX-config --libs --wxml)
#
wcml_example: wcml_lib wcml_example.o 
	$(FC) -o $@ wcml_example.o $$(./FoX-config --libs --wcml)
#
common_check:
	(cd common/test;./run_tests.sh)
dom_check:
sax_check:
wcml_check:
	(cd wcml/test;./run_tests.sh)
wxml_check:
	(cd wxml/test;./run_tests.sh)
check: common_check wxml_check wcml_check sax_check dom_check

DoX:
	(cd DoX; make)

clean: wxml_lib_clean wcml_lib_clean common_lib_clean fsys_lib_clean sax_lib_clean
	(cd examples;make clean)
	rm -f objs/lib/* objs/finclude/* .FoX

distclean: clean
	rm -f FoX-config arch.make config.log config.status .config
# DO NOT DELETE THIS LINE - used by make depend
sax_example.o: m_handlers.o
