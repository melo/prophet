package Prophet::Server::Dispatcher;
use Moose;
use Path::Dispatcher::Declarative -base;

has server => ( isa => 'Prophet::Server', is => 'rw', weak_ref => 1 );

sub token_delimiter       {'/'}
sub case_sensitive_tokens {0}

under 'POST' => sub {
    on qr'.*' => sub {
        my $self = shift;
        return $self->server->_send_401 if ( $self->server->read_only );
        next_rule;
    };

    under 'records' => sub {
        on qr|(.*)/(.*)/(.*)| => sub { shift->server->update_record_prop() };
        on qr|(.*)/(.*).json| => sub { shift->server->update_record() };
        on qr|^(.*).json|     => sub { shift->server->create_record() };
    };
};

under 'GET' => sub {
    on qr'replica/+(.*)$' => sub { shift->server->serve_replica() };
    on 'records.json' => sub { shift->server->get_record_types };
    under 'records' => sub {
        on qr|(.*)/(.*)/(.*)| => sub { shift->server->get_record_prop() };
        on qr|(.*)/(.*).json| => sub { shift->server->get_record() };
        on qr|(.*).json|      => sub { shift->server->get_record_list() };
    };

    on '^(.*)$' => sub { shift->server->show_template() || next_rule; };
};


no Moose;

1;
