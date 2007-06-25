#! /usr/bin/perl -w
#
# $Id: check_TcpConn.pl,v 1.2 2005/11/17 10:21:49 Sugumaran Mat $
#
# This plugin is developped under GPL Licence:
# http://www.fsf.org/licenses/gpl.txt
#
# Developped by Merethis SARL : http://www.merethis.com
#
# The Software is provided to you AS IS and WITH ALL FAULTS.
# MERETHIS makes no representation and gives no warranty whatsoever,
# whether express or implied, and without limitation, with regard to the quality,
# safety, contents, performance, merchantability, non-infringement or suitability for
# any particular or intended purpose of the Software found on the LINAGORA web site.
# In no event will MERETHIS be liable for any direct, indirect, punitive, special,
# incidental or consequential damages however they may arise and even if MERETHIS has
# been previously advised of the possibility of such damages.

##
## Plugin init
##

use strict;
use Net::SNMP qw(:snmp);
use FindBin;
use lib "$FindBin::Bin";
use lib "/srv/nagios/libexec";
use utils qw($TIMEOUT %ERRORS &print_revision &support);

if (eval "require oreon" ) {
    use oreon qw(get_parameters create_rrd update_rrd &is_valid_serviceid);
    use vars qw($VERSION %oreon);
    %oreon=get_parameters();
} else {
    print "Unable to load oreon perl module\n";
    exit $ERRORS{'UNKNOWN'};
}

use vars qw($PROGNAME);
use Getopt::Long;
use vars qw($opt_h $opt_V $opt_H $opt_C $opt_v $opt_p $opt_c $opt_w);
use vars qw($snmp);

$PROGNAME = "ckeck_TcpConn";
sub print_help ();
sub print_usage ();

Getopt::Long::Configure('bundling');
GetOptions
    ("h"   => \$opt_h, "help"         => \$opt_h,
     "v=s"   => \$opt_v, "snmp_version=s" => \$opt_v,
     "V"   => \$opt_V, "version"      => \$opt_V,
     "H=s"   => \$opt_H, "Hostname=s"     => \$opt_H,
     "p=s"   => \$opt_p, "port=s"         => \$opt_p,
     "C=s"   => \$opt_C, "Community=s"    => \$opt_C,
     "c=s"	=> \$opt_c, "w=s"	=> \$opt_w
);

if ($opt_V) {
    print_revision($PROGNAME,'$Revision: 1.0');
    exit $ERRORS{'OK'};
}

if ($opt_h) {
    print_help();
    exit $ERRORS{'OK'};
}

$opt_H = shift unless ($opt_H);
(print_usage() && exit $ERRORS{'OK'}) unless ($opt_H);

$opt_p = shift unless ($opt_p);
(print_usage() && exit $ERRORS{'OK'}) unless ($opt_p);

($opt_v) || ($opt_v = shift) || ($opt_v = "v1");
my $snmp = $1 if ($opt_v =~ /(\d)/);

if (!$opt_C){
	$opt_C = "public";
}
my $name = $0;
$name =~ s/\.pl.*//g;
my $day = 0;

#===  create a SNMP session ====
# 1.3.6.1.4.1.232.1.2.2.1.1.6

my ($session, $error) = Net::SNMP->session(-hostname  => $opt_H,-community => $opt_C, -version  => $snmp);
if (!defined($session)) {
    print("CRITICAL: $error");
    exit $ERRORS{'CRITICAL'};
}


my $OID_TCP_PORT = ".1.3.6.1.2.1.6.13.1.3";

my $result = $session->get_table(Baseoid => $OID_TCP_PORT);
if (!defined($result)) {
    printf("ERROR: Description Table : %s.\n", $session->error);
    $session->close;
    exit $ERRORS{'UNKNOWN'};
}

my $cpt = 0;

foreach my $key (oid_lex_sort(keys %$result)) {
	if ($result->{$key} eq $opt_p || $opt_p eq "all") {
 		$cpt++;
	}
}

if (!defined($opt_w)){$opt_w = 20;}
if (!defined($opt_c)){$opt_c = 30;}
if ($opt_p ne "all" ) { 
	print "Number of connections on port $opt_p :  $cpt |nb_conn=$cpt\n";
}else {
	print "Total connections : $cpt|nb_conn=$cpt\n"; 
}
if ($cpt >= $opt_w && $cpt < $opt_c){
	exit $ERRORS{'WARNING'};
} elsif ($cpt >= $opt_c){
	exit $ERRORS{'CRITICAL'};
} else {
	exit $ERRORS{'OK'};
}
	

sub print_usage () {
    print "\nUsage:\n";
    print "$PROGNAME\n";
    print "   -H (--hostname)   Hostname to query - (required)\n";
    print "   -p (--port)	port you want to check - (required)\n";
    print "   -C (--community)  SNMP read community (defaults to public,\n";
    print "                     used with SNMP v1 and v2c\n";
    print "   -v (--snmp_version)  1 for SNMP v1 (default)\n";
    print "                        2 for SNMP v2c\n";
    print "   -V (--version)    Plugin version\n";
    print "   -h (--help)       usage help\n";
}

sub print_help () {
    print "#=========================================\n";
    print "#  Copyright (c) 2005 Merethis SARL      =\n";
    print "#  Developped by Julien Mathis           =\n";
    print "#  Bugs to http://www.oreon-project.org/ =\n";
    print "#=========================================\n";
    print_usage();
    print "\n";
}

