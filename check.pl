#!/usr/bin/env perl

use strict;
use warnings;
use lib "./lib";
use Marathon;
use Data::Dumper;
use JSON::XS;

my $marathon = Marathon->new( url => "http://10.201.0.11:8080/");

print $marathon->ping ."\n";

my $app = $marathon->get_app('basic-3');

print $app->kill_tasks( { host => '10.201.0.13' } ) ."\n";

