#!/usr/bin/env perl

use strict;
use warnings;

use Perldoc::Server;
my $perldoc = Perldoc::Server->apply_default_middlewares(
    Perldoc::Server->psgi_app);
