package Dist::Zilla::Plugin::CopyrightYearFromGit;

use 5.010001;
use strict;
use warnings;

use Moose;
with (
    'Dist::Zilla::Role::BeforeBuild',
);

# AUTHORITY
# DATE
# DIST
# VERSION

has min_year           => (is => 'rw');
has release_tag_regex  => (is => 'rw');
has author_name_regex  => (is => 'rw');
has author_email_regex => (is => 'rw');

sub mvp_aliases { return { regex => 'release_tag_regex' } }

sub before_build {
    require Release::Util::Git;
    my $self = shift;

    my @lgry_args;
    push @lgry_args, defined $self->release_tag_regex ?
        (release_tag_regex => $self->release_tag_regex) : ();
    push @lgry_args, defined $self->author_name_regex ?
        (author_name_regex => $self->author_name_regex) : ();
    push @lgry_args, defined $self->author_email_regex ?
        (author_email_regex => $self->author_email_regex) : ();

    my $res = Release::Util::Git::list_git_release_years(@lgry_args);
    $self->log_fatal(["%s - %s"], $res->[0], $res->[1]) unless $res->[0] == 200;

    my $cur_year = (localtime)[5]+1900;

    my $min_year = $self->min_year;
    $min_year = $cur_year if defined $min_year && $min_year > $cur_year;

    my @years = @{ $res->[2] };
    if (!@years || $years[0] < $cur_year) {
        unshift @years, $cur_year;
    }
    @years = grep { !defined($min_year) || $_ >= $min_year } @years;
    my $year = join(", ", sort {$b <=> $a} @years);
    $self->log(["Setting copyright_year to %s", $year]);

    # dirty, dirty hack
    $self->zilla->_copyright_year;
    $self->zilla->{_copyright_year} = $year;
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Set copyright year from git

=for Pod::Coverage .+

=head1 SYNOPSIS

In F<dist.ini>:

 [CopyrightYearFromGit]


=head1 DESCRIPTION

This plugin will set copyright year to something like:

 2017, 2015, 2014, 2013

where the years will be retrieved from 1) the date of git tags that resemble
version string (qr/^(version|ver|v)?\d/); 2) current date; and will be listed in
descending order in a comma-separated list. This format is commonly used in
books, where the year of each revision/edition is mentioned, e.g.:

 Copyright (c) 2013, 2010, 2008, 2006 by Pearson Education, Inc.


=head1 CONFIGURATION

=head2 min_year

Instruct the plugin to not include years below this year. If C<min_year> is
(incorrectly) set to a value larger than the current year, then the current year
will be used instead.

=head2 release_tag_regex

Specify a custom regular expression for matching git release tags.

An old alias C<regex> is still recognized, but deprecated.

=head2 author_name_regex

Only consider release commits where author name matches this regex.

=head2 author_email_regex

Only consider release commits where author email matches this regex.


=head1 SEE ALSO
