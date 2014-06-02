use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package Dist::Zilla::Util::ExpandINI::Reader;

our $VERSION = '0.001000';

# ABSTRACT: An order-preserving INI reader

# AUTHORITY

use Carp qw(croak);

use parent 'Config::INI::Reader';

sub new {
  my ($class) = @_;

  my $self = { data => [], };

  bless $self => $class;
}

sub _xinit {
  my ($self) = @_;
  if ( not $self->{current_section} ) {
    $self->{current_section} = { name => $self->starting_section, lines => [] };
  }
  if ( not $self->{data} ) {
    $self->{data} = [];
  }
  if ( not $self->{sections} ) {
    $self->{sections} = {};
  }
}

sub change_section {
  my ( $self, $section ) = @_;

  $self->_xinit;

  my ( $package, $name ) = $section =~ m{\A\s*(?:([^/\s]+)\s*/\s*)?(.+)\z};
  $package = $name unless defined $package and length $package;

  Carp::croak qq{couldn't understand section header: "$section"}
    unless $package;

  push @{ $self->{data} }, $self->{current_section};

  if ( exists $self->{sections}->{$name} ) {
    Carp::croak qq{Duplicate section $name ( $package )};
  }
  $self->{sections}->{$name} = 1;
  $self->{current_section} = {
    name    => $name,
    package => $package,
    lines   => [],
  };
}

sub set_value {
  my ( $self, $name, $value ) = @_;
  $self->_xinit;
  push @{ $self->{current_section}->{lines} }, $name, $value;
}

sub finalize {
  my ($self) = @_;
  push @{ $self->{data} }, $self->{current_section};
}

1;

