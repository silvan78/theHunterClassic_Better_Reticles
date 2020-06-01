#!/usr/bin/perl

use POSIX qw(strftime);

my $today = strftime"%Y%m%d", localtime;
my %setup=();
my %lib_name=();
my %lib_correction=();

# Defaults
$setup{'library'} = '../../Universal Reticle MRAD.txt';
$setup{'library_legend'} = '../../Universal Reticle MRAD legend.txt';
$setup{'output_file'} = '../../hunt/range_card.txt';
$setup{'item_list'} = [];
$setup{'range_list_long'} = [150,175,200,225,250,275,300,325];
$setup{'range_list_short'} = [10,20,30,40,50,60,80,100];

if ($#ARGV < 0) {
    print "ERROR: No argument given. Exiting.\n\n";
    PrintHelp();
    PrintLibrary();
    exit(1);
}

GetArgs();

#print "ITEMS: ",join(',',@{$setup{'item_list'}}),"\n";
#print "LONG: ",join('-',@{$setup{'range_list_long'}}),"\n";
#print "SHORT: ",join('-',@{$setup{'range_list_short'}}),"\n";

ReadLibrary();

#print "LIBRARY NAMES: ",join(',',sort keys %lib_name),"\n";
#
#print "LIBRARY RANGES: \n";

#foreach $tmp (sort keys %lib_correction) {
#    print "$tmp";
#    foreach $tmpX (sort keys %{$lib_correction{$tmp}}) {
#        print " $tmpX $lib_correction{$tmp}{$tmpX}";
#    }
#    print "\n";
#}
#print "<",ItemCode("C1/TENPOINT"),">\n<",FormatName(ItemName("C1/TENPOINT")),">\n[",FormatCorrection($lib_correction{"C1/TENPOINT"}{'10'}),"]\n";

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

# Printing range card
open (OUT,">$setup{'output_file'}") or die "ERROR: Cannot write to output file ($setup{'output_file'}. Exiting.";
print {OUT} "Universal Reticle MRAD Range Card $today\n\n";

@LongRangeLines=();
@ShortRangeLines=();
push(@LongRangeLines,"     ");
push(@LongRangeLines,"LONG ");
push(@LongRangeLines,"----+");
foreach $range (@{$setup{'range_list_long'}}){
    push(@LongRangeLines,FormatRangeLong($range)."|");
}
foreach $item (@LongRangeItems) {
    $LongRangeLines[0].=ItemCode($item);
    $LongRangeLines[1].=FormatName($lib_name{$item});
    $LongRangeLines[2].="------";
    my $z;
    for ($z=0;$z<=$#{$setup{'range_list_long'}};$z++) {
        $range=$setup{'range_list_long'}[$z];
        $LongRangeLines[$z+3].=FormatCorrection($lib_correction{$item}{$range});
    }
}

push(@ShortRangeLines,"     ");
push(@ShortRangeLines,"SHORT");
push(@ShortRangeLines,"----+");
foreach $range (@{$setup{'range_list_short'}}){
    push(@ShortRangeLines,FormatRangeShort($range)."|");
}
foreach $item (@ShortRangeItems) {
    $ShortRangeLines[0].=ItemCode($item);
    $ShortRangeLines[1].=FormatName($lib_name{$item});
    $ShortRangeLines[2].="------";
    my $z;
    for ($z=0;$z<=$#{$setup{'range_list_short'}};$z++) {
        $range=$setup{'range_list_short'}[$z];
        $ShortRangeLines[$z+3].=FormatCorrection($lib_correction{$item}{$range});
    }
}

#deciding which has more lines
my $filler_length;
if ($#LongRangeLines > $#ShortRangeLines) {
    $filler=sprintf("%*s",length($ShortRangeLines[2]),"");
    foreach $z ($#LongRangeLines-$#ShortRangeLines .. $#LongRangeLines) {
        push(@ShortRangeLines,$filler);
    }
} elsif ($#LongRangeLines < $#ShortRangeLines) {
    $filler=sprintf("%*s",length($LongRangeLines[2]),"");
    foreach $z ($#ShortRangeLines-$#LongRangeLines .. $#ShortRangeLines) {
        push(@LongRangeLines,$filler);
    }
}

#joining output
foreach $z (0..$#LongRangeLines){
    print {OUT} "$LongRangeLines[$z]    $ShortRangeLines[$z]\n"
}


# Subs
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
    open(LIB,$setup{'library'}) or die "ERROR: Cannot open library file (".$setup{'library'}."). Exiting.";
    while ($RLline=<LIB>) {
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
			PrintLibrary();
			exit(0);
		} elsif ($arg eq '-i'){
			$setup{'library'} = $ARG_LIST[$i+1];
			$i++;
		} elsif ($arg eq '-ii') {
			$setup{'library_legend'} = $ARG_LIST[$i+1];
			$i++;
		} elsif ($arg eq '-o') {
			$setup{'output_file'} = $ARG_LIST[$i+1];
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
}

sub PrintHelp {
    print << "XXX";
range_card_parser <options> <optics/weapon list>

Program parses library range card into smaller range card file for specific hunt.
By default data form Universal Reticle MRAD.txt are cut into hunt/range_card.txt
file.

Options:
        -c : Calibre/optics items for hunt
        -i : Range Card library file [Universal Reticle MRAD.txt]
        -ii: Range Card library legend file [Universal Reticle MRAD legend.txt]
        -o : Output range card file [hunt/range_card.txt]
        -l : Print optics/weapon combinations in library
        -rl: Range list for long ranges [150,175,200,225,250,275,300,325]
        -rs: Range list for short ranges [10,20,30,40,50,60,80,100]
        -h : This help

Example:
        range_card_parser -c "S1/.17HMR" "C1/CroPis"
        range_card_parser -c "S1/.17HMR" "C1/CroPis" "M1/6.5x55" -rl 150,200,300 -rs 20,40,60

XXX

}

sub PrintLibrary {
    my @PL_file;
    open (LIB_LEGEND,$setup{'library_legend'}) or die "ERROR: Cannot open library legend file (".$setup{'library_legend'}."). Exiting.";
    @PL_file=<LIB_LEGEND>;
    print "--- Library legend: ",$setup{'library_legend'},"\n";
    print @PL_file;
    close (LIB_LEGEND);
}