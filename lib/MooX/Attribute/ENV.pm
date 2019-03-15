package MooX::Attribute::ENV;

our $VERSION = '0.01';

# this bit would be MooX::Utils but without initial _ on func name
use strict;
use warnings;
use Moo ();
use Moo::Role ();
use Carp qw(croak);
#use base qw(Exporter);
#our @EXPORT = qw(override_function);
sub _override_function {
  my ($target, $name, $func) = @_;
  my $orig = $target->can($name) or croak "Override '$target\::$name': not found";
  my $install_tracked = Moo::Role->is_role($target) ? \&Moo::Role::_install_tracked : \&Moo::_install_tracked;
  $install_tracked->($target, $name, sub { $func->($orig, @_) });
}
# end MooX::Utils;

sub import {
  my $target = scalar caller;
  _override_function($target, 'has', sub {
    my ($orig, $namespec, %opts) = @_;
    my $old_default = $opts{default};
    for my $name (ref $namespec ? @$namespec : $namespec) {
      my $envkey = _generate_key($name, \%opts, $target);
      $orig->($namespec, %opts), return if !defined $envkey; # non env
      $orig->($name, %opts, default => sub {
        return $ENV{$envkey} if defined $ENV{$envkey};
        return $ENV{uc $envkey} if defined $ENV{uc $envkey};
        return $old_default->() if ref $old_default eq 'CODE';
        $old_default;
      });
    }
  });
}

sub _generate_key {
  my ($attr, $opts, $target) = @_;
  return $attr if $opts->{env};
  return $opts->{env_key} if $opts->{env_key};
  return "$opts->{env_prefix}_$attr" if $opts->{env_prefix};
  if ($opts->{env_package_prefix}) {
    $target =~ s/:+/_/g;
    return "${target}_$attr";
  }
  undef;
}

=head1 NAME

MooX::Attribute::ENV - Allow Moo attributes to get their values from %ENV

=head1 SYNOPSIS

  package MyMod;
  use Moo;
  use MooX::Attribute::ENV;
  # look for $ENV{attr_val} and $ENV{ATTR_VAL}
  has attr => (
    is => 'ro',
    env_key => 'attr_val',
  );
  # looks for $ENV{otherattr} and $ENV{OTHERATTR}, then any default
  has otherattr => (
    is => 'ro',
    env => 1,
    default => 7,
  );
  # looks for $ENV{xxx_prefixattr} and $ENV{XXX_PREFIXATTR}
  has prefixattr => (
    is => 'ro',
    env_prefix => 'xxx',
  );
  # looks for $ENV{MyMod_packageattr} and $ENV{MYMOD_PACKAGEATTR}
  has packageattr => (
    is => 'ro',
    env_package_prefix => 1,
  );

  $ perl -MMyMod -E 'say MyMod->new(attr => 2)->attr'
  # 2
  $ ATTR_VAL=3 perl -MMyMod -E 'say MyMod->new->attr'
  # 3
  $ OTHERATTR=4 perl -MMyMod -E 'say MyMod->new->otherattr'
  # 4

=head1 DESCRIPTION

This is a L<Moo> extension. It allows other attributes for L<Moo/has>. If
any of these are given, then instead of the normal value-setting "chain"
for attributes of given, default; the chain will be given, environment,
default.

The environment will be searched for either the given case, or upper case,
version of the names discussed below.

When a prefix is mentioned, it will be prepended to the mentioned name,
with a C<_> in between.

=head1 ADDITIONAL ATTRIBUTES

=head2 env

Boolean. If true, the name is the attribute, no prefix.

=head2 env_key

String. If true, the name is the given value, no prefix.

=head2 env_prefix

String. The prefix is the given value.

=head2 env_package_prefix

Boolean. If true, use as the prefix the current package-name, with C<::>
replaced with C<_>.

=head1 AUTHOR

Ed J, porting John Napiorkowski's excellent L<MooseX::Attribute::ENV>.

=head1 LICENCE

The same terms as Perl itself.

=cut

1;