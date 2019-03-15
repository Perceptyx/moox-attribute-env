use Test::More;

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
has codeattr => (
  is => 'ro',
  env => 1,
  default => sub { 2 },
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

package main;

sub test_with_env {
  my ($attr, $env, $expected) = @_;
  local %ENV = (%ENV, %$env);
  my $obj = MyMod->new;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  is $obj->$attr, $expected, "$attr from ENV";
}

test_with_env(attr => { ATTR_VAL => 3 }, 3);
test_with_env(attr => { attr_val => 3 }, 3);

test_with_env(otherattr => { OTHERATTR => 4 }, 4);
test_with_env(otherattr => { otherattr => 4 }, 4);
test_with_env(otherattr => {}, 7);

test_with_env(codeattr => { CODEATTR => 8 }, 8);
test_with_env(codeattr => { codeattr => 8 }, 8);
test_with_env(codeattr => {}, 2);

test_with_env(prefixattr => { XXX_PREFIXATTR => 5 }, 5);
test_with_env(prefixattr => { xxx_prefixattr => 5 }, 5);

test_with_env(packageattr => { MYMOD_PACKAGEATTR => 6 }, 6);
test_with_env(packageattr => { MyMod_packageattr => 6 }, 6);

done_testing;
