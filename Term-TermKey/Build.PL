use strict;
use warnings;

use Module::Build;

eval { require ExtUtils::PkgConfig; } or
   die "OS unsupported - no ExtUtils::PkgConfig\n";

eval { ExtUtils::PkgConfig->find("termkey"); } or
   die "OS unsupported - pkg-config cannot find termkey\n";

my $version = ExtUtils::PkgConfig->modversion("termkey");
$version >= 0.5 or die "OS unsupported - termkey too old ($version)\n";

my $cflags = ExtUtils::PkgConfig->cflags("termkey");
my $libs   = ExtUtils::PkgConfig->libs("termkey");

my $build = Module::Build->new
  (
   module_name => 'Term::TermKey',
   extra_compiler_flags => [ split( m/ /, $cflags ) ],
   extra_linker_flags   => [ split( m/ /, $libs ) ],
   configure_requires => {
      'ExtUtils::PkgConfig' => 0,
   },
   requires => {
   },
   recommends => {
   },
   build_requires => {
      'ExtUtils::PkgConfig' => 0,
      'Module::Build' => 0,
      'Module::Build::Compat' => 0,
      'Test::More' => 0,
      'Test::Refcount' => 0,
   },
   license => 'perl',
   create_makefile_pl => 'small',
   create_license => 1,
   create_readme  => 1,
  );

$build->create_build_script;
