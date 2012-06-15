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
	die "Usage: $0 TARGETLANG AMBIENTLANG\n";
}

sub insert_backref {
	(my $target, my $var, my $var_number) = @_;
	$target =~ s/$var/"+"\$$var_number"+"/;
	return $target;
}

# First argument is the escaped source string, e.g. %a likes %a\.
# or in case of an alternate source language, %a aime %a\.
# Second argument is the escaped target string, e.g. Plijet eo %a gant %a
# Returns the target string, double-quoted, with each % variable
# replaced by a backref $2, $3, $4, ...  ($1 reserved for left-hand boundary)
sub insert_all_backrefs {
	(my $source, my $target) = @_;
	$target = "\"$target\"";
	my $var_number = 1;
	while ($source =~ m/(%[A-Za-z])/g) {
		$var_number++;
		$target = insert_backref($target, $1, $var_number);
	}
	$target =~ s/""\+//g;
	$target =~ s/\+""$//;
	return $target;
}

sub escape_regex {
	(my $r) = @_;
	$r =~ s/'/\\'/g;
	$r =~ s/([.])/\\$1/g;
	$r =~ s/[?]$/\\\\?/g;  # don't escape non-terminal ? (see fr.po)
	$r =~ s/([()])/\\\\$1/g;
	return $r;
}

my @outputlines;
my %plural_regex;
my %formats;
my $targetlang = $ARGV[0];
my $ambient = $ARGV[1];
my %source; # maps English to whatever ambient language is (maybe en!)
$formats{'%A'} = '%A'; # simple days of the week: "Saturday"
$formats{'%B'} = '%B'; # simple month names: "February"

open(PLURALS, "<:utf8", "plurals.txt") or die "Could not open plural form file: $!";
while (<PLURALS>) {
	chomp;
	(my $code, my $num, my $regex) = m/^([A-Za-z-]+)\t([0-9])\t(.+)$/;
	$plural_regex{$num} = $regex if ($code eq $targetlang);
}
close PLURALS;

unless ($ambient eq 'en') {
	my $aref = Locale::PO->load_file_asarray("po/$ambient.po");
	shift @$aref;
	foreach my $msg (@$aref) {
		next if $msg->fuzzy();
		my $id = $msg->msgid();
		my $plural_id = $msg->msgid_plural();
		if (defined($plural_id)) {
			my $plural_hashref = $msg->msgstr_n();
			if (scalar keys %{$plural_hashref} != 2) {
				print STDERR "Warning: Alternate source language must have nplurals==2\n";
			}
			else {
				my $str = $msg->dequote($plural_hashref->{'0'}); 
				$source{$msg->dequote($id)} = $str unless ($str eq '');
				$str = $msg->dequote($plural_hashref->{'1'}); 
				$source{$msg->dequote($plural_id)} = $str unless ($str eq '');
			}
		}
		else {
			my $str = $msg->dequote($msg->msgstr());
			if (!defined($str)) {
				print STDERR "problem; str not defined for msgid = $id\n";
			}
			$source{$msg->dequote($id)} = $str unless ($str eq '');
		}
	}
}

# return undef if I don't know the string in the alternate source lang
sub get_source_string {
	(my $str) = @_;
	if ($ambient eq 'en') {
		return $str;
	}
	else {
		if (exists($source{$str})) {
			return $source{$str};
		}
		else {
			return undef;
		}
	}
}

# takes dequoted msgid, msgstr, and boolean true iff element is always a link
# result is that a line of JS is written to @outputlines array 
sub process_generic_translation {
	(my $id, my $str, my $link_p, my $regex) = @_;

	$id = escape_regex($id);
	my $orig = $id;
	$id =~ s/%T/(<a [^>]+><abbr [^>]+>[^<]+<\/abbr><\/a>)/g;
	$id =~ s/%a/(<a [^>]+>[^<]+<\/a>)/g;
	$id =~ s/%d/($regex)/g;
	$id =~ s/%s/([^<" ]+)/g;
	$str =~ s/"/\\"/g;
	if ($id ne $str) {
		$str = insert_all_backrefs($orig, $str);
		if ($link_p) {
			$id = '(^|>)'.$id.'(?=($|<))';
		}
		else {
			$id = '(^|="|>)'.$id.'(?=($|"|<))';
		}
		push @outputlines, "  d = r(d, '$id', \"\$1\"+$str);\n";
	}
}

my $aref = Locale::PO->load_file_asarray("po/$targetlang.po");
shift @$aref;  # remove PO header
foreach my $msg (@$aref) {
	next if $msg->fuzzy();
	my $id = $msg->dequote($msg->msgid());
	$id = get_source_string($id);
	next unless defined($id);
	my $plural_id = $msg->msgid_plural();
	my $str = $msg->msgstr();
	my $note = $msg->automatic();
	my $link_p = (defined($note) and $note =~ /Always a link\./);
	if (defined($note) and $note =~ /Format\./) {
		$str = $msg->dequote($str);
		$formats{$id} = $str if ($str ne '');
	}
	elsif (defined($note) and $note =~ /(Day of the Week|Month Name)/) {
		$str = $msg->dequote($str);
		next if ($str eq '');
		# note we're assuming these come after all format strings...
		for my $fmt (keys %formats) {
			if (($fmt =~ /%A/ and $note =~ /Day of the Week/) or
			    ($fmt =~ /%B/ and $note =~ /Month Name/)) {
				my $regex = $fmt;  # e.g. "%B %d" - might have parens if non-English ambient (e.g. es)
				$regex =~ s/%[AB]/$id/; # February %d
				$regex = escape_regex($regex); # might be needed eventually for new alternate source languages
				my $orig = $regex;
				$regex =~ s/%d/([0-9]{1,2})/;  # Now "February ([0-9]{1,2})
				$regex =~ s/%Y/([0-9]{4})/;
				$regex =~ s/%s/([0-9:.apm]+)/;
				$regex = '(^|="|>)'.$regex.'(?=($|"|<))';
				my $repl = $formats{$fmt};        # e.g. "%d %B"
				$repl =~ s/%[AB]/$str/;       # Now "%d Feabhra"
				if ($targetlang =~ m/^(an|ast)$/) {
					$repl =~ s/de ([aeiou])/d'$1/;
				}
				$repl = insert_all_backrefs($orig, $repl);
				push @outputlines, "  d = r(d, '$regex', \"\$1\"+$repl);\n";
			}
		}
	}
	elsif (defined($plural_id)) {
		$plural_id = $msg->dequote($plural_id);
		$plural_id = get_source_string($plural_id);
		next unless defined($plural_id);
		my $plural_hashref = $msg->msgstr_n();
		foreach my $k (sort { $a <=> $b } keys %{$plural_hashref}) {
			my $trans = $msg->dequote($plural_hashref->{$k});
			if ($trans ne '') {
				my $numeral_regex = $plural_regex{$k};
				my $singular = '1';
				# matches singular, but isn't the catch-all
				if ($singular =~ m/^$numeral_regex$/ and $numeral_regex ne '[0-9,]+') {
					# no %d's in (singular) msgid so no regex needed
					# But for br, gd, msgstr[0] might have %d, so subst. "1"
					my $sing_trans = $trans;
					$sing_trans =~ s/%d/1/;
					process_generic_translation($id, $sing_trans, $link_p, '');
				}
				# as long as regex isn't '1', it matches some plurals
				process_generic_translation($plural_id, $trans, $link_p, $numeral_regex) if ($numeral_regex ne $singular);
			}
		}
	}
	else {
		$str = $msg->dequote($str);
		process_generic_translation($id, $str, $link_p, '[0-9,]+') unless ($str eq '');
	}
}

print foreach (sort { length($b) <=> length($a) } @outputlines);

exit 0;
