#!/usr/bin/perl -w

# to run:
#
# RT_DBA_USER=root RT_DBA_PASSWORD= prove -lv -I/Users/clkao/work/bps/rt-3.7/lib t/sd-rt.t
use strict;

use Test::More;
eval 'use RT::Test; 1'
    or plan skip_all => 'requires 3.7 to run tests.'.$@;

use Prophet::Test tests => 10;

no warnings 'once';

RT::Handle->InsertData($RT::EtcPath.'/initialdata');
use Test::More;
BEGIN {
    require File::Temp;
    $ENV{'PROPHET_REPO'} = $ENV{'SVB_REPO'} =
        File::Temp::tempdir( CLEANUP => 0).'/_svb';
    warn $ENV{'PROPHET_REPO'};
}

my ($url, $m) = RT::Test->started_ok;

use RT::Client::REST;
use RT::Client::REST::Ticket;
my $rt = RT::Client::REST->new( server => $url );
$rt->login( username => 'root', password => 'password' );

$url =~ s|http://|http://root:password@|;
warn $url;
my $sd_rt_url = "rt:$url|General|Status!='resolved'";

my $ticket = RT::Client::REST::Ticket->new(
        rt => $rt,
        queue => 'General',
        status => 'new',
        subject => 'Fly Man',
    )->store(text => "Ticket Comment");

diag $ticket->id;
my ($ret, $out, $err);
($ret, $out, $err) = run_script('sd', ['pull', $sd_rt_url]);

my ($yatta_uuid, $flyman_uuid);
run_output_matches('sd', ['ticket', '--list', '--regex', '.'], [qr/(.*?)(?{ $flyman_uuid = $1 }) Fly Man new/]);


RT::Client::REST::Ticket->new(
        rt => $rt,
        id => $ticket->id,
        status => 'open',
    )->store();

($ret, $out, $err) = run_script('sd', ['pull', $sd_rt_url]);

run_output_matches('sd', ['ticket', '--list', '--regex', '.'], ["$flyman_uuid Fly Man open"]);

# create from sd and push

run_output_matches('sd', ['ticket', '--create', '--summary', 'YATTA', '--status', 'new'], [qr/Created ticket (.*)(?{ $yatta_uuid = $1 })/]);

diag $yatta_uuid;

run_output_matches('sd', ['ticket', '--list', '--regex', '.'],
                   [ 
                     "$flyman_uuid Fly Man open",
                    "$yatta_uuid YATTA new",
                   ]);

($ret, $out, $err) = run_script('sd', ['push', $sd_rt_url]);
warn $out;
warn $err;

($ret, $out, $err) = run_script('sd', ['pull', $sd_rt_url]);


run_output_matches('sd', ['ticket', '--list', '--regex', '.'],
                   [ 
                     "$flyman_uuid Fly Man open",
                    "$yatta_uuid YATTA new",
                   ]);


#diag $uuid;

1;




