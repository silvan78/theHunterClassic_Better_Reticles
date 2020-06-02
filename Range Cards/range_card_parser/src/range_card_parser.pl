#!/usr/bin/perl

use warnings;
use strict;
use POSIX qw(strftime);

my $version="1.01";

my $today = strftime"%Y%m%d", localtime;
my %setup=();
my %lib_name=();
my %lib_correction=();
my $item;
my $range;
my @LongRangeLines;
my @ShortRangeLines;
my $z;

# Defaults
$setup{'library'} = 'data/Universal Reticle MRAD.txt';
$setup{'library_legend'} = 'data/Universal Reticle MRAD legend.txt';
$setup{'output_file'} = 'hunt/range_card.txt';
$setup{'item_list'} = [];
$setup{'range_list_long'} = [150,175,200,225,250,275,300,325];
$setup{'range_list_short'} = [10,20,30,40,50,60,80,100];
$setup{'simulate'}=0;
$setup{'printlegend'}=0;

if ($#ARGV < 0) {
    print "ERROR: No argument given. Exiting.\n\n";
    PrintHelp();
    PrintLibraryLegend();
    exit(1);
}

GetArgs();

# Read Library data into %lib_names and %lib_correction

# Define Long Range Items
my @LongRangeItems=();
foreach $item (@{$setup{'item_list'}}) {
    foreach $range (sort @{$setup{'range_list_long'}}) {
        if (defined $lib_correction{$item}{$range}) {
            push(@LongRangeItems,$item);
            last;
        }
    }
}
# Define Short Range Items
my @ShortRangeItems=();
foreach $item (@{$setup{'item_list'}}) {
    foreach $range (sort @{$setup{'range_list_short'}}) {
        if (defined $lib_correction{$item}{$range}) {
            push(@ShortRangeItems,$item);
            last;
        }
    }
}

# Preparing range card print
@LongRangeLines=();
@ShortRangeLines=();
push(@LongRangeLines,"     ");
push(@LongRangeLines,"     ");
push(@LongRangeLines,"LONG ");
push(@LongRangeLines,"----+");
foreach $range (@{$setup{'range_list_long'}}){
    push(@LongRangeLines,FormatRangeLong($range)."|");
}
foreach $item (@LongRangeItems) {
    $LongRangeLines[0].=ItemCode($item);
    $LongRangeLines[1].=FormatName1stLine($lib_name{$item});
    $LongRangeLines[2].=FormatName2ndLine($lib_name{$item});
    $LongRangeLines[3].="------";
    for ($z=0;$z<=$#{$setup{'range_list_long'}};$z++) {
        $range=$setup{'range_list_long'}[$z];
        $LongRangeLines[$z+4].=FormatCorrection($lib_correction{$item}{$range});
    }
}
push(@ShortRangeLines,"     ");
push(@ShortRangeLines,"     ");
push(@ShortRangeLines,"SHORT");
push(@ShortRangeLines,"----+");
foreach $range (@{$setup{'range_list_short'}}){
    push(@ShortRangeLines,FormatRangeShort($range)."|");
}
foreach $item (@ShortRangeItems) {
    $ShortRangeLines[0].=ItemCode($item);
    $ShortRangeLines[1].=FormatName1stLine($lib_name{$item});
    $ShortRangeLines[2].=FormatName2ndLine($lib_name{$item});
    $ShortRangeLines[3].="------";
    for ($z=0;$z<=$#{$setup{'range_list_short'}};$z++) {
        $range=$setup{'range_list_short'}[$z];
        $ShortRangeLines[$z+4].=FormatCorrection($lib_correction{$item}{$range});
    }
}

# Deciding which has more lines (to fill with appropriate number of space shorter output)
my $filler;
if ($#LongRangeLines > $#ShortRangeLines) {
    $filler=sprintf("%*s",length($ShortRangeLines[3]),"");
    foreach $z ($#LongRangeLines-$#ShortRangeLines .. $#LongRangeLines) {
        push(@ShortRangeLines,$filler);
    }
} elsif ($#LongRangeLines < $#ShortRangeLines) {
    $filler=sprintf("%*s",length($LongRangeLines[3]),"");
    foreach $z ($#ShortRangeLines-$#LongRangeLines .. $#ShortRangeLines) {
        push(@LongRangeLines,$filler);
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
foreach $z (0..$#LongRangeLines){
    print {$out} "$LongRangeLines[$z]    $ShortRangeLines[$z]\n"
}



#######
# Subs
#######
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
    my $FNin=shift @_;
    my @FNtbl=split(' ',$FNin);
    return " ".sprintf("%5s",substr($FNtbl[0],0,5));
}

sub FormatName2ndLine {
    my $FNin=shift @_;
    my @FNtbl;
    if ($FNin=~/ /) {
        @FNtbl = split(' ', $FNin);
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
    my $ICin=shift @_;
    my @ICtmp=split('/',$ICin,-1);
    return "  (".$ICtmp[0].")";
}
sub ItemName {
    my $INin=shift @_;
    my @INtmp=split('/',$INin,-1);
    return $INtmp[1];
}

sub toUpper {
    my $tU = shift @_;
    $tU=~tr/{a-z}/{A-Z}/;
    return $tU;
}

sub ReadLibrary {
    my $i;
    my @RLtmp_tbl;
    my $RLline;
    my $RLfh;

    open $RLfh,$setup{'library'} or die "ERROR: Cannot open library file (".$setup{'library'}."). Exiting.";
    while ($RLline=<$RLfh>) {
        @RLtmp_tbl=[];
        $RLline=~tr/[\r\n]//d;
        if ($RLline=~/,/){
            @RLtmp_tbl=split(',',$RLline,-1);
            $RLtmp_tbl[0]=toUpper($RLtmp_tbl[0]);
            $lib_name{$RLtmp_tbl[0]} = $RLtmp_tbl[1];
            for ($i=2;$i<=$#RLtmp_tbl;$i=$i+2) {
                $lib_correction{$RLtmp_tbl[0]}{$RLtmp_tbl[$i]} = $RLtmp_tbl[$i+1];
                #print $RLtmp_tbl[0]," ",$lib_name{$RLtmp_tbl[0]}," ",$RLtmp_tbl[$i]," [",$lib_correction{$RLtmp_tbl[0]}{$RLtmp_tbl[$i]},"]\n";
            }
        }
    }
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
		} elsif ($arg eq '-ii') {
			$setup{'library_legend'} = $ARG_LIST[$i+1];
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
					    push(@{$setup{'item_list'}}, toUpper($ARG_LIST[$j]));
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

    # Basic input parameter tests
    if ($#{$setup{'item_list'}} == -1) {
        print "ERROR: Empty item list. Exiting.";
        exit(1);
    }
    if ((!defined $setup{'library'}) and (!defined $setup{'library_legend'})) {
        print "ERROR: library and/ot library legend file not defined. Exiting.";
        exit(1);
    }

    ReadLibrary();

    if ($setup{'printlegend'} == 1) {
        PrintLibraryLegend();
        exit(0);
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
       range_card_parser[.exe|.pl] <options> -c <optics/weapon list>

Options:
        -c : Calibre/optics/weapon index items for hunt
        -i : Range Card library file [Universal Reticle MRAD.txt]
        -ii: Range Card library legend file [Universal Reticle MRAD legend.txt]
        -o : Output range card file [hunt/range_card.txt]
        -l : Print optics/weapon combinations in library
        -rl: Range list for long ranges [150,175,200,225,250,275,300,325]
        -rs: Range list for short ranges [10,20,30,40,50,60,80,100]
        -s : Simulate parsing, print to STDOUT
        -h : This help

Example:
        range_card_parser[.exe|.pl] -c "L1/.17HMR" "S2/CroPis"
        range_card_parser[.exe|.pl] -c "M1/.17HMR" "S2/CroPis" "M1/6.5x55" -rl 150,200,300 -rs 20,40,60

XXX

}

sub PrintLibraryLegend {
    my $PLfh;
    my @PL_file;
    open $PLfh,"<",$setup{'library_legend'} or die "ERROR: Cannot open library legend file (".$setup{'library_legend'}."). Exiting.";
    @PL_file=<$PLfh>;
    print "--- Library legend: ",$setup{'library_legend'},"\n";
    print @PL_file;
    close ($PLfh);

    my $itemlist="Available combinations: ".join(', ',sort keys %lib_name)."\n";
    my $wrap_length = 100;
    my $wrapped_itemlist;
    ($wrapped_itemlist = $itemlist) =~s/(.{0,$wrap_length}(?:\s|$))/$1\n/g;
    print $wrapped_itemlist;
}