package App::rmhere;

use 5.010001;
use strict;
use warnings;
#use experimental 'smartmatch';
use Log::Any '$log';

use File::chdir;

# for testing
use Time::HiRes qw(sleep);

#require Exporter;
#our @ISA       = qw(Exporter);
#our @EXPORT_OK = qw(rmhere);

# VERSION

our %SPEC;

$SPEC{rmhere} = {
    v             => 1.1,
    summary       => 'Delete files in current directory',
    args          => {
        here => {
            summary => 'Override current directory',
            schema  => 'str*',
        },
        preestimate => { # XXX name
            summary => 'Count files first before start deleting',
            schema  => 'bool*',
        },
        # TODO: force option
        # TODO: match option
        # TODO: dir option
        # TODO: recursive option
    },
    features => {
        progress => 1,
        dry_run  => 1,
    },
};
sub rmhere {
    my %args = @_;

    my $progress = $args{-progress};
    my $dry_run  = $args{-dry_run};

    local $CWD = $args{here} if defined $args{here};

    opendir my($dh), "." or return [500, "Can't opendir: $!"];
    my $get_next_file = sub {
        while (defined(my $e = readdir($dh))) {
            next if $e eq '.' || $e eq '..';
            next if (-d $e);
            return $e;
        }
        return undef;
    };
    my $files;

    $progress->pos(0) if $progress;
    if ($args{preestimate}) {
        $files = [];
        while (defined(my $e = $get_next_file->())) {
            push @$files, $e;
        }
        $progress->target(~~@$files) if $progress;
    } else {
        $progress->target(undef) if $progress;
    }

    my $i = 0;
    while (defined(my $e = $files ? shift(@$files) : $get_next_file->())) {
        $log->info("Deleting $e ...");
        $i++;
        unlink($e) unless $dry_run;

        # for testing
        sleep(0.0001);

        $progress->update(message => "Deleted $i files") if $progress;
    }
    $progress->finish if $progress;
    [200, "OK"];
}

1;
# ABSTRACT: Delete files in current directory

=head1 SYNOPSIS

See L<rmhere> script.


=head1 DESCRIPTION


=cut