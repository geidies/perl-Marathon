#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';
use Marathon;
use Marathon::Group;

my $marathon = Marathon->new( url => 'http://10.201.0.11:8080/' );

my $group = Marathon::Group->new();
$group->_bail();

my $app = $marathon->get_app( 'basic-3' );

$app->cpus( 0.4 );
$app->update;
