.PHONY: all check munge full sans lgc ttf full-ttf full-web full-woff full-svg full-eot sans-ttf lgc-ttf status dist src-dist ttf-dist sans-dist lgc-dist norm check-harder pre-patch clean

# Release version
VERSION = 0.1
# Snapshot version
SNAPSHOT = dev
# Initial source directory, assumed read-only
SRCDIR  = src
# Directory where temporary files live
TMPDIR  = tmp
# Directory where final files are created
BUILDDIR  = build
# Directory where final archives are created
DISTDIR = dist
# What is a Python?
PYTHON = python3.2

# Release layout
FONTCONFDIR = fontconfig
DOCDIR = .
SCRIPTSDIR = scripts
TTFDIR = ttf
RESOURCEDIR = resources

ifeq "$(SNAPSHOT)" ""
ARCHIVEVER = $(VERSION)
else
ARCHIVEVER = $(VERSION)-$(SNAPSHOT)
endif

SRCARCHIVE  = gehen-fonts-$(ARCHIVEVER)
WEBARCHIVE  = gehen-fonts-web-$(ARCHIVEVER)
TTFARCHIVE  = gehen-fonts-ttf-$(ARCHIVEVER)
SANSARCHIVE = gehen-sans-ttf-$(ARCHIVEVER)
LGCARCHIVE  = gehen-lgc-fonts-ttf-$(ARCHIVEVER)

ARCHIVEEXT = .zip .tar.bz2
SUMEXT     = .zip.md5 .tar.bz2.md5 .tar.bz2.sha512

OLDSTATUS    = $(DOCDIR)/status.txt
BLOCKS       = $(RESOURCEDIR)/Blocks.txt
UNICODEDATA  = $(RESOURCEDIR)/UnicodeData.txt
FC-LANG      = $(RESOURCEDIR)/fc-lang

GENERATE     = $(SCRIPTSDIR)/generate.pe
TTPOSTPROC   = $(SCRIPTSDIR)/ttpostproc.pl
LGC          = $(SCRIPTSDIR)/lgc.pe
UNICOVER     = $(SCRIPTSDIR)/unicover.pl
LANGCOVER    = $(SCRIPTSDIR)/langcover.pl
STATUS	     = $(SCRIPTSDIR)/status.pl
PROBLEMS     = $(SCRIPTSDIR)/problems.pl
NORMALIZE    = $(SCRIPTSDIR)/sfdnormalize.pl
NARROW       = $(SCRIPTSDIR)/narrow.pe

SRC      := $(wildcard $(SRCDIR)/*.sfd)
SFDFILES := $(patsubst $(SRCDIR)/%, %, $(SRC))
FULLSFD  := $(patsubst $(SRCDIR)/%.sfd, $(TMPDIR)/%.sfd, $(SRC))
NORMSFD  := $(patsubst %, %.norm, $(FULLSFD))
LGCSFD   := $(patsubst $(SRCDIR)/Gehen%.sfd, $(TMPDIR)/GehenLGC%.sfd, $(SRC))
FULLTTF  := $(patsubst $(TMPDIR)/%.sfd, $(BUILDDIR)/%.ttf, $(FULLSFD))
LGCTTF   := $(patsubst $(TMPDIR)/%.sfd, $(BUILDDIR)/%.ttf, $(LGCSFD))
FULLWOFF := $(patsubst $(BUILDDIR)/%.ttf, $(BUILDDIR)/%.woff, $(wildcard $(BUILDDIR)/*.ttf))
FULLSVG  := $(patsubst $(BUILDDIR)/%.ttf, $(BUILDDIR)/%.svg, $(wildcard $(BUILDDIR)/*.ttf))
FULLEOT  := $(patsubst $(BUILDDIR)/%.ttf, $(BUILDDIR)/%.eot, $(wildcard $(BUILDDIR)/*.ttf))

FONTCONF     := $(wildcard $(FONTCONFDIR)/*.conf)
FONTCONFLGC  := $(wildcard $(FONTCONFDIR)/*lgc*.conf)
FONTCONFFULL := $(filter-out $(FONTCONFLGC), $(FONTCONF))

STATICDOC := $(addprefix $(DOCDIR)/, AUTHORS BUGS LICENSE NEWS README)
STATICSRCDOC := $(addprefix $(DOCDIR)/, BUILDING)
GENDOCFULL = unicover.txt langcover.txt status.txt
GENDOCSANS = unicover-sans.txt langcover-sans.txt
GENDOCLGC  = unicover-lgc.txt langcover-lgc.txt

all : full sans lgc

$(TMPDIR)/%.sfd: $(SRCDIR)/%.sfd
	@echo "[1] $< => $@"
	install -d $(dir $@)
	sed "s@\(Version:\? \)\(0\.[0-9]\+\.[0-9]\+\|[1-9][0-9]*\.[0-9]\+\)@\1$(VERSION)@" $< > $@
	touch -r $< $@

$(TMPDIR)/GehenLGC%.sfd: $(TMPDIR)/Gehen%.sfd
	@echo "[2] $< => $@"
	sed -e 's,FontName: Gehen,FontName: GehenLGC,'\
	    -e 's,FullName: Gehen,FullName: Gehen LGC,'\
	    -e 's,FamilyName: Gehen,FamilyName: Gehen LGC,'\
            -e 's,"Gehen \(\(Sans\|Serif\)*\( Condensed\| Mono\)*\( Bold\)*\( Oblique\|Italic\)*\)","Gehen LGC \1",g' < $< > $@
	@echo "Stripping unwanted glyphs from $@"
	$(LGC) $@
	touch -r $< $@

$(BUILDDIR)/%.ttf: $(TMPDIR)/%.sfd
	@echo "[3] $< => $@"
	install -d $(dir $@)
	$(GENERATE) ttf $<
	mv $<.ttf $@
	$(TTPOSTPROC) $@
	$(RM) $@~
	touch -r $< $@

$(BUILDDIR)/%.woff: $(BUILDDIR)/%.ttf
	@echo "[3] $< => $@"
	$(GENERATE) woff $<
	mv $<.woff $@

$(BUILDDIR)/%.svg: $(BUILDDIR)/%.ttf
	@echo "[3] $< => $@"
	$(GENERATE) svg $<
	mv $<.svg $@

$(BUILDDIR)/%.eot: $(BUILDDIR)/%.ttf
	@echo "[3] $< => $@"
	ttf2eot < $< > $@

$(BUILDDIR)/status.txt: $(FULLSFD)
	@echo "[4] => $@"
	install -d $(dir $@)
	$(STATUS) $(VERSION) $(OLDSTATUS) $(FULLSFD) > $@

$(BUILDDIR)/unicover.txt: $(patsubst %, $(TMPDIR)/%.sfd, GehenSans GehenSerif GehenSansMono)
	@echo "[5] => $@"
	install -d $(dir $@)
	$(UNICOVER) $(UNICODEDATA) $(BLOCKS) \
	            $(TMPDIR)/GehenSans.sfd "Sans" \
	            $(TMPDIR)/GehenSerif.sfd "Serif" \
	            $(TMPDIR)/GehenSansMono.sfd "Sans Mono" > $@

$(BUILDDIR)/unicover-sans.txt: $(TMPDIR)/GehenSans.sfd
	@echo "[5] => $@"
	install -d $(dir $@)
	$(UNICOVER) $(UNICODEDATA) $(BLOCKS) \
	            $(TMPDIR)/GehenSans.sfd "Sans" > $@

$(BUILDDIR)/unicover-lgc.txt: $(patsubst %, $(TMPDIR)/%.sfd, GehenLGCSans GehenLGCSerif GehenLGCSansMono)
	@echo "[5] => $@"
	install -d $(dir $@)
	$(UNICOVER) $(UNICODEDATA) $(BLOCKS) \
	            $(TMPDIR)/GehenLGCSans.sfd "Sans" \
	            $(TMPDIR)/GehenLGCSerif.sfd "Serif" \
	            $(TMPDIR)/GehenLGCSansMono.sfd "Sans Mono" > $@

$(BUILDDIR)/langcover.txt: $(patsubst %, $(TMPDIR)/%.sfd, GehenSans GehenSerif GehenSansMono)
	@echo "[6] => $@"
	install -d $(dir $@)
ifeq "$(FC-LANG)" ""
	touch $@
else
	$(LANGCOVER) $(FC-LANG) \
	             $(TMPDIR)/GehenSans.sfd "Sans" \
	             $(TMPDIR)/GehenSerif.sfd "Serif" \
	             $(TMPDIR)/GehenSansMono.sfd "Sans Mono" > $@
endif

$(BUILDDIR)/langcover-sans.txt: $(TMPDIR)/GehenSans.sfd
	@echo "[6] => $@"
	install -d $(dir $@)
ifeq "$(FC-LANG)" ""
	touch $@
else
	$(LANGCOVER) $(FC-LANG) \
	             $(TMPDIR)/GehenSans.sfd "Sans" > $@
endif

$(BUILDDIR)/langcover-lgc.txt: $(patsubst %, $(TMPDIR)/%.sfd, GehenLGCSans GehenLGCSerif GehenLGCSansMono)
	@echo "[6] => $@"
	install -d $(dir $@)
ifeq "$(FC-LANG)" ""
	touch $@
else
	$(LANGCOVER) $(FC-LANG) \
	             $(TMPDIR)/GehenLGCSans.sfd "Sans" \
	             $(TMPDIR)/GehenLGCSerif.sfd "Serif" \
	             $(TMPDIR)/GehenLGCSansMono.sfd "Sans Mono" > $@
endif

$(BUILDDIR)/Makefile: Makefile
	@echo "[7] => $@"
	install -d $(dir $@)
	sed -e "s+^VERSION\([[:space:]]*\)=\(.*\)+VERSION = $(VERSION)+g"\
	    -e "s+^SNAPSHOT\([[:space:]]*\)=\(.*\)+SNAPSHOT = $(SNAPSHOT)+g" < $< > $@
	touch -r $< $@

$(TMPDIR)/$(SRCARCHIVE): $(addprefix $(BUILDDIR)/, $(GENDOCFULL) Makefile) $(FULLSFD)
	@echo "[8] => $@"
	install -d -m 0755 $@/$(SCRIPTSDIR)
	install -d -m 0755 $@/$(SRCDIR)
	install -d -m 0755 $@/$(FONTCONFDIR)
	install -d -m 0755 $@/$(DOCDIR)
	install -p -m 0644 $(BUILDDIR)/Makefile $@
	install -p -m 0755 $(GENERATE) $(TTPOSTPROC) $(LGC) $(NORMALIZE) \
	                   $(UNICOVER) $(LANGCOVER) $(STATUS) $(PROBLEMS) \
	                   $@/$(SCRIPTSDIR)
	install -p -m 0644 $(FULLSFD) $@/$(SRCDIR)
	install -p -m 0644 $(FONTCONF) $@/$(FONTCONFDIR)
	install -p -m 0644 $(addprefix $(BUILDDIR)/, $(GENDOCFULL)) \
	                   $(STATICDOC) $(STATICSRCDOC) $@/$(DOCDIR)

$(TMPDIR)/$(WEBARCHIVE): web
	@echo "[8] => $@"
	install -d -m 0755 $@/woff
	install -d -m 0755 $@/eot
	install -d -m 0755 $@/svg
	install -d -m 0755 $@/$(DOCDIR)
	install -p -m 0644 $(FULLWOFF) $@/woff
	install -p -m 0644 $(FULLEOT) $@/eot
	install -p -m 0644 $(FULLSVG) $@/svg
	install -p -m 0644 $(addprefix $(BUILDDIR)/, $(GENDOCFULL)) \
	                   $(STATICDOC) $@/$(DOCDIR)

$(TMPDIR)/$(TTFARCHIVE): full
	@echo "[8] => $@"
	install -d -m 0755 $@/$(TTFDIR)
	install -d -m 0755 $@/$(FONTCONFDIR)
	install -d -m 0755 $@/$(DOCDIR)
	install -p -m 0644 $(FULLTTF) $@/$(TTFDIR)
	install -p -m 0644 $(FONTCONFFULL) $@/$(FONTCONFDIR)
	install -p -m 0644 $(addprefix $(BUILDDIR)/, $(GENDOCFULL)) \
	                   $(STATICDOC) $@/$(DOCDIR)

$(TMPDIR)/$(SANSARCHIVE): sans
	@echo "[8] => $@"
	install -d -m 0755 $@/$(TTFDIR)
	install -d -m 0755 $@/$(DOCDIR)
	install -p -m 0644 $(BUILDDIR)/GehenSans.ttf $@/$(TTFDIR)
	install -p -m 0644 $(addprefix $(BUILDDIR)/, $(GENDOCSANS)) \
	                   $(STATICDOC) $@/$(DOCDIR)

$(TMPDIR)/$(LGCARCHIVE): lgc
	@echo "[8] => $@"
	install -d -m 0755 $@/$(TTFDIR)
	install -d -m 0755 $@/$(FONTCONFDIR)
	install -d -m 0755 $@/$(DOCDIR)
	install -p -m 0644 $(LGCTTF) $@/$(TTFDIR)
	install -p -m 0644 $(FONTCONFLGC) $@/$(FONTCONFDIR)
	install -p -m 0644 $(addprefix $(BUILDDIR)/, $(GENDOCLGC)) \
	                   $(STATICDOC) $@/$(DOCDIR)

$(DISTDIR)/%.zip: $(TMPDIR)/%
	@echo "[9] => $@"
	install -d $(dir $@)
	(cd $(TMPDIR); zip -rv $(abspath $@) $(notdir $<))

$(DISTDIR)/%.tar.bz2: $(TMPDIR)/%
	@echo "[9] => $@"
	install -d $(dir $@)
	(cd $(TMPDIR); tar cjvf $(abspath $@) $(notdir $<))

%.md5: %
	@echo "[10] => $@"
	(cd $(dir $<); md5sum -b $(notdir $<) > $(abspath $@))

%.sha512: %
	@echo "[10] => $@"
	(cd $(dir $<); sha512sum -b $(notdir $<) > $(abspath $@))

%.sfd.norm: %.sfd
	@echo "[11] $< => $@"
	$(NORMALIZE) $<
	touch -r $< $@

check : $(NORMSFD)
	for sfd in $^ ; do \
	echo "[12] Checking $$sfd" ;\
	$(PROBLEMS)  $$sfd ;\
	done

munge: $(NORMSFD)
	for sfd in $(SFDFILES) ; do \
	echo "[13] $(TMPDIR)/$$sfd.norm => $(SRCDIR)/$$sfd" ;\
	cp $(TMPDIR)/$$sfd.norm $(SRCDIR)/$$sfd ;\
	done

mono-to-programmer-ttf :
	mkdir -p tmp
	cp src/GehenSansMono.sfd src/GehenSansMono-Programmer.sfd
	patch src/GehenSansMono-Programmer.sfd scripts/mono-to-programmer.patch

full : $(FULLTTF) $(addprefix $(BUILDDIR)/, $(GENDOCFULL))

sans : $(addprefix $(BUILDDIR)/, GehenSans.ttf $(GENDOCSANS))

lgc : $(LGCTTF) $(addprefix $(BUILDDIR)/, $(GENDOCLGC))

ttf : full-ttf sans-ttf lgc-ttf

web : full-web

full-web : full-ttf 
	make full-woff full-svg full-eot web-css

full-ttf : mono-to-programmer-ttf $(FULLTTF)

full-woff : $(FULLWOFF) 

full-svg : $(FULLSVG)

full-eot : $(FULLEOT)

web-css :
	python scripts/make-css.py $(FULLTTF) > $(BUILDDIR)/webfonts.css

sans-ttf: $(BUILDDIR)/GehenSans.ttf

lgc-ttf : $(LGCTTF)

status : $(addprefix $(BUILDDIR)/, $(GENDOCFULL))

dist : src-dist ttf-dist sans-dist lgc-dist web-dist

src-dist :  $(addprefix $(DISTDIR)/$(SRCARCHIVE),  $(ARCHIVEEXT) $(SUMEXT))

ttf-dist : $(addprefix $(DISTDIR)/$(TTFARCHIVE), $(ARCHIVEEXT) $(SUMEXT))

sans-dist : $(addprefix $(DISTDIR)/$(SANSARCHIVE), $(ARCHIVEEXT) $(SUMEXT))

lgc-dist :  $(addprefix $(DISTDIR)/$(LGCARCHIVE),  $(ARCHIVEEXT) $(SUMEXT))

web-dist : $(addprefix $(DISTDIR)/$(WEBARCHIVE), $(ARCHIVEEXT) $(SUMEXT))

norm : $(NORMSFD)

check-harder : clean check

pre-patch : munge clean

clean :
	$(RM) -r $(TMPDIR) $(BUILDDIR) $(DISTDIR)

condensed: $(NORMSFD)
	$(NARROW) 90 $(TMPDIR)/GehenSans.sfd.norm
	$(NARROW) 90 $(TMPDIR)/GehenSans-Bold.sfd.norm
	$(NARROW) 90 $(TMPDIR)/GehenSans-Oblique.sfd.norm
	$(NARROW) 90 $(TMPDIR)/GehenSans-BoldOblique.sfd.norm
	$(NARROW) 90 $(TMPDIR)/GehenSerif.sfd.norm
	$(NARROW) 90 $(TMPDIR)/GehenSerif-Bold.sfd.norm
	$(NARROW) 90 $(TMPDIR)/GehenSerif-Italic.sfd.norm
	$(NARROW) 90 $(TMPDIR)/GehenSerif-BoldItalic.sfd.norm
	$(NORMALIZE) $(TMPDIR)/GehenSans.sfd.norm.narrow
	$(NORMALIZE) $(TMPDIR)/GehenSans-Bold.sfd.norm.narrow
	$(NORMALIZE) $(TMPDIR)/GehenSans-Oblique.sfd.norm.narrow
	$(NORMALIZE) $(TMPDIR)/GehenSans-BoldOblique.sfd.norm.narrow
	$(NORMALIZE) $(TMPDIR)/GehenSerif.sfd.norm.narrow
	$(NORMALIZE) $(TMPDIR)/GehenSerif-Bold.sfd.norm.narrow
	$(NORMALIZE) $(TMPDIR)/GehenSerif-Italic.sfd.norm.narrow
	$(NORMALIZE) $(TMPDIR)/GehenSerif-BoldItalic.sfd.norm.narrow
	cp $(TMPDIR)/GehenSans.sfd.norm.narrow.norm $(TMPDIR)/GehenSansCondensed.sfd.norm
	cp $(TMPDIR)/GehenSans-Bold.sfd.norm.narrow.norm $(TMPDIR)/GehenSansCondensed-Bold.sfd.norm
	cp $(TMPDIR)/GehenSans-Oblique.sfd.norm.narrow.norm $(TMPDIR)/GehenSansCondensed-Oblique.sfd.norm
	cp $(TMPDIR)/GehenSans-BoldOblique.sfd.norm.narrow.norm $(TMPDIR)/GehenSansCondensed-BoldOblique.sfd.norm
	cp $(TMPDIR)/GehenSerif.sfd.norm.narrow.norm $(TMPDIR)/GehenSerifCondensed.sfd.norm
	cp $(TMPDIR)/GehenSerif-Bold.sfd.norm.narrow.norm $(TMPDIR)/GehenSerifCondensed-Bold.sfd.norm
	cp $(TMPDIR)/GehenSerif-Italic.sfd.norm.narrow.norm $(TMPDIR)/GehenSerifCondensed-Italic.sfd.norm
	cp $(TMPDIR)/GehenSerif-BoldItalic.sfd.norm.narrow.norm $(TMPDIR)/GehenSerifCondensed-BoldItalic.sfd.norm

deploy : 
	$(PYTHON) scripts/add-fonts.py `cat ../github-token.txt` \
		dist/$(TTFARCHIVE).tar.bz2 \
		dist/$(SANSARCHIVE).tar.bz2 \
		dist/$(WEBARCHIVE).tar.bz2
