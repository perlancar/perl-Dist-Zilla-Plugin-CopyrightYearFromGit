package Dist::Zilla::Plugin::CopyrightYearFromGit;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use Moose;
with (
    'Dist::Zilla::Role::BeforeBuild',
);

has min_year => (is => 'rw');
has regex    => (is => 'rw');

sub before_build {
    require Release::Util::Git;
    my $self = shift;

    my @regex_args;
    if (defined $self->regex) {
        @regex_args = ( regex => $self->regex );
    }
    my $res = Release::Util::Git::list_git_release_years(@regex_args);
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

Instruct the plugin to not include years below this year. Note that the current
year will always be used, even though C<min_year> is (incorrectly) set to a
value larger than the current year.

=head2 regex

Specify a custom regular expression for matching version strings in git tags.

=head1 SEE ALSO
