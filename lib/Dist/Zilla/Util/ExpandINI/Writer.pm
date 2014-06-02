use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package Dist::Zilla::Util::ExpandINI::Writer;

our $VERSION = '0.001000';

# ABSTRACT: An order-preserving INI Writer

# AUTHORITY

use parent 'Config::INI::Writer';
use Carp qw(croak);

sub is_valid_section_name {
  my ( undef, $name ) = @_;
  return $name !~ m{
    (?:    # Dont capture
      \n   # Newlines may not occur in a section name
      |
      \s;  # Comments may not occur in a section name
      |
      ^\s  # Leading whitespace is illegal in a section name
      |
      \s$  # Trailing whitespace is illegal in a section name
    )
  }msx;
}

sub preprocess_input {
  my ( undef, $input_data ) = @_;
  my @out;
  my $i = 0;
  for my $ini_record ( @{$input_data} ) {
    $i++;
    if ( $ini_record->{name} and '_' eq $ini_record->{name} ) {
      push @out, '_', $ini_record->{lines};
      next;
    }
    if ( not $ini_record->{package} ) {
      croak("Entry $i lacks package component");
    }
    my $kn = $ini_record->{package};
    if ( $ini_record->{name} and $ini_record->{package} ne $ini_record->{name} ) {
      $kn .= q[ / ] . $ini_record->{name};
    }
    push @out, $kn, $ini_record->{lines};
    next;
  }
  return \@out;
}

sub validate_input {
  my ( $self, $input ) = @_;

  my %seen;

  my @input_copy = @{$input};

  while (@input_copy) {
    my ( $name, $props ) = splice @input_copy, 0, 2;

    if ( $seen{$name}++ ) {
      Carp::croak "multiple declarations found of $name";
    }

    Carp::croak "illegal section name '$name'"
      if not $self->is_valid_section_name($name);

    my @props_copy = @{$props};

    while (@props_copy) {
      my ( $property, $value ) = splice @props_copy, 0, 2;

      Carp::croak "property name '$property' contains illegal character"
        if not $self->is_valid_property_name($property);

      Carp::croak "value for $name.$property contains illegal character"
        if defined $value and not $self->is_valid_value($value);

    }
  }
  return;
}
1;

