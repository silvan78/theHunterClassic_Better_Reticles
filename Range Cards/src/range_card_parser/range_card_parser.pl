#!/c/opt/Perl/perl/bin/perl

use warnings;
use strict;
use POSIX qw(strftime);
use YAML::XS qw{LoadFile};

my $version="1.1";

my $today = strftime"%Y%m%d", localtime;
my %setup=();
my $item;
my $range;
my @LongRangeLines;
my @ShortRangeLines;
my $z;
my $weapons;
my $scopes;


# Defaults
$setup{'library'} = 'data/Universal Reticle MRAD.yml';
$setup{'output_file'} = 'hunt/range_card.txt';
$setup{'item_list'} = [];
$setup{'range_list_long'} = [150,175,200,225,250,275,300,325];
$setup{'range_list_short'} = [10,20,30,40,50,60,80,100];
$setup{'simulate'}=0;
$setup{'printlegend'}=0;

if ($#ARGV < 0) {
    print "ERROR: No argument given (items/listing/help). Exiting.\n\n";
    PrintHelp();
    PrintLibraryLegend();
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
    push(@LongRangeLines,"LONG ");
    push(@LongRangeLines,"----+");
    foreach $range (@{$setup{'range_list_long'}}){
        push(@LongRangeLines,FormatRangeLong($range)."|");
    }
    foreach $item (@LongRangeItems) {
        $LongRangeLines[0].=ItemName($item);
        $LongRangeLines[1].=FormatName1stLine($item);
        $LongRangeLines[2].=FormatName2ndLine($item);
        $LongRangeLines[3].="------";
        for ($z=0;$z<=$#{$setup{'range_list_long'}};$z++) {
            $range=$setup{'range_list_long'}[$z];
            $LongRangeLines[$z+4].=FormatCorrection(GetRange($item,$range));
        }
    }
}

@ShortRangeLines=();
if ($#ShortRangeItems >= 0) {
    push(@ShortRangeLines,"     ");
    push(@ShortRangeLines,"     ");
    push(@ShortRangeLines,"SHORT");
    push(@ShortRangeLines,"----+");
    foreach $range (@{$setup{'range_list_short'}}){
        push(@ShortRangeLines,FormatRangeShort($range)."|");
    }
    foreach $item (@ShortRangeItems) {
        $ShortRangeLines[0].=ItemName($item);
        $ShortRangeLines[1].=FormatName1stLine($item);
        $ShortRangeLines[2].=FormatName2ndLine($item);
        $ShortRangeLines[3].="------";
        for ($z=0;$z<=$#{$setup{'range_list_short'}};$z++) {
            $range=$setup{'range_list_short'}[$z];
            $ShortRangeLines[$z+4].=FormatCorrection(GetRange($item,$range));
        }
    }
}

# Deciding which has more lines (to fill with appropriate number of space shorter output)
my $filler;
if ( ($#LongRangeItems >= 0) and ($#ShortRangeItems >= 0)) {
    if ($#LongRangeLines > $#ShortRangeLines) {
        $filler = sprintf("%*s", length($ShortRangeLines[3]), "");
        foreach $z ($#LongRangeLines - $#ShortRangeLines .. $#LongRangeLines) {
            push(@ShortRangeLines, $filler);
        }
    }
    elsif ($#LongRangeLines < $#ShortRangeLines) {
        $filler = sprintf("%*s", length($LongRangeLines[3]), "");
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
        print "ERROR: Calling GetRange with not enough arguments (",join(',',@GR_tmp),"). Exiting.\n";
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
        print "ERROR: SplitItems input missing elements (",$SI_in,"). Exiting.\n";
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
    my $FCin="";
    $FCin=shift @_;
    if ($FCin eq "") {
        return "      "
    } elsif ($FCin=~/\?/) {
        return sprintf("% 6s",$FCin);
    } else {
        return sprintf("%6.2f",$FCin);
    }
}

sub FormatName1stLine {
    my $FN_in=shift @_;
    my $FN_weapon=GetWeapon($FN_in);
    my $FN_ammo=GetAmmo($FN_in);
    my $FN_name=$weapons->{$FN_weapon}->{'ammo'}->{$FN_ammo}->{'abbrev'};
    my @FNtbl=split(' ',$FN_name);

    return " ".sprintf("%5s",substr($FNtbl[0],0,5));
}

sub FormatName2ndLine {
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
    #my @IN_tbl=split(' ',$weapons->{$IN_weapon}->{'abbrev'});
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
    # my $i;
    # my @RLtmp_tbl;
    # my $RLline;
    # my $RLfh;

    my $yamlref=LoadFile($setup{'library'}) or die "ERROR: Cannot open library file (".$setup{'library'}."). Exiting.";

    $scopes=$yamlref->{'scope'};
    $weapons=$yamlref->{'weapon'};
    if (length($weapons) < 1 ) {
        print "ERROR: No weapons in library (".$setup{'library'}."). Exiting.\n";
        exit(1);
    }
    if (length($scopes) < 1 ) {
        print "ERROR: No scopes in library (".$setup{'library'}."). Exiting.\n";
        exit(1);
    }

    # open $RLfh,$setup{'library'} or die "ERROR: Cannot open library file (".$setup{'library'}."). Exiting.";
    # while ($RLline=<$RLfh>) {
    #     @RLtmp_tbl=[];
    #     $RLline=~tr/[\r\n]//d;
    #     if ($RLline=~/,/){
    #         @RLtmp_tbl=split(',',$RLline,-1);
    #         $RLtmp_tbl[0]=toUpper($RLtmp_tbl[0]);
    #         $lib_name{$RLtmp_tbl[0]} = $RLtmp_tbl[1];
    #         for ($i=2;$i<=$#RLtmp_tbl;$i=$i+2) {
    #             $lib_correction{$RLtmp_tbl[0]}{$RLtmp_tbl[$i]} = $RLtmp_tbl[$i+1];
    #             #print $RLtmp_tbl[0]," ",$lib_name{$RLtmp_tbl[0]}," ",$RLtmp_tbl[$i]," [",$lib_correction{$RLtmp_tbl[0]}{$RLtmp_tbl[$i]},"]\n";
    #         }
    #     }
    # }
}

sub GetArgs {
	my @ARG_LIST=@ARGV;
	my $arg;
	my $i=0;
	for ($i=0;$i<=$#ARG_LIST;$i++) {
		$arg=$ARG_LIST[$i];
		if (($arg eq '-h') or ($arg eq 'help') or ($arg eq '--help')) {
			PrintHelp();
			exit(0);
		} elsif ($arg eq '-l') {
            $setup{'printlegend'} = 1;
		} elsif ($arg eq '-i'){
			$setup{'library'} = $ARG_LIST[$i+1];
			$i++;
		} elsif ($arg eq '-o') {
            $setup{'output_file'} = $ARG_LIST[$i + 1];
            $i++;
        } elsif ($arg eq '-s') {
            $setup{'simulate'} = 1;
            $i++;
		} elsif ($arg eq '-c') {
			my $j;
			for ($j=$i+1;$j<=$#ARG_LIST;$j++) {
				if ($ARG_LIST[$j]=~/^-/) {
					$i=$j-1;
					last;
				} else {
				    if ($ARG_LIST[$j]=~/,/) {
				        push(@{$setup{'item_list'}}, split(',',$ARG_LIST[$j],-1));
				    } else {
					    push(@{$setup{'item_list'}}, $ARG_LIST[$j]);
					}
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
			print "ERROR: Unknown option ($arg). Exiting.\n";
			PrintHelp();
			exit(1);
		}
    }
    # Basic library parameter tests
    if ((!defined $setup{'library'}) and (!defined $setup{'library_legend'})) {
        print "ERROR: library and/ot library legend file not defined. Exiting.";
        exit(1);
    }
    if (! -e $setup{'library'}) {
        print "ERROR: $setup{'library'} library file does not exist. Exiting.\n";
        exit(1);
    }

    ReadLibrary();

    if ($setup{'printlegend'} == 1) {
        PrintLibraryLegend();
        exit(0);
    }

    # Input item parameter test
    if ($#{$setup{'item_list'}} == -1) {
        print "ERROR: Empty item list. Exiting.";
        exit(1);
    }
}

sub PrintHelp {
    print << "XXX";
range_card_parser v.$version

The Hunter Classic custom overlay reticles range cards formatter.
Program parses library range card into smaller hunt-specific range card.
By default data form Range Cards/Universal Reticle MRAD.txt are cut into
Range Cards/hunt/range_card.txt file.

Usage:
       range_card_parser[.exe|.pl] <options> -c <CSV Weapon/Ammo/Optics list>

Options:
        -c : Weapon/Ammo/Optics items for hunt (comma separated)
        -i : Range Card library file [data/Universal Reticle MRAD.txt]
        -o : Output range card file [hunt/range_card.txt]
        -l : Print optics/weapon combinations in library
        -rl: Range list for long ranges [150,175,200,225,250,275,300,325]
        -rs: Range list for short ranges [10,20,30,40,50,60,80,100]
        -s : Simulate parsing, print to STDOUT
        -h : This help

Example:
        range_card_parser[.exe|.pl] -c ".17LA/.17HMR/12x56" "CroPis/Arrow/2xCroPis"
        range_card_parser[.exe|.pl] -c ".223BA/.223/5-22x56" "ParkerPython/Arrow/5pinPython" -rl 150,200,300 -rs 20,40,60

XXX

}

sub PrintLibraryLegend {
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

    my @tmp_pairs;
    my $weapon;
    my $ammo;
    my $scope;

    print "--- Library: ",$setup{'library'},"\n\n";

    print "-- Scopes (id name):\n";
    foreach $scope (sort keys %{$scopes}) {
        printf("\t%-15s   %s\n", $scope,$scopes->{$scope}->{'name'});
    };
    print "\n";
    print "-- Weapons (id name):\n";
    foreach $weapon (sort keys %{$weapons}) {
        printf ("\t%-15s   %s\n",$weapon,$weapons->{$weapon}->{'name'});
    };
    print "\n";

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
        printf("\t%-35s    %s\n",$tmp_pairs[$i],$tmp_pairs[$i+1]);
    }

}