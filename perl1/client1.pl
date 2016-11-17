use strict;
use warnings;
use IO::Socket::INET;
use Getopt::Long;

my ($port, $host);
my $nick = "Guest";
my $MAXLEN  = 1024;

GetOptions( "port=i"    => \$port,
    	    "host=s"	=> \$host,
            "nick=s"    => \$nick);

die "Need Port!\n" unless defined $port;
die "Need host!\n" unless defined $host;




if($child = fork) {
    while(1) {
        $sock->recv($_, $MAXLEN) or die "recv: $!\n";
        print "$_\n";
        next;
    }
}

die "fork: $!\n" unless defined $child;

print "Connected as $nick to $host:$port\n";
$sock->send("/nick $nick") or die "send: $!\n";

while(<STDIN>) {
    chomp;
    $sock->send($_) or die "send: $!\n";
}