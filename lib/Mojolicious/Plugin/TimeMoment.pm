package Mojolicious::Plugin::TimeMoment;

use Mojo::Base 'Mojolicious::Plugin';
use Scalar::Util ('looks_like_number');
use Mojo::Util ('monkey_patch');
use Time::Moment;
use Time::y2038 ();

monkey_patch 'Time::Moment', then => sub {
  return $_[0]->from_epoch( $_[1] )->with_offset_same_instant( int( ( Time::y2038::timegm( Time::y2038::localtime( $_[1] ) ) - $_[1] ) / 60 ) );
};

monkey_patch 'Time::Moment', dts => sub {
  my $tm = $_[0]->from_string( $_[1] );
  return $tm->with_offset_same_instant( int( ( Time::y2038::timegm( Time::y2038::localtime( $tm->epoch ) ) - $tm->epoch ) / 60 ) );
};

monkey_patch 'Time::Moment', at_end_of_day => sub {
  return $_[0]->with_hour( 23 )->with_minute( 59 )->with_second( 59 )->with_nanosecond( 999999999 );
};

our $VERSION = '0.09';

sub register {
  my ( $self, $app, $conf ) = @_;

  $app->helper( tm => sub {
    shift;
    return Time::Moment->now unless $_[0];
    return Time::Moment->then($_[0]) if looks_like_number($_[0]);
    return Time::Moment->dts($_[0]);
  });

  $app->helper( tmc => sub {
    return 'Time::Moment';
  });

  # If formats provided, format names become Time::Moment instance methods using Time::Moment's strftime function.
  if ( keys %$conf ) {
    for my $method ( keys %$conf ) {
      monkey_patch 'Time::Moment', $method => sub { shift->strftime( $conf->{$method} ) };
    }
  }
}

1;
__END__

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::TimeMoment - Adds a Time::Moment object as a helper.

=head1 VERSION

0.09

=head1 SYNOPSIS

  # Mojolicious:

  $ENV{TZ} = 'America/Chicago';
  POSIX::tzset();

  $app->plugin( 'TimeMoment' => {
    dt_mdy => '%D, %-l:%M %p',
    basic_date_time => '%B %-e, %Y %-l:%M %p',
    timestamp => '%a, %d %b %Y %H:%M:%S GMT',
  });

  # Controllers: Create Time::Moment objects.

  my $tm1 = $c->tm;
  my $tm2 = $c->tm( 1465483062 );
  my $tm3 = $c->tm( '2016-06-09T09:37:42-05' );

  my $tm4 = $c->tmc->now_utc;
  my $tm5 = $c->tmc->from_string( '2016-06-09T09:37:42-05' );

  # Templates: Use created objects, or use the helper.

  %= $tm1->timestamp
  %= $tm2->month
  %= $tm3->year
  %= tm->basic_date_time
  %= tm(1465483062)->dt_mdy
  %= tm('2016-06-09T09:37:42-05')->dt_mdy

=head1 DESCRIPTION

Time::Moment is a great module and fast. Mojolicious::Plugin::TimeMoment uses this module as a plugin.

=head1 METHODS

=head2 register

  $app->plugin( 'TimeMoment' );

  $app->plugin( 'TimeMoment' => {
    $format_name1 => $custom_strftime_format1,
    $format_name2 => $custom_strftime_format2,
  });

Registers the plugin into the Mojolicious app.

=head1 HELPERS

=head2 tm

  $c->tm;           # TimeMoment->now, offset set to system's time zone offset
  $c->tm( $epoch ); # TimeMoment->then( $epoch ), offset set to system's time zone offset
  $c->tm( $dts );   # TimeMoment->dts( $dts ), offset set to system's time zone offset

Used to create a Time::Moment object. Time::Moment has several constructors. Used without any parameters, the localized "now" constructor creates the object. Pass in an epoch, the "then" constructor is used (this is a new constructor added to Time::Moment with the offset set to the system's time zone offset from UTC). Pass in a date timestamp, the "dts" constructor is used (this is a new constructor added to Time::Moment with the offset set to the system's time zone offset from UTC).

=head2 tmc

  $c->tmc->now_utc;                # offset set to UTC
  $c->tmc->from_string( $string ); # offset set to UTC

Use any of the Time::Moment constructors.

=head2 "custom_date_formats"

The following configuration creates custom instance methods.

  $app->plugin( 'TimeMoment' => {
    dt_mdy => '%D, %-l:%M %p',
    basic_date_time => '%B %-e, %Y %-l:%M %p',
    unconventional_date => 'This is a %A in %B, to be more precise %d/%m of %Y.',
  });

  % my $tm = $c->tm( 1465483062 );
  <%= $tm->dt_mdy %> is "06/09/16, 9:37 AM"
  <%= $tm->basic_date_time %> is "June 9, 2016 9:37 AM"
  <%= $tm->unconventional_date %> is "This is a Thursday in June, to be more precise 09/06 of 2016."

  <%= tm( 1465483062 )->dt_mdy %> is "06/09/16, 9:37 AM"
  <%= tm( 1465483062 )->basic_date_time %> is "June 9, 2016 9:37 AM"
  <%= tm( 1465483062 )->unconventional_date %> is "This is a Thursday in June, to be more precise 09/06 of 2016."

=head2 ADDITIONS TO TIME::MOMENT CONSTRUCTORS

=head2 then

    $tm = Time::Moment->then(1234567890);

Constructs an instance of C<Time::Moment> that is set to the epoch input in the system time zone, with the offset set to the system's time zone offset from UTC.

=head2 ADDITIONS TO TIME::MOMENT INSTANCE METHODS

=head2 at_end_of_day

    $tm2 = $tm1->at_end_of_day;

Returns a copy of this instance with the time of day set to the very end of the day (T23:59:59). This method is equivalent to:

    $tm2 = $tm1->with_hour(23)
               ->with_minute(59)
               ->with_second(59)
               ->with_nanosecond(999999999);

=head1 SOURCE REPOSITORY

L<http://github.com/keenlinks/Mojolicious-Plugin-TimeMoment>

=head1 AUTHOR

Scott Kiehn E<lt>sk.keenlinks@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2016 - Scott Kiehn

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Time::Moment>

=cut