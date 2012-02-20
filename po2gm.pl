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

sub insert_backref {
	(my $str, my $var, my $backref) = @_;
	$str =~ s/^$var/\$$backref"+"/;
	$str =~ s/$var$/"+"\$$backref/;
	$str =~ s/$var/"+"\$$backref"+"/;
	return $str;
}

sub insert_all_backrefs {
	(my $orig, my $str) = @_;
	my $vars = 1;
	while ($orig =~ m/(%[A-Za-z])/g) {
		$vars++;
		$str = insert_backref($str, $1, $vars);
	}
	return $str;
}

my @outputlines;
my %formats;
$formats{'%A'} = '%A'; # simple days of the week: "Saturday"
$formats{'%B'} = '%B'; # simple month names: "February"

my $aref = Locale::PO->load_file_asarray($ARGV[0]);
foreach my $msg (@$aref) {
	next if $msg->fuzzy();
	my $id = $msg->msgid();
	my $str = $msg->msgstr();
	my $note = $msg->automatic();
	if ($str and $id and $id ne '""') {
		my $tempid = $msg->dequote($id);
		my $tempstr = $msg->dequote($str);
		if ($tempstr ne '') {
			if (defined($note) and $note =~ /Format\./) {
				$formats{$tempid} = $tempstr;
			}
			elsif (defined($note) and $note =~ /(Day of the Week|Month Name)/) {
				for my $fmt (keys %formats) {
					if (($fmt =~ /%A/ and $note =~ /Day of the Week/) or
					    ($fmt =~ /%B/ and $note =~ /Month Name/)) {
						my $regex = $fmt;  # e.g. "%B %d"
						$regex =~ s/%[AB]/$tempid/;
						my $orig = $regex;
						$regex =~ s/%d/([0-9]{1,2})/;  # Now "February ([0-9]{1,2})
						$regex =~ s/%Y/([0-9]{4})/;
						$regex =~ s/%s/([0-9:apm]+)/;
						$regex = '(^|="|>)'.$regex.'(?=($|"|<))';
						my $repl = $formats{$fmt};        # e.g. "%d %B"
						$repl =~ s/%[AB]/$tempstr/;       # Now "%d Feabhra"
						$repl = insert_all_backrefs($orig, $repl);
						push @outputlines, "  d = r(d, '$regex', \"\$1\"+\"$repl\");\n";
					}
				}
			}
			else {
				$tempid =~ s/'/\\'/g;
				$tempid =~ s/([.])/\\$1/g;
				$tempid =~ s/([()?])/\\\\$1/g;
				my $orig = $tempid;
				$tempid =~ s/%a/(<a [^>]+>[^<]+<\/a>)/g;
				$tempid =~ s/%d/([0-9]+)/g;
				$tempid =~ s/%s/([^<" ]+)/g;
				$tempstr =~ s/"/\\"/g;
				$tempstr = insert_all_backrefs($orig, $tempstr);
				$tempid = '(^|="|>)'.$tempid.'(?=($|"|<))';
				push @outputlines, "  d = r(d, '$tempid', \"\$1\"+\"$tempstr\");\n";
			}
		}
	}
}

print foreach (sort { length($b) <=> length($a) } @outputlines);

exit 0;
