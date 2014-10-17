#!/usr/bin/env plackup

use strict;
use warnings;

BEGIN {
    use Cwd qw(getcwd);
    $ENV{PERLDOC_SERVER_HOME} ||= getcwd();
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
