package Oak::IO::DBI;

use base qw(Oak::Component);
use Error qw(:try);
use DBI;

use strict;

=head1 NAME

Oak::IO::DBI - IO routines to exchange data with databases using DBI

=head1 DESCRIPTION

This module provides access for exchange data with databases using DBI.

=head1 HIERARCHY

L<Oak::Object|Oak::Object>

L<Oak::Persistent|Oak::Persistent>

L<Oak::Component|Oak::Component>

L<Oak::IO::DBI|Oak::IO::DBI>

=head1 PROPERTIES

=over 4

=item datasource

DBI datasorce string, used to create the connection. See
perldoc DBI for more information.

=item username,password,options

DBI options. See DBI documentation for more help.

=back

=head1 EVENTS

=over

=item ev_onConnect

When a connection is openned

=item ev_onSql

When a sql is executed

=item ev_onDisconnect

When the database is explicitly disconnected (not on DESTROY)

=back

=cut

sub constructor {
	my $self = shift;
	my %params = @_;
	$self->SUPER::constructor(%params);
	unless (ref $params{RESTORE} eq "HASH") {
		unless ($self->_test_required_params(%params)) {
			throw Oak::Error::ParamsMissing;
		}
		$self->set	# Avoid inexistent properties
		  (
		   datasource => $params{datasource},
		   username => $params{username},
		   password => $params{password},
		   options => $params{options},
		  );
	}
	$self->connect;
}

# internal function
sub _test_required_params {
	my $self = shift;
	my %params = @_;
	return undef unless (
			     $params{datasource}
			    );
	return 1;
}

=head1 METHODS

=over

=item connect

Register the connection for this object. Generates an ev_onConnect event.

Could raise the Oak::IO::DBI::Error::ConnectionFailure exception.

=back

=cut

sub connect {
	my $self = shift;

	$self->{dbh} ||= DBI->connect (
				      $self->get('datasource'),
				      $self->get('username'),
				      $self->get('password'),
				      $self->get('options')
				     );
	unless ($self->{dbh}) {
		throw Oak::IO::DBI::Error::ConnectionFailure; # Must raise the exception
	}
	$self->dispatch('ev_onConnect');
	return 1;
}

=over

=item do_sql(SQL)

Prepare, executes and test if successfull. Returns the Sth.
Generates an ev_onSql event (passes $sql and $sth to the function called).

Could rause the following exceptions:
Oak::Filer::DBI::Error::SQLSyntaxError and Oak::Filer::DBI::Error::SQLExecuteError

=back

=cut

sub do_sql {
	my $self = shift;
	my $sql = shift;
	$self->connect;
	my $sth = $self->{dbh}->prepare($sql);
	throw Oak::IO::DBI::Error::SQLSyntaxError -text => $sql unless defined $sth;
	my $rv = $sth->execute;
	throw Oak::IO::DBI::Error::SQLExecuteError -text => $sql unless (defined $sth) and ($rv);
	$self->dispatch('ev_onSql');
	return $sth;
}

=over

=item quote

Quotes a string, using DBI->quote unless empty, else uses "''".

=back

=cut

sub quote {
	my $self = shift;
	my $str = shift || "";
	$self->connect;
	unless (($str eq '') || (!defined $str)) {
		$str = $self->{dbh}->quote($str);
	} else {
		$str = "''";
	}
	return $str;
}

=over

=item get_dbh

Returns the DBI object.

=back

=cut

sub get_dbh {
	my $self = shift;
	$self->connect;
	return $self->{dbh};
}


=over

=item disconnect

Called by DESTROY, releases the DBI connection. It disconnects.
Generates a ev_onDisconnect event.

=back

=cut

sub disconnect {
	my $self = shift;
	$self->{dbh}->disconnect if $self->{dbh};
	$self->{dbh} = undef;
	$self->dispatch('ev_onDisconnect');
	return 1;
}


=over

=item begin_work, commit, rollback

Calls the method with the same name at DBI.

=back

=cut

sub begin_work {
	my $self = shift;
	$self->{dbh}->begin_work if $self->{dbh};
	return 1;
}

sub commit {
	my $self = shift;
	$self->{dbh}->commit if $self->{dbh};
	return 1;
}

sub rollback {
	my $self = shift;
	$self->{dbh}->rollback if $self->{dbh};
	return 1;
}

1;

=head1 EXCEPTION HANDLING

=over

=item Oak::IO::DBI::Error::ConnectionFailure;

This class is used in the register_connection when it fails

=back

=cut

package Oak::IO::DBI::Error::ConnectionFailure;

use base qw (Error);

sub stringify {
	return "Connection Failure";
}

package Oak::IO::DBI::Error::SQLSyntaxError;

=over

=item Oak::IO::DBI::Error::SQLSyntaxError;

This class is raised when the sql has wrong syntax

=back

=cut

use base qw (Error);

sub stringify {
	return "Syntax Error";
}

package Oak::IO::DBI::Error::SQLExecuteError;

=over

=item Oak::IO::DBI::Error::SQLExecuteError;

This class is raised when the sql has an error while executing

=back

=cut

use base qw (Error);

sub stringify {
	return "Execute Error";
}

__END__

=head1 COPYRIGHT

Copyright (c) 2001 Daniel Ruoso <daniel@ruoso.com> and Rodolfo Sikora <rodolfo@trevas.net>. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
