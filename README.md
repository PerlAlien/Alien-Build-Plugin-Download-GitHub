# Alien::Build::Plugin::Download::GitHub ![linux](https://github.com/PerlAlien/Alien-Build-Plugin-Download-GitHub/workflows/linux/badge.svg) ![macos](https://github.com/PerlAlien/Alien-Build-Plugin-Download-GitHub/workflows/macos/badge.svg) ![windows](https://github.com/PerlAlien/Alien-Build-Plugin-Download-GitHub/workflows/windows/badge.svg)

Alien::Build plugin to download from GitHub

# SYNOPSIS

```perl
use alienfile;

...

share {

  plugin 'Download::GitHub' => (
    github_user => 'PerlAlien',
    github_repo => 'dontpanic',
  );

};
```

# DESCRIPTION

This plugin will download releases from GitHub.  It is generally preferred over
[Alien::Build::Plugin::Download::Git](https://metacpan.org/pod/Alien::Build::Plugin::Download::Git) for packages that are released on GitHub,
as it has much fewer dependencies and is more reliable.

# PROPERTIES

## github\_user

The GitHub user or org that owns the repository.  This property is required.

## github\_repo

The GitHub repository name.  This property is required.

## include\_assets

\[deprecated: use the asset\* properties instead\]

Defaulting to false, this option designates whether to include the assets of
releases in the list of candidates for download. This should be one of three
types of values:

- true value

    The full list of assets will be included in the list of candidates.

- false value

    No assets will be included in the list of candidates.

- regular expression

    If a regular expression is provided, this will include assets that match by
    name.

## tags\_only

Boolean value for those repositories that do not upgrade their tags to releases.
There are two different endpoints. One for
[releases](https://developer.github.com/v3/repos/releases/#list-releases-for-a-repository)
and one for simple [tags](https://developer.github.com/v3/repos/#list-tags). The
default is to interrogate the former for downloads. Passing a true value for
["tags\_only"](#tags_only) interrogates the latter for downloads.

## version

Regular expression that can be used to extract a version from a GitHub tag.  The
default ( `qr/^v?(.*)$/` ) is reasonable for many GitHub repositories.

## prefer

How to sort candidates for selection.  This should be one of three types of values:

- code reference

    This will be used as the prefer hook.

- true value (not code reference)

    Use [Alien::Build::Plugin::Prefer::SortVersions](https://metacpan.org/pod/Alien::Build::Plugin::Prefer::SortVersions).

- false value

    Don't set any preference at all.  The order returned from GitHub will be used if
    no other prefer plugins are specified.  This may be reasonable for at least some
    GitHub repositories.  This is the default.

## asset

Download from assets instead of via tag.  This option is incompatible with
`tags_only`.

## asset\_name

Regular expression which the asset name should match.  The default is `qr/\.tar\.gz$/`.

## asset\_format

The format of the asset.  This is passed to [Alien::Build::Plugin::Extract::Negotiate](https://metacpan.org/pod/Alien::Build::Plugin::Extract::Negotiate)
so any format supported by that is valid.

## asset\_convert\_version

This is an optional code reference which can be used to modify the version.  For example,
if the release version is prefixed with a `v` You could do this:

```perl
plugin 'Download::GitHub' => (
  github_user => 'PerlAlien',
  github_repo => 'dontpanic',
  asset => 1,
  asset_convert_version => sub {
    my $version = shift;
    $version =~ s/^v//;
    $version;
  },
);
```

# ENVIRONMENT

- ALIEN\_BUILD\_GITHUB\_TOKEN GITHUB\_TOKEN GITHUB\_PAT

    If one of these environment variables are set, then the GitHub API Personal
    Access Token (PAT) will be used when connecting to the GitHub API.

    For security reasons, the PAT will be removed from the log.  Some Fetch plugins
    (for example the `curl` plugin) will log HTTP requests headers so this will
    make sure that your PAT is not displayed in the log.

- ALIEN\_BUILD\_PLUGIN\_DOWNLOAD\_GITHUB\_DEBUG

    Setting this to a true value will send additional diagnostics to the log during
    the indexing phase of the fetch.

# CAVEATS

This plugin does not support, and will not work if `ALIEN_DOWNLOAD_RULE` is set to
either `digest_and_encrypt` or `digest`.

The GitHub API is rate limited.  Once you've reach that limit, this plugin will be 
inoperative for a period of time until the limits reset.  When using the GitHub
API unauthenticated the limit is especially low.  This is usually not a problem when
used in production where you only need to use the API once for each [Alien](https://metacpan.org/pod/Alien), but
it can become a problem when testing an [Alien](https://metacpan.org/pod/Alien) that uses this plugin in CI or via
cpantesters.  In this situation you can set the `ALIEN_BUILD_GITHUB_TOKEN` environment
variable (or commonly used but unofficial `GITHUB_TOKEN` or `GITHUB_PAT`), and this
plugin will use that in making API requests.  If you are using GitHub Actions for CI,
then you can use the `secrets.GITHUB_TOKEN` macro to get a PAT.

If you do this it is recommended that you make some precautions where possible:

- Limit permissions

    Create a PAT with the bare minimum access permissions.  Consider creating a
    separate GitHub account without access to anything, and use it to generate the PAT.

- Limit scope of usage

    The PAT is only needed (if it is needed at all) during the build stage
    of a share install.  If you are doing this in GitHub Actions you can
    just set the environment variable for that stage:

    ```
    perl Makefile.PL
    env ALIEN_BUILD_GITHUB_TOKEN=${{ secrets.GITHUB_TOKEN }} make
    make test
    ```

    Or if you are using [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla)

    ```
    dzil listdeps --missing | cpanm -n
    env ALIEN_BUILD_GITHUB_TOKEN=${{ secrets.GITHUB_TOKEN }} dzil test
    ```

# AUTHOR

Author: Graham Ollis <plicease@cpan.org>

Contributors:

Roy Storey (KIWIROY)

# COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
