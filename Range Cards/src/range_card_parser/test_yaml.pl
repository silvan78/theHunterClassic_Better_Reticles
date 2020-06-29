#!/e/opt/Perl/perl/bin/perl

use YAML::XS;
use Data::Dumper;

my $arrayref=YAML::XS::LoadFile("../../data/Universal Reticle MRAD.yml");

my $scopes=$arrayref->{'scope'};
my $weapons=$arrayref->{'weapon'};

print Dumper($scopes),"\n";
print Dumper($weapons),"\n";
