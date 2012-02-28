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

if (scalar @ARGV != 2) {
	die "Usage: $0 POFILE AMBIENTLANG\n";
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

sub escape_regex {
	(my $r) = @_;
	$r =~ s/'/\\'/g;
	$r =~ s/([.])/\\$1/g;
	$r =~ s/([()?])/\\\\$1/g;
	return $r;
}

my @outputlines;
my %formats;
my $ambient = $ARGV[1];
my %source; # maps English to whatever ambient language is (maybe en!)
$formats{'%A'} = '%A'; # simple days of the week: "Saturday"
$formats{'%B'} = '%B'; # simple month names: "February"

unless ($ambient eq 'en') {
	my $aref = Locale::PO->load_file_asarray("po/$ambient.po");
	foreach my $msg (@$aref) {
		my $id = $msg->msgid();
		my $str = $msg->msgstr();
		if ($id ne '""' and $str ne '""' and !$msg->fuzzy()) {
			$source{$msg->dequote($id)} = $msg->dequote($str);
		}
		else {
			$source{$msg->dequote($id)} = $msg->dequote($id);
		}
	}
}

sub get_source_string {
	(my $str) = @_;
	if ($ambient eq 'en') {
		return $str;
	}
	else {
		return $source{$str};
	}
}

my $aref = Locale::PO->load_file_asarray($ARGV[0]);
foreach my $msg (@$aref) {
	next if $msg->fuzzy();
	my $id = $msg->msgid();
	my $str = $msg->msgstr();
	my $note = $msg->automatic();
	if ($str and $id and $id ne '""') {
		my $tempid = $msg->dequote($id);
		$tempid = get_source_string($tempid);
		my $tempstr = $msg->dequote($str);
		if ($tempstr ne '') {
			if (defined($note) and $note =~ /Format\./) {
				$formats{$tempid} = $tempstr;
			}
			elsif (defined($note) and $note =~ /(Day of the Week|Month Name)/) {
				for my $fmt (keys %formats) {
					if (($fmt =~ /%A/ and $note =~ /Day of the Week/) or
					    ($fmt =~ /%B/ and $note =~ /Month Name/)) {
						my $regex = $fmt;  # e.g. "%B %d" - might have parens if non-English ambient (e.g. es)
						$regex =~ s/%[AB]/$tempid/;
						$regex = escape_regex($regex);
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
				$tempid = escape_regex($tempid);
				my $orig = $tempid;
				$tempid =~ s/%a/(<a [^>]+>[^<]+<\/a>)/g;
				$tempid =~ s/%d/([0-9]+)/g;
				$tempid =~ s/%s/([^<" ]+)/g;
				$tempstr =~ s/"/\\"/g;
				$tempstr = insert_all_backrefs($orig, $tempstr);
				if (defined($note) and $note =~ /Always a link\./) {
					$tempid = '(^|>)'.$tempid.'(?=($|<))';
				}
				else {
					$tempid = '(^|="|>)'.$tempid.'(?=($|"|<))';
				}
				push @outputlines, "  d = r(d, '$tempid', \"\$1\"+\"$tempstr\");\n";
			}
		}
	}
}

print foreach (sort { length($b) <=> length($a) } @outputlines);

exit 0;
