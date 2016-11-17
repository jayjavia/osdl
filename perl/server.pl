use strict;
use warnings;
use IO::Socket::INET;
use Getopt::Long;

my $MAXLEN = 1024;
my $PORTNO;

GetOptions("port=i" => \$PORTNO);
die "Need port!\n" unless defined $PORTNO;

my $sock = IO::Socket::INET->new(
        LocalPort   => $PORTNO, 
        Proto       => 'udp'
    ) or die "sock: $!";

print "Waiting for users on $PORTNO...\n";

my %clients;
my $msg;

while ($sock->recv($msg, $MAXLEN)) {
    my $ipaddr      = gethostbyaddr($sock->peeraddr, AF_INET);
    my $port        = $sock->peerport;
    my $cur_client  = "$ipaddr:$port";
    my $first_msg   = 0;

    if (not exists $clients{$cur_client}) {
        $clients{$cur_client}->{nick}       = "Guest";
        $clients{$cur_client}->{address}    = $ipaddr;
        $clients{$cur_client}->{port}       = $port; 
        $first_msg                          = 1;
    }

    if ($msg =~ /\/nick (\w+)/) {
        my $prev_nick = $clients{$cur_client}->{nick};
        $clients{$cur_client}->{nick} = $1;
        if ($first_msg) {                   # I feel like this section is a bit hackey, is there a better way of doing this?
            $msg = "[Server] new user: $1";
            $first_msg = 0;
        } else {
            $msg = "[Server] nick change: $prev_nick -> $1 ";
        }
    } else {
        $msg = join "", $clients{$cur_client}->{nick}, ": ", $msg;
    }

    print $msg, " ($cur_client)\n";

    for (keys %clients) {
        close $sock;
        my $sock_send = IO::Socket::INET->new(  # I feel like this should be unnecesary, is there a way of modifying 
            LocalPort   => $PORTNO,             # the existing $sock object instead of creating a new one each time
            Proto       => 'udp',               # I want to send a message?
            PeerAddr    => $clients{$_}->{address},
            PeerPort    => $clients{$_}->{port}
        ) or die "sock: $!";
        $sock_send->send($msg);
        close $sock_send;
    }

    $sock = IO::Socket::INET->new(
        LocalPort   => $PORTNO, 
        Proto       => 'udp'
    ) or die "sock: $!";
} 