#!/e/opt/Perl/perl/bin/perl

use YAML::XS;
use Data::Dumper;

my $arrayref=YAML::XS::LoadFile("../../data/Universal Reticle MRAD.yml");

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

print "Sets (weapon/ammo/scope):\n\t";
foreach $weapon (sort keys %{$weapons}) {
    foreach $ammo (sort keys %{$weapons->{$weapon}->{'ammo'}}) {
        foreach $scope (sort keys %{$weapons->{$weapon}->{'ammo'}->{$ammo}->{'scope'}}) {
            push(@tmp_pairs,$weapon."/".$ammo."/".$scope);
        }

    }
}
print join("\n\t",@tmp_pairs),"\n";

