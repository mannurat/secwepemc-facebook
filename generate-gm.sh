#!/bin/bash
#  Copyright 2012 Kevin Scannell
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

VERSION=1.0.0
TEMPFILE=`mktemp`
cat LINGUAS | tr "\t" "~" |
while read x
do
	LANGCODE=`echo $x | sed 's/~.*//'`
	ENGLISHNAME=`echo $x | sed 's/^[^~]*~//' | sed 's/~.*//'`
	NATIVENAME=`echo $x | sed 's/^.*~\([^~]*\)~[^~]*$/\1/'`
	TRANSLATORS=`echo $x | sed 's/^.*~\([^~]*\)$/\1/'`
	echo "Generating greasemonkey for ${LANGCODE}..."
	perl po2gm.pl po/$LANGCODE.po > ${TEMPFILE}
	sed "/Translations go here/r ${TEMPFILE}" template.user.js | sed "s/!TEANGA!/${LANGCODE}/" | sed "s/!DATA!/`date --rfc-3339=date`/" | sed "s/!LEAGAN!/${VERSION}/" | sed "s/!ENGLISHNAME!/${ENGLISHNAME}/" | sed "s/!TRANSLATORS!/${TRANSLATORS}/" | sed "s/!NATIVENAME!/${NATIVENAME}/" > facebook-${LANGCODE}.user.js
	rm -f ${LANGCODE}-temp.js
done
rm -f ${TEMPFILE}
