# defs.mak - Common makefile definitions.
#
# Original author: David Banas
# Original date:   May 9, 2015
#
# Copyright (c) 2015 David Banas; all rights reserved World wide.

# Establish default target.
.PHONY: all clean rebuild
all:

clean:
	@echo "Cleaning up previous build..."
	-rm *.o *.obj *.exp *.lib *.manifest *.dll *.so *.exe 2>/dev/null

rebuild:
	@$(MAKE) clean
	@$(MAKE) all

# Microsoft Visual C++ installation base directories.
# If you did not install MSVC to the default location, or if you're using a
# version other than 2013, you'll need to edit these.
MSVC_BASE       := /cygdrive/c/Program Files (x86)/Microsoft Visual Studio 12.0/VC
MSVC_BASE_DOS   := C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC
MS_SDK_BASE     := /cygdrive/c/Program Files/Microsoft SDKs/Windows/v7.1
MS_SDK_BASE_DOS := C:\Program Files\Microsoft SDKs\Windows\v7.1

# Machine dependent definitions
MACHINE ?= X86
ifeq ($(MACHINE), X86)
    SUFFIX := amd64_x86
else
    ifeq ($(MACHINE), AMD64)
        SUFFIX := amd64
    else
        $(error Unrecognized machine type: $(MACHINE))
    endif
endif

# Handle Windows vs. Linux differences.
OS ?= Linux
ifeq ($(OS), Windows_NT)
    OBJS := $(MODS:%=%_$(SUFFIX).obj)
    ENV_SETTER := $(MSVC_BASE_DOS)\vcvarsall.bat
    RUN_CMD := cmd /C "$(ENV_SETTER)" $(SUFFIX) '&&' 
    CC := cl.exe
    CXX := cl.exe
    LIB := lib.exe
    LD := link.exe
    CFLAGS := /EHsc /Gy /W3 /nologo /c /I. /I"$(IBISAMI_ROOT_DOS)" /I"$(BOOST_ROOT)" /D "WIN32"
    LIBFLAGS = /OUT:$@ /DEF
    LDFLAGS = /INCREMENTAL:NO /NOLOGO /DLL /SUBSYSTEM:WINDOWS /OUT:$@
    ifeq ($(MACHINE), X86)
        LDFLAGS += /MACHINE:X86
    else
        LDFLAGS += /MACHINE:X64
    endif
    ifdef DEBUG
        CFLAGS += /Zi /Od /MTd /D "DEBUG"
        LDFLAGS += /DEBUG
    else
        CFLAGS += /Oi /MT /O2 /D "NDEBUG"
    endif
    CXXFLAGS = $(CFLAGS)
    LDLIBS := kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib \
	      oleaut32.lib uuid.lib odbc32.lib dbccp32.lib
    IBISAMI_LIB := ibisami.lib
else
    ifeq ($(OS), Linux)
        OBJS = $(MODS:%=%_$(SUFFIX).o)
        RUN_CMD =
        BIN := /usr/bin
        CC := gcc
        CXX := g++
        LIB := $(CXX)
        LD := $(CXX)
        CFLAGS := -c -fPIC -I. -std=gnu++11
        LDFLAGS = -o $@ -shared
        ifeq ($(MACHINE), X86)
            LDFLAGS += -m32
            CFLAGS += -m32
        else
            LDFLAGS += -m64
            CFLAGS += -m64
        endif
        ifdef DEBUG
            CFLAGS += -g
            LDFLAGS += -g
        else
            LDFLAGS += -s -static-libgcc -static-libstdc++
        endif
        CXXFLAGS := $(CFLAGS)
        IBISAMI_LIB := libibisami.a
    else
        $(error Unsupported OS: $(OS))
    endif
endif

# Default rules
LIN_CMD = $(RUN_CMD) $(CXX) $(CPPFLAGS) $(CXXFLAGS) $< -o $@
%_$(SUFFIX).o : $(SRCDIR)/%.cc
	$(LIN_CMD)
%_$(SUFFIX).o : $(SRCDIR)/%.cpp
	$(LIN_CMD)
%_$(SUFFIX).o : $(SRCDIR)/%.cxx
	$(LIN_CMD)

%_$(SUFFIX).o : $(SRCDIR)/%.c
	$(RUN_CMD) $(CC) $(CPPFLAGS) $(CFLAGS) $< -o $@

WIN_CMD = $(RUN_CMD) $(CXX) $(CPPFLAGS) $(CXXFLAGS) $< /Fo$@
%_$(SUFFIX).obj : $(SRCDIR)/%.cc
	$(WIN_CMD)
%_$(SUFFIX).obj : $(SRCDIR)/%.cpp
	$(WIN_CMD)
%_$(SUFFIX).obj : $(SRCDIR)/%.cxx
	$(WIN_CMD)

%_$(SUFFIX).obj : $(SRCDIR)/%.c
	$(RUN_CMD) $(CC) $(CPPFLAGS) $(CFLAGS) $< /Fo$@

# Establish object file dependency on include files.
$(OBJS): $(INCS:%=$(INCDIR)/%)
