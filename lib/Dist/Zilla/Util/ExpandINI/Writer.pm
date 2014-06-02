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
  my ( $self, $name ) = @_;
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
  }x;
}

sub preprocess_input {
  my ( $self, $data ) = @_;
  my @out;
  my $i = 0;
  for my $record ( @{$data} ) {
    $i++;
    if ( $record->{name} and $record->{name} eq '_' ) {
      push @out, '_', $record->{lines};
      next;
    }
    if ( not $record->{package} ) {
      croak("Entry $i lacks package component");
    }
    my $kn = $record->{package};
    if ( $record->{name} and $record->{package} ne $record->{name} ) {
      $kn .= q[ / ] . $record->{name};
    }
    push @out, $kn, $record->{lines};
    next;
  }
  return \@out;
}

sub validate_input {
  my ( $self, $input ) = @_;

  my %seen;

  for ( my $i = 0 ; $i < $#$input ; $i += 2 ) {
    my ( $name, $props ) = @$input[ $i, $i + 1 ];

    if ( $seen{$name}++ ) {
      Carp::croak "multiple declarations found of $name";
    }

    Carp::croak "illegal section name '$name'"
      if not $self->is_valid_section_name($name);

    for ( my $j = 0 ; $j < $#$props ; $j += 2 ) {
      my $property = $props->[$j];
      my $value    = $props->[ $j + 1 ];

      Carp::croak "property name '$property' contains illegal character"
        if not $self->is_valid_property_name($property);

      Carp::croak "value for $name.$property contains illegal character"
        if defined $value and not $self->is_valid_value($value);

    }
  }
  return;
}
1;

