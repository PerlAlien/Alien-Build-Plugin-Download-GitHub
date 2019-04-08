package Alien::Build::Plugin::Download::GitHub;

use strict;
use warnings;
use 5.008001;
use Carp qw( croak );
use Path::Tiny qw( path );
use JSON::PP qw( decode_json );
use Alien::Build::Plugin;
use Alien::Build::Plugin::Download::Negotiate;

# ABSTRACT: Alien::Build plugin to download from GitHub
# VERSION

=head1 SYNOPSIS

 use alienfile;

 ...

 share {
 
   plugin 'Download::GitHub' => (
     github_user => 'Perl5-Alien',
     github_repo => 'dontpanic',
   );
 
 };

=head1 DESCRIPTION

This plugin will download releases from GitHub.  It is generally preferred over
L<Alien::Build::Plugin::Download::Git> for packages that are released on GitHub,
as it has much fewer dependencies and is more reliable.

=head1 PROPERTIES

=head2 github_user

The GitHub user or org that owns the repository.

=head2 github_repo

The GitHub repository name.

=head2 version

Regular expression that can be used to extract a version from a GitHub tag.  The
default ( C<qr/^v?(.*)$/> ) is reasonable for many GitHub repositories.

=head2 prefer

How to sort candidates for selection.  This should be one of three types of values:

=over 4

=item code reference

This will be used as the prefer hook.

=item true value (not code reference)

Use L<Alien::Build::Plugin::Prefer::SortVersions>.

=item false value

Don't set any preference at all.  A hook must be installed, or another prefer plugin specified.

=back

=cut

has github_user => sub { croak("github_user is required") };
has github_repo => sub { croak("github_repo is required") };
has version => qr/^v?(.*)$/;
has prefer => 1;

sub init
{
  my($self, $meta) = @_;

  if(defined $meta->prop->{start_url})
  {
    croak("Don't set set a start_url with the Download::GitHub plugin");
  }

  $meta->prop->{start_url} ||= "https://api.github.com/repos/@{[ $self->github_user ]}/@{[ $self->github_repo ]}/releases";

  $meta->apply_plugin('Download',
    prefer  => $self->prefer,
    version => $self->version,
  );
  $meta->apply_plugin('Extract',
    format  => 'tar.gz',
  );

  $meta->around_hook(
    fetch => sub {
      my $orig = shift;
      my($build, $url) = @_;
      my $res = $orig->($build, $url);
      if($res->{type} eq 'file' && $res->{filename} eq 'releases')
      {
        my $rel;
        if($res->{content})
        {
          $rel = decode_json $res->{content};
        }
        elsif($res->{path})
        {
          $rel = path($res->{path})->slurp_utf8;
        }
        else
        {
          croak("malformed response object: no content or path");
        }
        return {
          type => 'list',
          list => [
            map {
              my %h = (
                filename => $_->{tag_name},
                url      => $_->{tarball_url},
                version  => $_->{tag_name},
              );
              \%h;
            } @$rel
          ],
        };
      }
      else
      {
        return $res;
      }
    },
  );

}

1;
