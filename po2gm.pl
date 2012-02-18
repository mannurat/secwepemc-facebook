#!/usr/bin/perl
#  Copyright 2012 Kevin Scannell
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

use strict;
use warnings;
use Locale::PO;

if (scalar @ARGV != 1) {
	die "Usage: $0 POFILE\n";
}

my @outputlines;

my $aref = Locale::PO->load_file_asarray($ARGV[0]);
foreach my $msg (@$aref) {
	my $id = $msg->msgid();
	my $str = $msg->msgstr();
	if ($str and $id and $id ne '""') {
		my $tempid = $msg->dequote($id);
		my $tempstr = $msg->dequote($str);
		if ($tempstr ne '') {
			$tempid =~ s/'/\\'/g;
			$tempid =~ s/([.])/\\$1/g;
			$tempid =~ s/([()?])/\\\\$1/g;
			$tempid =~ s/%d/([0-9]+)/;
			$tempid =~ s/%s/(<a [^>]+>[^<]+<\/a>)/;
			$tempstr =~ s/"/\\"/g;
			$tempstr =~ s/^%[ds]/\$2"+"/;
			$tempstr =~ s/%[ds]$/"+"\$2/;
			$tempstr =~ s/%[ds]/"+"\$2"+"/;
			$tempid = '(^|="|>)'.$tempid.'(?=($|"|<))';
			push @outputlines, "  d = r(d, '$tempid', \"\$1\"+\"$tempstr\");\n";
		}
	}
}

print foreach (sort { length($b) <=> length($a) } @outputlines);

exit 0;
