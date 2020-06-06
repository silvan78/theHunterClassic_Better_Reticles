# Install Strawberry Perl
# Run windows gui CPAN client
#> get pp
#> install pp
# or bash console from Strawberry installation directory cpanm.bat pp
# JUST SETUP PATH with path to gmake in c/bin

PERLPATH_BASE="/e/opt/Perl/"
ln -f ../range_card_parser.pl range_card_parser/range_card_parser.pl

export PATH="${PERLPATH_BASE}/perl/bin:${PERLPATH_BASE}/perl/site/bin:${PERLPATH_BASE}/perl/vendor/bin:${PERLPATH_BASE}/c/bin:$PATH"
export PERL5LIB="${PERLPATH_BASE}/perl/lib:${PERLPATH_BASE}/perl/site/lib:${PERLPATH_BASE}/perl/vendor/lib"

perl /e/opt/Perl/perl/site/bin/pp -o ../range_card_parser.exe src/range_card_parser.pl


