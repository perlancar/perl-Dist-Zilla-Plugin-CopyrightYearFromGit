package Dist::Zilla::Plugin::CopyrightYearFromGit;

use 5.010001;
use strict;
use warnings;

use List::Util ();

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
has exclude_year       => (is => 'rw');
has include_year       => (is => 'rw');
has continuous_year    => (is => 'rw');

sub mvp_aliases { return { regex => 'release_tag_regex' } }

sub mvp_multivalue_args { qw(exclude_year include_year) }

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

    # filter by min_year
    @years = grep { !defined($min_year) || $_ >= $min_year } @years;

    # add include_year
    push @years, @{ $self->include_year } if $self->include_year;

    # filter by exclude_year
    if ($self->exclude_year) {
        my @fyears;
        for my $year (@years) {
            next if grep { $year eq $_ } @{ $self->exclude_year };
            push @years, $year;
        }
        @years = @fyears;
    }

    # make the years continuous
    if ($self->continuous_year) {
        my $min = List::Util::min(@years);
        my $max = List::Util::max(@years);
        @years = $min .. $max;
    }

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

Suppose the current year is 2021 and you have release git tags for 2019, 2017,
2016. The default setting will make copyright_year to be:

 2021, 2019, 2017, 2016

In F<dist.ini>:

 [CopyrightYearFromGit]
 ; release_tag_regex = ^v    ; optional, default is ^(version|ver|v)\d
 ; author_name_regex = foo   ; optional, default is none (any author name will be included)
 ; author_email_regex = foo  ; optional, default is none (any author name will be included)

 ; min_year = 2017           ; optional, setting this would make copyright_year become: 2021, 2019, 2017.

 ; include_year = 2015
 ; include_year = 2013       ; optional, setting this two lines would make copyright_year become: 2021, 2019, 2017, 2016, 2015, 2013.

 ; exclude_year = 2016
 ; exclude_year = 2017       ; optional, setting this two lines would make copyright_year become: 2021, 2019

 ; continuous_year = 1       ; optional, setting this two lines would make copyright_year become: 2021, 2020, 2019, 2018, 2017, 2016


=head1 DESCRIPTION

This plugin will set copyright_year to something like:

 2021, 2019, 2017, 2016

where the years will be retrieved from: 1) the date of git tags that resemble
version string (qr/^(version|ver|v)?\d/); 2) the current year. Years that do not
see version tags and are not the current year will not be included, unless you
set L</continuous_year> or L</include_year>. On the other hand, years that see
version tags or the current year can be excluded via L</min_year> or
L</exclude_year>.

The included years will be listed in descending order in a comma-separated list.
This format is commonly used in books, where the year of each revision/edition
is mentioned, e.g.:

 Copyright (c) 2013, 2010, 2008, 2006 by Pearson Education, Inc.


=head1 CONFIGURATION

=head2 release_tag_regex

String (regex pattern). Specify a custom regular expression for matching git
release tags.

An old alias C<regex> is still recognized, but deprecated.

=head2 author_name_regex

String (regex pattern). Only consider release commits where author name matches
this regex.

=head2 author_email_regex

String (regex pattern). Only consider release commits where author email matches
this regex.

=head2 min_year

Integer. Instruct the plugin to not include years below this year. If
C<min_year> is (incorrectly) set to a value larger than the current year, then
the current year will be used instead. Note that L</include_year> and
L</exclude_year> override C<min_year>.

=head2 include_year

Integer (can be specified multiple times). Force-include one or more years. Note
that L</exclude_year> overrides C<include_year>.

=head2 exclude_year

Integer (can be specified multiple times). Force-exclude one or more years. Note
that L</continuous_year> overrides C<exclude_year>.

=head2 continuous_year

Boolean. If set to true, will make copyright_year a continuous range from the
smallest included year to the largest included year, with no gap inside.


=head1 SEE ALSO
