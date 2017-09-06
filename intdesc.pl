#!/usr/bin/perl -w
#
use Net::SNMP qw(:snmp);
use Getopt::Std;
use XML::Dumper;
use strict;

##########
# Changeable Variables
##########
my $options = {};
getopts("h:c: ", $options);
##########
# Changeable Variables
##########

# snmpbulkwalk -v 2c -c SSCsnmpR0 10.49.0.10 IF-MIB::ifDescr

my $ifDesc = '1.3.6.1.2.1.2.2.1.2';
$\ = "\n";


my ($session, $error) = Net::SNMP->session(
                           -hostname      => $$options{h},
                           -port          => 161,
                           -version       => 2,
                           -community     => $$options{c},   # v1/v2c  
                        );

my $inthashref = $session->get_entries( -columns => [ $ifDesc ] );

die $error if $error;

map {print $_ . "\t" . $$inthashref{$_} } keys %$inthashref
