use Test2::V0 -no_srand => 1;
use Alien::Build::Plugin::Download::GitHub;
use Test::Alien::Build;

subtest 'basic load' => sub {

  alienfile_ok q{

    use alienfile;

    plugin 'Download::GitHub' => (
      github_user => 'Perl5-Alien',
      github_repo => 'dontpanic',
    );

  };

};

subtest 'live tests' => sub {

  my $build = alienfile q{

    use alienfile;

    probe sub { 'share' };

    share {
      plugin 'Download::GitHub' => (
        github_user => 'Perl5-Alien',
        github_repo => 'dontpanic',
        prefer      => 1,
      );
    };

  };

  alienfile_skip_if_missing_prereqs;

  alien_install_type_is 'share';

  my $default = $build->fetch;

  is
    $default,
    hash {
      field type => 'list';
      field list => bag {
        item hash sub {
          field filename => '1.02';
          field url => match qr/https:/;
          field version => '1.02';
        };
        item hash sub {
          field filename => '1.01';
          field url => match qr/https:/;
          field version => '1.01';
        };
        item hash sub {
          field filename => '1.00';
          field url => match qr/https:/;
          field version => '1.00';
        };
        item hash sub {
          field filename => '0.90';
          field url => match qr/https:/;
          field version => '0.90';
        };
        etc;
      };
    },
    'see that we have 0.90, 1.00, 1.01 and 1.02 at least',
  ;

  alien_download_ok;
  alien_extract_ok;

  my $extract = $build->install_prop->{extract};

  ok(-d $extract, "extracted to directory");
  note("install_prop.extract = $extract");
  ok(-f "$extract/configure", "has a configure file");
};

done_testing
