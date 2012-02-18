# Makefile for secwepemc-facebook
# Copyright 2012 Kevin Scannell
# License: GPLv3+
facebook.pot: strings.txt header.pot
	sed "s/XXXX-XX-XX XX:XX-XXXX/`date --rfc-3339=seconds`/" header.pot > $@
	cat strings.txt | sed 's/"/\\"/g' | sed 's/.*/msgid "&"\nmsgstr ""\n/' >> $@

updatepos: facebook.pot
	find po/ -name '*.po' | while read x; do echo "Updating $$x..."; msgmerge -q --backup=off -U $$x facebook.pot > /dev/null 2>&1; done

updategms: facebook-ga.user.js

# builds all languages
facebook-ga.user.js: po/*.po template.user.js po2gm.pl generate-gm.sh
	bash generate-gm.sh
	cp -f facebook-*.js ${HOME}/public_html/obair

clean:
	rm -f facebook.pot facebook-*.user.js

FORCE:
