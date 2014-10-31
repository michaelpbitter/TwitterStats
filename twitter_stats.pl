#!/usr/bin/perl

use strict;
use warnings;

use Dancer;
use HTML::Entities;
use Net::Twitter::Lite::WithAPIv1_1;

use constant +{
 	CONSUMER_KEY => 'FpVsm5yKBW7DYJ6kZPJcrrVCP',
 	CONSUMER_SECRET => 'UJDRk3dTVc6JE5Ky3K7Msd1PYnjMIKXfMQ4zgWHTvr1oThRDdO',
 	TOKEN => '2872638300-ZJvdvTUPA7EZMWdftuik7mMwvWt4H27t5HgkFIV',
 	TOKEN_SECRET => 'SL2SgHZxx13Vev16Ufdt3AhMOftwxZCYS5LEMDVnC943p',
};

my $nt = Net::Twitter::Lite::WithAPIv1_1->new(
    consumer_key        => CONSUMER_KEY,
    consumer_secret     => CONSUMER_SECRET,
    access_token        => TOKEN,
    access_token_secret => TOKEN_SECRET,
    ssl                 => 1,
);

get('/', sub {
  return <<HTML;
<!DOCTYPE html>
<html>
  <body>
    <h2>Lookup Recent Tweets</h2>
    <form name="input1" action="tweets" method="post">
      Username: <input type="text" name="user">
      <input type="submit" value="Submit">
    </form>
    <p />
    <h2>Find Common Friends</h2>
    <form name="input2" action="common_friends" method="post">
      Username1: <input type="text" name="user1"> Username2: <input type="text" name="user2">
      <input type="submit" value="Submit">
    </form>
  </body>
</html>
HTML
});

post('/tweets', sub {
  my $user = param('user');

  unless ($user) {
  	return "No user specified";
  }

  my $ret = $nt->user_timeline({screen_name => [$user]});
  # XXX error checking should go here, but Net::Twitter::Lite::WithAPIv1_1 has minimal
  #     support for error handling.
  my @tweets = map { encode_entities($_->{text}) } @$ret;
  my $output = join "\n", (
  	'<table>',
  	(map { "  <tr><td>$_</td></tr>" } @tweets),
  	'</table>',
  );

  return join "\n", (
    '<!DOCTYPE html>',
    '<html>',
    '<body>',
    $output,
    '</body>',
    '</html>',
  );
});

post('/common_friends', sub {
  my ($user1, $user2) = (param('user1'), param('user2'));

  unless ($user1 && $user2) {
    return 'Invalid inputs: ' . ($user1 || '&lt;empty&gt;') . ' & ' . ($user2 || '&lt;empty&gt;')
  }
  if ($user1 eq $user2) {
    return "Nice try, both user1 and user2 are the same user ($user1)";
  }

  my @friends1 = get_friends($user1);
  my @friends2 = get_friends($user2);
  my @intersect = intersection(\@friends1, \@friends2);

  my $users = $nt->lookup_users({user_id => \@intersect});
  my $output = join "\n", (
    '<table>',
    (map { "  <tr><td>$_->{name}</td></tr>" } @$users),
    '</table>',
  );

  return join "\n", (
    '<!DOCTYPE html>',
    '<html>',
    '<body>',
    $output,
    '</body>',
    '</html>',
  );
});

sub intersection {
  my ($list1, $list2) = @_;
  my %hash;
  $hash{$_}++ foreach @$list1;
  return grep { $hash{$_}-- > 0 } @$list2;
}

sub get_friends {
  my ($user) = @_;
  my ($ret, @friends);
  do {
    $ret = $nt->friends_ids({
      screen_name => $user, 
      count => 5000,
      cursor => $ret->{next_cursor} // -1,
    });
    push @friends, @{$ret->{ids}};
  } while ($ret->{next_cursor});
  return @friends;
}

dance;