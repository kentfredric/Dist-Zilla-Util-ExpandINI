use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package Dist::Zilla::Util::ExpandINI::Reader;

our $VERSION = '0.001004';

# ABSTRACT: An order-preserving INI reader

# AUTHORITY

use Carp qw(croak);

use parent 'Config::INI::Reader';

sub new {
  my ($class) = @_;

  my $self = {
    data     => [],
    sections => {},
  };

  bless $self => $class;
  $self->{current_section} = { name => $self->starting_section, lines => [] };
  return $self;
}

sub change_section {
  my ( $self, $section ) = @_;

  my ( $package, $name ) = $section =~ m{
    \A \s*                    # Ignore leading whitespace
    (?:                       # Optional Non Capture Group
      ([^/\s]+)               # Capture a bunch chars at the front
      \s*                     # then skip over subsequent whitespace
      /                       # and slash divider
      \s*
    )?
    (.+)                      # Capture the rest as a complete token
    \z
  }msx;
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
  return;
}

sub set_value {
  my ( $self, $name, $value ) = @_;
  push @{ $self->{current_section}->{lines} }, $name, $value;
  return;
}

sub finalize {
  my ($self) = @_;
  push @{ $self->{data} }, $self->{current_section};
  return;
}

1;
