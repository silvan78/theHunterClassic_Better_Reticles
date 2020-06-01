#!/usr/bin/perl

my %setup={};

# Defaults
$setup->{'library'} = '../../Universal Reticle MRAD.txt';
$setup->{'library_legend'} = '../../Universal Reticle MRAD legend.txt';
$setup->{'output_file'} = '../../hunt/range_card.txt';
$setup->{'item_list'} = [];

if ($#ARGV < 0) {
    print "ERROR: No argument given. Exiting.\n\n";
    PrintHelp();
    PrintLibrary();
    exit(1);
}

GetArgs();

print join(',',@{$setup->{'item_list'}}),"\n";


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
			$setup->{'library'} = $ARG_LIST[$i+1];
			$i++;
		} elsif ($arg eq '-ii') {
			$setup->{'library_legend'} = $ARG_LIST[$i+1];
			$i++;
		} elsif ($arg eq '-o') {
			$setup->{'output_file'} = $ARG_LIST[$i+1];
			$i++;
		} elsif ($arg eq '-c') {
			my $j;
			for ($j=$i+1;$j<=$#ARG_LIST;$j++) {
				if ($ARG_LIST[$j]=~/^-/) {
					$i=$j-1;
					last;
				} else {
					push(@{$setup->{'item_list'}}, $ARG_LIST[$j]);
				}
				if ($j==$#ARG_LIST) {
					$i=$j;
				}
			}
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
        -h : This help

Example:
        range_card_parser -c "S1/.17HMR" "C1/CroPis"

XXX

}

sub PrintLibrary {
    my @PL_file;
    open (LIB_LEGEND,$setup->{'library_legend'}) or die "ERROR: Cannot open library legend file (".$setup->{'library_legend'}."). Exiting.";
    @PL_file=<LIB_LEGEND>;
    print "--- Library legend: ",$setup->{'library_legend'},"\n";
    print @PL_file;
    close (LIB_LEGEND);
}