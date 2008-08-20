package Prophet::CLI::Command::Log;
use Moose;
extends 'Prophet::CLI::Command';

sub run {
    my $self = shift;
    my $handle = $self->handle;
    my $newest = $self->arg('last') || $handle->latest_sequence_no;
    my $start = $newest - ($self->arg('count') || '20');
    $start = 0 if $start < 0;

    $handle->traverse_changesets(
        after    => $start,
        callback => sub {
            my $changeset = shift;
          print $changeset->as_string(change_header => sub {
                    my $change = shift;
                    return " # " . $change->record_type. " ".$self->app_handle->handle->find_or_create_luid(uuid => $change->record_uuid)." (" . $change->record_uuid.")\n";
                       
              });
        },
    );


}

1;