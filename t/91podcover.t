#!perl -w
use strict;
use Test::More;
eval "use Test::Pod::Coverage;";
plan skip_all => "Test::Pod::Coverage required for POD coverage" if $@;

plan tests => 1;
pod_coverage_ok('Imager::Screenshot');
