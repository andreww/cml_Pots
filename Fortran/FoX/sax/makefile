#
default: install
#
OBJFILES= m_sax_tokenizer.o m_sax_reader.o \
          m_sax_parser.o m_sax_operate.o FoX_sax.o
#
LIBRARY=libFoX_sax.a
INCFLAGS=$(MOD_PREFIX)../objs/finclude
#
#---------NOTHING SHOULD NEED TO BE CHANGED BELOW THIS LINE-----
#
include ../arch.make

# Uncomment one of the following lines for debugging/profiling support
#
#FFLAGS=$(FFLAGS_DEBUG)
#FFLAGS=$(FFLAGS_PROFILE)
#FFLAGS=$(FFLAGS_CHECK)
#
CP=cp -p
install: $(OBJFILES)
	@echo "  ==> Updating $(LIBRARY) with $(OBJFILES)"
	@$(AR) $(ARFLAGS_EXTRA) cru $(LIBRARY) $(OBJFILES)
	@$(RANLIB) $(LIBRARY)
	$(CP) $(LIBRARY) $(LIB_DIR) 
	for i in *.$(MOD_EXT) ; do  \
           $(CP) $$i $(MOD_DIR);done
#
clean:
	rm -f *.o  *.$(MOD_EXT) $(LIBRARY)
# DO NOT DELETE THIS LINE - used by make depend
FoX_sax.o: m_sax_operate.o
m_sax_operate.o: m_sax_parser.o m_sax_reader.o m_sax_types.o
m_sax_parser.o: m_sax_reader.o m_sax_tokenizer.o m_sax_types.o
m_sax_tokenizer.o: m_sax_reader.o m_sax_types.o
m_sax_types.o: m_sax_reader.o
