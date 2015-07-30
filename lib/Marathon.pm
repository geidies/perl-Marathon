package Marathon;

use 5.006;
use strict;
use warnings;
use LWP::UserAgent;
use JSON::XS;
use Marathon::App;

=head1 NAME

Marathon - An object-oriented Mapper for the Marathon REST API

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
our $verbose = 0;


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Marathon;

    my $foo = Marathon->new();
    ...

=head1 SUBROUTINES/METHODS

=head2 new

Creates a Marathon object. You can pass in the URL to the marathon REST interface:
    
    use Marathon;
    my $marathon = Marathon->new( url => 'http://169.254.47.11:8080' )

=cut

sub new {
    my ($class, %conf) = @_;
    my $url = delete $conf{url} || 'http://localhost:8080/';
    $Marathon::verbose = delete $conf{verbose} || 0;
    my $ua = LWP::UserAgent->new;
    my $self = bless {
      _ua     => $ua,
    };
    $self->_set_url($url);
    return $self;
}

sub _set_url { # void
  my ($self, $url) = @_;
  unless ( $url =~ m,^https?\://, ) {
      $url = 'http://' . $url;
  }
  unless ( $url =~ m,/$, ) {
      $url .= '/';
  }
  $self->{_url} = $url;
}

=head2 ping

returns 1 if the master responds to a ping request.

=cut

sub get_app { # Marathon::App
    my ( $self, $id ) = @_;
    my $api_response = $self->_get_obj('/v2/apps/' . $id);
    return undef unless defined $api_response;
    return Marathon::App->new( $api_response->{app}, $self );
}

sub new_app {
    my ($self, $config) = @_;
    return Marathon::App->new( $config, $self );
}

sub get_group { # Marathon::App
    my ( $self, $id ) = @_;
    return Marathon::Group->get( $id, $self );
}

sub new_group {
    my ($self, $config) = @_;
    return Marathon::Group->new( $config, $self );
}

sub get_endpoint {
    my ( $self, $path ) = @_;
    my $url = $self->{_url} . $path;
    $url =~ s,/+,/,g;
    $url =~ s,^http:/,http://,;
    return $url;
}

sub metrics {
    my $self = shift;
    return $self->_get_obj('/metrics');
}

sub help { # string (html)
    my $self = shift;
    return $self->_get_html('/help');
}

sub logging { # string (html)
    my $self = shift;
    return $self->_get_html('/logging');
}

sub ping { # string (plaintext)
    my $self = shift;
    return $self->_get_html('/ping') =~ m,pong, ? 'pong' : undef;
}

sub _get { # HTTP::Response
    my ( $self, $path ) = @_;
    my $url = $self->get_endpoint( $path );
    my $response = $self->{_ua}->get( $url );
    $self->_response_handler( 'GET', $response );
    return $response;
}

sub _get_html { # string (html) or undef on error
    my ( $self, $path ) = @_;
    my $response = $self->_get($path);
    if ( $response->is_success ) {
        return $response->decoded_content;
    }
    return undef;
}

sub _get_obj { # hashref
    my ( $self, $path ) = @_;
    my $response = $self->_get_html($path);
    if ($response) {
        return decode_json $response;
    }
    return undef;
}

sub _post {
    my ($self, $path, $payload) = @_;
    return $self->_put_post_delete( 'POST', $path, $payload );
}

sub _put {
    my ($self, $path, $payload) = @_;
    return $self->_put_post_delete( 'PUT', $path, $payload );
}

sub _delete {
    my ($self, $path, $payload) = @_;
    return $self->_put_post_delete( 'DELETE', $path, $payload );
}

sub _put_post_delete {
    my ($self, $method, $path, $payload) = @_;
    my $req = HTTP::Request->new( $method, $self->get_endpoint($path) );
    if ( $payload ) {
        $req->header( 'Content-Type' => 'application/json' );
        $req->content( encode_json $payload );
    }
    my $response = $self->{_ua}->request( $req );
    $self->_response_handler( $method, $response );
    return $response->is_success ? $response->decoded_content : undef;
}

sub _response_handler {
    my ( $self, $method, $response ) = @_;
    unless ( $response->is_success ) {
        print STDERR 'Error doing '.$method.' against '. $response->base.': ' . $response->status_line . "\n";
        print STDERR $response->decoded_content ."\n";
    } else {
        if ( $verbose ) {
            print STDERR $response->status_line . "\n"
        }
    }
    return $response;
}

=head1 AUTHOR

Sebastian Geidies, C<< <seb at geidi.es> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-marathon at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Marathon>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Marathon


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Marathon>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Marathon>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Marathon>

=item * Search CPAN

L<http://search.cpan.org/dist/Marathon/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Sebastian Geidies.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Marathon
