# vim:set sw=4 ts=4 sts=4 ft=perl expandtab:
package Lstu::Controller::Authent;
use Mojo::Base 'Mojolicious::Controller';

sub index {
    my $c = shift;
    if ($c->is_user_authenticated) {
        $c->redirect_to('index');
    } elsif (defined($c->config('trust_http_auth'))) {
        my $username = $c->req->headers->header($c->config('trust_http_auth')->{header});
        if ($username) {
             $c->authenticate($username, '');
             $c->redirect_to('index');
        }
    } else {
        $c->render(template => 'login');
    }
}

sub login {
    my $c     = shift;
    my $login = $c->param('login');
    my $pwd   = $c->param('password');

    if($c->authenticate($login, $pwd)) {
        $c->respond_to(
            json => sub {
                my $c = shift;
                $c->render(
                    json => {
                        success => Mojo::JSON->true,
                        msg     => $c->l('You have been successfully logged in.')
                    }
                );
            },
            any => sub {
                $c->redirect_to('index');
            }
        );
    } else {
        my $msg = $c->l('Please, check your credentials: unable to authenticate.');
        $c->respond_to(
            json => sub {
                my $c = shift;
                $c->render(
                    json => {
                        success => Mojo::JSON->false,
                        msg     => $msg
                    }
                );
            },
            any => sub {
                $c->stash(msg => $msg);
                $c->render(template => 'login')
            }
        );
    }
}

sub log_out {
    my $c = shift;
    if ($c->is_user_authenticated) {
        $c->logout;
        if ($c->config->{trust_http_auth}->{logout_url}) {
            $c->redirect_to($c->config->{trust_http_auth}->{logout_url});
        }
    }
    $c->respond_to(
        json => sub {
            my $c = shift;
            $c->render(
                json => {
                    success => Mojo::JSON->true,
                    msg     => $c->l('You have been successfully logged out.')
                }
            );
        },
        any => sub {
            $c->render(template => 'logout');
        }
    );
}

1;
