#!/c/opt/Perl/perl/bin/perl

use YAML::XS qw{LoadFile};
use Data::Dumper qw{Dumper};

my $arrayref=LoadFile("../../data/Universal Reticle MRAD.yml");

my $scopes=$arrayref->{'scope'};
my $weapons=$arrayref->{'weapon'};

#print Dumper($scopes),"\n";
#print Dumper($weapons),"\n";
my @tmp_pairs;
my $weapon;
my $ammo;
my $scope;

print "Scopes (id name):\n";
foreach $scope (sort keys %{$scopes}) {
    printf("\t%-15s   %s\n", $scope,$scopes->{$scope}->{'name'});
};
print "\n";
print "Weapons (id name):\n";
foreach $weapon (sort keys %{$weapons}) {
    printf ("\t%-15s   %s\n",$weapon,$weapons->{$weapon}->{'name'});
};
print "\n";

print "Sets (weapon/ammo/scope   ranges):\n";
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

