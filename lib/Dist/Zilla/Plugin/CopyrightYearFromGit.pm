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

sub before_build {
    require Release::Util::Git;
    my $self = shift;

    my $res = Release::Util::Git::list_git_release_tags(detail => 1);
    $self->log_fatal(["%s - %s"], $res->[0], $res->[1]) unless $res->[0] == 200;

    my %years;

    # current date's year
    $years{ (localtime)[5]+1900 }++;

    for my $e (@{ $res->[2] }) {
        # year from each release tag
        $years{ (localtime $e->{date})[5]+1900 }++; # XXX take tz_offset into account
    }

    my $year = join(", ", sort {$b <=> $a} keys %years);
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
version string (qr/^(version|ver|v)?\d/); 2) current date; and will be listed in descending
order in a comma-separated list. This format is commonly used in books, where
the year of each revision/edition is mentioned, e.g.:

 Copyright (c) 2013, 2010, 2008, 2006 by Pearson Education, Inc.


=head1 SEE ALSO
