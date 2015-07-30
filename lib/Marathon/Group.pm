package Marathon::Group;

use strict;
use warnings;
use parent 'Marathon::App';

sub new {
    my ($class, $conf) = @_;
    return bless {};
}

1;
