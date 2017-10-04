# Original makefile from https://github.com/martinthomson/i-d-template

# Edited by wkumari to remove a bunch of the extra stuff I'll never use.

# The following tools are used by this file.
# All are assumed to be on the path, but you can override these
# in the environment, or command line.

# Mandatory:
#   https://pypi.python.org/pypi/xml2rfc
xml2rfc ?= xml2rfc

# If you are using markdown files:
#   https://github.com/cabo/kramdown-rfc2629
kramdown-rfc2629 ?= kramdown-rfc2629

# If you are using outline files:
#   https://github.com/Juniper/libslax/tree/master/doc/oxtradoc
oxtradoc ?= oxtradoc.in

# For sanity checkout your draft:
#   https://tools.ietf.org/tools/idnits/
idnits ?= idnits

# For diff:
#   https://tools.ietf.org/tools/rfcdiff/
rfcdiff ?= rfcdiff --browse

# For generating PDF:
#   https://www.gnu.org/software/enscript/
enscript ?= enscript
#   http://www.ghostscript.com/
ps2pdf ?= ps2pdf 


## Work out what to build
draft := $(basename $(lastword $(sort $(wildcard draft-*.xml)) $(sort $(wildcard draft-*.org)) $(sort $(wildcard draft-*.md))))

ifeq (,$(draft))
$(warning No file named draft-*.md or draft-*.xml or draft-*.org)
$(error Read README.md for setup instructions)
endif

draft_type := $(suffix $(firstword $(wildcard $(draft).md $(draft).org $(draft).xml)))

## Targets
default:
	@echo 
	@echo "Useful targets:"
	@echo "  txt: The Text version of the draft"
	@echo "  commit: Creates README.md, commits (ci) and pushes the changes to git" 
	@echo "  tag: Lists current tags, gets  anew one, commits and pushed to git"
	@echo "  diff: Unsurprisingly, the diff..."
	@echo


.PHONY: latest txt html pdf submit diff clean update

latest: txt html
txt: $(draft).txt
html: $(draft).html
pdf: $(draft).pdf


idnits: $(draft).txt
	$(idnits) $<


clean:
	-rm -f $(draft).{txt,html,pdf} index.html
	-rm -f $(draft)-[0-9][0-9].{xml,md,org,txt,html,pdf}
	-rm -f *.diff.html
	-rm -f README.md
ifneq (.xml,$(draft_type))
	-rm -f $(draft).xml
endif

## diff

diff:
	git diff $(draft).xml

README.md: $(draft).xml
	@echo "Making README.md and committing and pushing to github. Run 'make tag' to add and push a tag."
	@echo '**Important:** Read CONTRIBUTING.md before submitting feedback or contributing' > README.md
	@echo \`\`\` >> README.md
	@cat $(draft).txt >> README.md
	@echo \`\`\` >> README.md

commit: $(draft).txt README.md
	read -p "Commit message: " msg; \
	git commit -a -m "$$msg";
	@git push

tag:
	@echo "Current tags:"
	git tag
	@echo
	@read -p "Tag message (e.g: Version-00): " tag; \
	git tag -a $$tag -m $$tag
	@git push --tags

## Recipes

.INTERMEDIATE: $(draft).xml
%.xml: %.md
	$(kramdown-rfc2629) $< > $@

%.xml: %.org
	$(oxtradoc) -m outline-to-xml -n "$@" $< > $@

%.txt: %.xml
	$(xml2rfc) $< -o $@ --text

%.html: %.xml
	$(xml2rfc) $< -o $@ --html

%.pdf: %.txt
	$(enscript) --margins 76::76: -B -q -p - $^ | $(ps2pdf) - $@
