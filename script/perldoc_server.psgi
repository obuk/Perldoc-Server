BEGIN {
    use Cwd qw(getcwd);
    $ENV{PERLDOC_SERVER_HOME} ||= getcwd();
}

use Perldoc::Server;
my $perldoc = Perldoc::Server->apply_default_middlewares(
    Perldoc::Server->psgi_app);
