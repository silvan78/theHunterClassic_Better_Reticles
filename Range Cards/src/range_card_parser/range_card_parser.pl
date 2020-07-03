#!/usr/bin/perl

use warnings;
use strict;
use POSIX qw(strftime);
use YAML::XS qw{LoadFile};

my $version="1.2";

my $today = strftime"%Y%m%d", localtime;
my %setup=();
my $item;
my $range;
my @LongRangeLines;
my @ShortRangeLines;
my %DictIndexItem;
my %DictItemIndex;
my $z;
my $weapons;
my $scopes;
my $error;

# Defaults
$setup{'library'} = 'data/Universal Reticle MRAD.yml';
$setup{'output_file'} = 'hunt/range_card.txt';
$setup{'item_list'} = [];
$setup{'range_list_long'} = [150,175,200,225,250,275,300,325];
$setup{'range_list_short'} = [10,20,30,40,50,60,80,100];
$setup{'simulate'}=0;
$setup{'printlegend'}=0;

open $error,">&",\*STDERR or die "ERROR: Cannot write to STDERR. Exiting.";


if ($#ARGV < 0) {
    print {$error} "ERROR: No argument given (items/listing/help). Exiting.\n\n";
    PrintHelp();
    PrintLibraryContents();
    exit(1);
}

GetArgs();

# Read Library data into %lib_names and %lib_correction

# Define Long Range
my @LongRangeItems=();
foreach $item (@{$setup{'item_list'}}) {
    foreach $range (sort @{$setup{'range_list_long'}}) {
        if (defined GetRange($item,$range)) {
            push(@LongRangeItems,$item);
            last;
        }
    }
}
# Define Short Range Items
my @ShortRangeItems=();
foreach $item (@{$setup{'item_list'}}) {
    foreach $range (sort @{$setup{'range_list_short'}}) {
        if (defined GetRange($item,$range)) {
            push(@ShortRangeItems,$item);
            last;
        }
    }
}

# Preparing range card print
@LongRangeLines=();
if ($#LongRangeItems >= 0) {
    push(@LongRangeLines,"     ");
    push(@LongRangeLines,"     ");
    push(@LongRangeLines,"     ");
    push(@LongRangeLines,"LONG ");
    push(@LongRangeLines,"----+");
    foreach $range (@{$setup{'range_list_long'}}){
        push(@LongRangeLines,FormatRangeLong($range)."|");
    }
    foreach $item (@LongRangeItems) {
        $LongRangeLines[0].=ItemName($item);
        $LongRangeLines[1].=AmmoName1stLine($item);
        $LongRangeLines[2].=AmmoName2ndLine($item);
        $LongRangeLines[3].=ScopeName($item);
        $LongRangeLines[4].="------";
        for ($z=0;$z<=$#{$setup{'range_list_long'}};$z++) {
            $range=$setup{'range_list_long'}[$z];
            $LongRangeLines[$z+5].=FormatCorrection(GetRange($item,$range));
        }
    }
}

@ShortRangeLines=();
if ($#ShortRangeItems >= 0) {
    push(@ShortRangeLines,"     ");
    push(@ShortRangeLines,"     ");
    push(@ShortRangeLines,"     ");
    push(@ShortRangeLines,"SHORT");
    push(@ShortRangeLines,"----+");
    foreach $range (@{$setup{'range_list_short'}}){
        push(@ShortRangeLines,FormatRangeShort($range)."|");
    }
    foreach $item (@ShortRangeItems) {
        $ShortRangeLines[0].=ItemName($item);
        $ShortRangeLines[1].=AmmoName1stLine($item);
        $ShortRangeLines[2].=AmmoName2ndLine($item);
        $ShortRangeLines[3].=ScopeName($item);
        $ShortRangeLines[4].="------";
        for ($z=0;$z<=$#{$setup{'range_list_short'}};$z++) {
            $range=$setup{'range_list_short'}[$z];
            $ShortRangeLines[$z+5].=FormatCorrection(GetRange($item,$range));
        }
    }
}

# Deciding which has more lines (to fill with appropriate number of space shorter output)
my $filler;
if ( ($#LongRangeItems >= 0) and ($#ShortRangeItems >= 0)) {
    if ($#LongRangeLines > $#ShortRangeLines) {
        $filler = sprintf("%*s", length($ShortRangeLines[4]), "");
        foreach $z ($#LongRangeLines - $#ShortRangeLines .. $#LongRangeLines) {
            push(@ShortRangeLines, $filler);
        }
    }
    elsif ($#LongRangeLines < $#ShortRangeLines) {
        $filler = sprintf("%*s", length($LongRangeLines[4]), "");
        foreach $z ($#ShortRangeLines - $#LongRangeLines .. $#ShortRangeLines) {
            push(@LongRangeLines, $filler);
        }
    }
}

#joining output and printing
my $out;
if ($setup{'simulate'} == 0) {
    open $out,">",$setup{'output_file'} or die "ERROR: Cannot write to output file ($setup{'output_file'}. Exiting.";
 } else {
     open $out,">&",\*STDOUT or die "ERROR: Cannot write to STDOUT. Exiting.";
}
print {$out} "Universal Reticle MRAD Range Card $today\n\n";
if ($#LongRangeItems >=0) {
    foreach $z (0 .. $#LongRangeLines) {
        print {$out} "$LongRangeLines[$z]";
        if ($#ShortRangeItems >=0) {
            print {$out} "    $ShortRangeLines[$z]"
        }
        print {$out} "\n";
    }
} else {
    foreach $z (0 .. $#ShortRangeLines) {
        print {$out} "$ShortRangeLines[$z]\n";
    }

}


#######
# Subs
#######
sub GetWeapon {
    my $GW_in = shift @_;
    return ${SplitItem($GW_in)}[0];
}

sub GetAmmo {
    my $GA_in = shift @_;
    return ${SplitItem($GA_in)}[1];
}

sub GetScope {
    my $GS_in = shift @_;
    return ${SplitItem($GS_in)}[2];
}

sub GetRange {
    my @GR_in=@_;
    my @GR_tmp=@GR_in;
    my $GR_item = shift @GR_in;
    my $GR_range = shift @GR_in;
    my $GR_weapon;
    my $GR_ammo;
    my $GR_scope;

    if (length($GR_range) <1) {
        print {$error} "ERROR: Calling GetRange with not enough arguments (",join(',',@GR_tmp),"). Exiting.\n";
        exit(1);
    } else {
        $GR_weapon = GetWeapon($GR_item);
        $GR_ammo = GetAmmo($GR_item);
        $GR_scope = GetScope($GR_item);
    }
    if (defined $weapons->{$GR_weapon}->{'ammo'}->{$GR_ammo}->{'scope'}->{$GR_scope}->{'correction'}->{$GR_range}) {
        return $weapons->{$GR_weapon}->{'ammo'}->{$GR_ammo}->{'scope'}->{$GR_scope}->{'correction'}->{$GR_range};
    } else {
        return undef;
    }
}

sub SplitItem {
    my $SI_in=shift @_;
    my @SI_tbl;
    @SI_tbl=split('/',$SI_in);
    if ($#SI_tbl < 2) {
        print {$error} "ERROR: SplitItems input missing elements (",$SI_in,"). Exiting.\n";
        exit(1);
    }
    return \@SI_tbl;
}

sub FormatRangeLong {
    return sprintf("%4d",shift @_);
}

sub FormatRangeShort {
    return sprintf("%4d",shift @_);
}

sub FormatCorrection {
    my $FCin;
    if (@_) {
        $FCin=shift @_;
    } else {
        $FCin=undef;
    }
    if (! defined $FCin) {
        return "      "
    } elsif ($FCin=~/\?/) {
        return sprintf("% 6s",$FCin);
    } else {
        return sprintf("%6.2f",$FCin);
    }
}

sub AmmoName1stLine {
    my $FN_in=shift @_;
    my $FN_weapon=GetWeapon($FN_in);
    my $FN_ammo=GetAmmo($FN_in);
    my $FN_name=$weapons->{$FN_weapon}->{'ammo'}->{$FN_ammo}->{'abbrev'};
    my @FNtbl=split(' ',$FN_name);

    return " ".sprintf("%5s",substr($FNtbl[0],0,5));
}

sub AmmoName2ndLine {
    my $FN_in=shift @_;
    my $FN_weapon=GetWeapon($FN_in);
    my $FN_ammo=GetAmmo($FN_in);
    my $FN_name=$weapons->{$FN_weapon}->{'ammo'}->{$FN_ammo}->{'abbrev'};
    if ($FN_name=~/ /) {
        my @FNtbl = split(' ', $FN_name);
        @FNtbl = splice @FNtbl, 1, $#FNtbl;
        return " " . sprintf("%5s", substr(join(' ', @FNtbl), 0, 5));
    } else {
        return "      ";
    }
}

sub ScopeName {
    my $SN_in=shift @_;
    my $SN_scope=GetScope($SN_in);
    my $SN_name=$scopes->{$SN_scope}->{'abbrev'};
    return " " . sprintf("%5s", substr($SN_name, 0, 5));
}

sub FormatName {
    my $FNin=shift @_;
    return " ".sprintf("%5s",substr($FNin,0,5));
}

sub ItemCode {
    my $IC_in = shift @_;
    my $IC_weapon = GetWeapon($IC_in);
    my $IC_scope = GetScope($IC_in);
    my $IC_out = $scopes->{$IC_scope}->{'alias'};
    $IC_out.=$weapons->{$IC_weapon}->{'index'};
    return $IC_out;
}

sub ItemName {
    my $IN_in=shift @_;
    my $IN_weapon=GetWeapon($IN_in);
    my $IN_name=$weapons->{$IN_weapon}->{'abbrev'};
    $IN_name=~s/ //g;
    return " ".sprintf("%5s",substr($IN_name,0,5));
}

sub toUpper {
    my $tU = shift @_;
    $tU=~tr/{a-z}/{A-Z}/;
    return $tU;
}

sub ReadLibrary {
    my $yamlref=LoadFile($setup{'library'}) or die "ERROR: Cannot open library file (".$setup{'library'}."). Exiting.";

    $scopes=$yamlref->{'scope'};
    $weapons=$yamlref->{'weapon'};
    if (length($weapons) < 1 ) {
        print {$error} "ERROR: No weapons in library (".$setup{'library'}."). Exiting.\n";
        exit(1);
    }
    if (length($scopes) < 1 ) {
        print {$error} "ERROR: No scopes in library (".$setup{'library'}."). Exiting.\n";
        exit(1);
    }

    BuildLibraryIndex();
}

sub BuildLibraryIndex {
    my $weapon;
    my $ammo;
    my $scope;
    my $i;
    my $dict_item;

    $i=1;
    foreach $weapon (sort keys %{$weapons}) {
        foreach $ammo (sort keys %{$weapons->{$weapon}->{'ammo'}}) {
            foreach $scope (sort keys %{$weapons->{$weapon}->{'ammo'}->{$ammo}->{'scope'}}) {
                $dict_item=$weapon."/".$ammo."/".$scope;
                $DictIndexItem{$i}=$dict_item;
                $DictItemIndex{$dict_item}=$i;
                $i++;
            }
        }
    }
}
sub GetArgs {
	my @ARG_LIST=@ARGV;
	my $arg;
	my $i=0;
    my @item_tbl;
    $setup{'show_all'}=0;
    $setup{'show_combinations'}=0;
    $setup{'show_weapons'}=0;
    $setup{'show_scopes'}=0;
    $setup{'simulate'}=0;

	for ($i=0;$i<=$#ARG_LIST;$i++) {
		$arg=$ARG_LIST[$i];
		if (($arg eq '-h') or ($arg eq 'help') or ($arg eq '--help')) {
			PrintHelp();
			exit(0);
		} elsif ($arg eq '-l') {
            $setup{'show_all'} = 1;
        } elsif ($arg eq '-ls') {
            $setup{'show_scopes'} = 1;
        } elsif ($arg eq '-lw') {
            $setup{'show_weapons'} = 1;
        } elsif ($arg eq '-lc') {
            $setup{'show_combinations'} = 1;
		} elsif ($arg eq '-i'){
			$setup{'library'} = $ARG_LIST[$i+1];
			$i++;
		} elsif ($arg eq '-o') {
            $setup{'output_file'} = $ARG_LIST[$i + 1];
            $i++;
        } elsif ($arg eq '-s') {
            $setup{'simulate'} = 1;
		} elsif ($arg eq '-c') {
			my $j;
			for ($j=$i+1;$j<=$#ARG_LIST;$j++) {
				if (($ARG_LIST[$j]=~/^-/) or ($ARG_LIST[$j]=~/^help/)){
					$i=$j-1;
					last;
				} else {
                    push(@item_tbl,$ARG_LIST[$j]);
                }
				if ($j==$#ARG_LIST) {
					$i=$j;
				}
			}
		} elsif ($arg eq '-rl') {
		    @{$setup{'range_list_long'}} = split(',',$ARG_LIST[$i+1]);
		    $i++;
		} elsif ($arg eq '-rs') {
		    @{$setup{'range_list_short'}} = split(',',$ARG_LIST[$i+1]);
		    $i++;
		} else {
			print {$error} "ERROR: Unknown option ($arg). Exiting.\n";
			PrintHelp();
			exit(1);
		}
    }
    # Basic library parameter tests
    if (!defined $setup{'library'}) {
        print {$error} "ERROR: library and/ot library legend file not defined. Exiting.";
        exit(1);
    }
    if (! -e $setup{'library'}) {
        print {$error} "ERROR: $setup{'library'} library file does not exist. Exiting.\n";
        exit(1);
    }

    ReadLibrary();

    if ($setup{'show_all'}+$setup{'show_scopes'}+$setup{'show_weapons'}+$setup{'show_combinations'} > 0) {
        PrintLibraryContents();
        exit(0);
    }

    # Input item parameters processing and testing
    if ($#item_tbl == -1) {
        print {$error} "ERROR: Empty initial item list. Exiting.\n";
        exit(1);
    } else {
        my $t;
        for ($t = 0; $t <= $#item_tbl; $t++) {
            my $arg_element;
            my $item_candidate;
            if ($item_tbl[$t] =~ /,/) {
                my @tmp_item_tbl = split(',', $item_tbl[$t]);
                foreach $arg_element (@tmp_item_tbl) {
                    $item_candidate=ItemizeArg($arg_element);
                    if (defined $DictItemIndex{$item_candidate}) {
                        push(@{$setup{'item_list'}}, $item_candidate);
                    } else {
                        print {$error} "ERROR: Item $arg_element not in library. Omitting.\n";
                    }
                }
            }
            else {
                $item_candidate=ItemizeArg($item_tbl[$t]);
                if ($DictItemIndex{$item_candidate}) {
                    push(@{$setup{'item_list'}}, $item_candidate);
                } else {
                    print {$error} "WARNING: Item $item_tbl[$t] not in library. Omitting.\n";
                }
            }
        }
    }
    if ($#{$setup{'item_list'}} == -1) {
        print {$error} "ERROR: Empty final item list. Exiting.\n";
        exit(1);
    }
}

sub ItemizeArg {
    my $IA_in=shift @_;
    if ($IA_in=~/.+\/.+\/.+/) {
        if ($DictItemIndex{$IA_in}) {
            return $IA_in;
        } else {
            return "NONE";
        }
    } elsif ($IA_in=~/\d+/) {
        if ($DictIndexItem{$IA_in}) {
        return $DictIndexItem{$IA_in};
    } else {
            return "NONE";
        }
    } else {
        print {$error} "ERROR: Unknown item format ($IA_in). Exiting.";
        exit(1);
    }
}

sub PrintHelp {
    print << "XXX";
range_card_parser v.$version

The Hunter Classic custom overlay reticles range cards formatter.
Program parses library range card into smaller hunt-specific range card.
By default data form Range Cards/Universal Reticle MRAD.yml are cut into
Range Cards/hunt/range_card.txt file.

Usage:
       range_card_parser[.exe|.pl] <options> -c <CSV Weapon/Ammo/Optics list>

Options:
        -c : Weapon/Ammo/Optics or items indexes (comma/space separated)
        -i : Range Card library file [data/Universal Reticle MRAD.yml]
        -o : Output range card file [hunt/range_card.txt]
        -l : Print all library content
        -ls: Print scopes in library
        -lw: Print weapons in library
        -lc: Print weapon/ammo/optics combinations in library
        -rl: Range list for long ranges [150,175,200,225,250,275,300,325]
        -rs: Range list for short ranges [10,20,30,40,50,60,80,100]
        -s : Simulate parsing, print to STDOUT
        -h : This help

Example:
        range_card_parser[.exe|.pl] -c ".17LA/.17HMR/12x56" "CroPis/Arrow/2xCroPis"
        range_card_parser[.exe|.pl] -c ".223BA/.223/5-22x56" "ParkerPython/Arrow/5pinPython" -rl 150,200,300 -rs 20,40,60
        range_card_parser[.exe|.pl] -c 1,2 28 ".223BA/.223/5-22x56" -rl 200,300 -rs 20,40,60

XXX

}

sub PrintLibraryContents {
    # my $PLfh;
    # my @PL_file;
    # open $PLfh,"<",$setup{'library_legend'} or die "ERROR: Cannot open library legend file (".$setup{'library_legend'}."). Exiting.";
    # @PL_file=<$PLfh>;
    # print "--- Library legend: ",$setup{'library_legend'},"\n";
    # print @PL_file;
    # close ($PLfh);
    #
    # my $itemlist="Available combinations: ".join(', ',sort keys %lib_name)."\n";
    # my $wrap_length = 100;
    # my $wrapped_itemlist;
    # ($wrapped_itemlist = $itemlist) =~s/(.{0,$wrap_length}(?:\s|$))/$1\n/g;
    # print $wrapped_itemlist;

    print "--- Library: ", $setup{'library'}, "\n\n";
    if (($setup{'show_scopes'} == 1) or ($setup{'show_all'})) {
        PrintLibraryLegendScopes();
    }
    if (($setup{'show_weapons'} == 1) or ($setup{'show_all'})) {
        PrintLibraryLegendWeapons()
    }
    if (($setup{'show_combinations'} == 1) or ($setup{'show_all'})) {
        PrintLibraryLegendCombinations();
    }
}

sub PrintLibraryLegendScopes {
    my $scope;

    print "-- Scopes (id name):\n";
    foreach $scope (sort keys %{$scopes}) {
        printf("\t%-15s   %s\n", $scope, $scopes->{$scope}->{'name'});
    };

    print "\n";
}
sub PrintLibraryLegendWeapons {
    my $weapon;
    print "-- Weapons (id name):\n";
    foreach $weapon (sort keys %{$weapons}) {
        printf ("\t%-15s   %s\n",$weapon,$weapons->{$weapon}->{'name'});
    };
    print "\n";
}

sub PrintLibraryLegendCombinations {
    my @tmp_pairs;
    my $weapon;
    my $ammo;
    my $scope;

    print "-- Sets (weapon/ammo/scope   ranges):\n";
    my $corrections;
    foreach $weapon (sort keys %{$weapons}) {
        foreach $ammo (sort keys %{$weapons->{$weapon}->{'ammo'}}) {
            foreach $scope (sort keys %{$weapons->{$weapon}->{'ammo'}->{$ammo}->{'scope'}}) {
                $corrections=join(',',sort { $a <=> $b } keys %{$weapons->{$weapon}->{'ammo'}->{$ammo}->{'scope'}->{$scope}->{'correction'}});
                push(@tmp_pairs,$weapon."/".$ammo."/".$scope,$corrections);
            }

        }
    }
    my $i;
    for ($i=0;$i<=$#tmp_pairs;$i=$i+2) {
        printf("\t%2d  %-35s    %s\n",$DictItemIndex{$tmp_pairs[$i]},$tmp_pairs[$i],$tmp_pairs[$i+1]);
    }
    print "\n";
}