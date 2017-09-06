#!/usr/bin/perl -w
#
use Number::Format;
use Math::BigInt;
use Net::SNMP qw(:snmp);
use Getopt::Std;
#use XML::Dumper;
use strict;

##########
# Changeable Variables
##########
my $options = {};
getopts("h:c:i: ", $options);
my $delayinsecs = 5;
##########
# Changeable Variables
##########

# snmpbulkwalk -v 2c -c SSCsnmpR0 10.49.0.10 IF-MIB::ifDescr

my $breakblock = 0;
$SIG{INT} = sub { $breakblock = 1};
my $ifHCInOctets = '1.3.6.1.2.1.31.1.1.1.6';
my $ifHCOutOctets = '1.3.6.1.2.1.31.1.1.1.10';
my $inputoid = $ifHCInOctets . ".$$options{i}";
my $outputoid = $ifHCOutOctets . ".$$options{i}";
my $formatter = Number::Format->new();
$\ = "\n";


my ($session, $error) = Net::SNMP->session(
                           -hostname      => $$options{h},
                           -port          => 161,
                           -version       => 2,
                           -community     => $$options{c},   # v1/v2c  
                        );

my $inthashref = $session->get_request( -varbindlist => [ $inputoid, $outputoid ] );

die $error if $error;

my %basevalues = (
	'inbound' => Math::BigInt->new($$inthashref{$inputoid}),
	'outbound' => Math::BigInt->new($$inthashref{$outputoid})
	);

do {
	my $actualdelay = sleep $delayinsecs;
	$inthashref = $session->get_request( -varbindlist => [ $inputoid, $outputoid ] );

	my %newvalues = (
		'inbound' => Math::BigInt->new($$inthashref{$inputoid}),
		'outbound' => Math::BigInt->new($$inthashref{$outputoid})
		);

	my %differentials = ( 'inbound' => $newvalues{inbound}->copy(),
			'outbound' => $newvalues{outbound}->copy()
			);

	map {$differentials{$_}->bsub($basevalues{$_})} keys %differentials;
	map {$differentials{$_}->bdiv($actualdelay)} keys %differentials;
	map {$_->bmul(8)} values %differentials;

	print "Inbound: " . $formatter->format_bytes($differentials{inbound}->bstr()) . "bps"
		 . " Outbound: " . $formatter->format_bytes($differentials{outbound}->bstr()) . "bps"
		;

	%basevalues = (
		'inbound' => $newvalues{inbound},
		'outbound' => $newvalues{outbound},
		);
	
	} while ($breakblock == 0);

$session->close();

print "Caught SIGINT!";
