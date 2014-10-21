#!/usr/bin/env plackup

use strict;
use warnings;

BEGIN {
    use Cwd qw(getcwd);
    $ENV{PERLDOC_SERVER_HOME} ||= getcwd();
    my %seen; $seen{$_}++ for @INC;
    for my $p5 (grep $ENV{$_}, qw(PERLBREW_ROOT PERL_LOCAL_LIB_ROOT)) {
	$seen{$_}++ for grep /^$ENV{$p5}/, split ':', $ENV{PATH};
    }
    $ENV{PERLDOC_SERVER_SEARCH_PATH} = join "\n", sort keys %seen;
}

use Perldoc::Server;
my $perldoc = Perldoc::Server->apply_default_middlewares(
    Perldoc::Server->psgi_app);

=begin comment

use Plack::Builder;

builder {
    enable "Plack::Middleware::Static",
        path => qr{\.(js|css|png|ico)$}, root => 'root';
    mount "/perldoc" => $perldoc;
};

=end comment

=cut
