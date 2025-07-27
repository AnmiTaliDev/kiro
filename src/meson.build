# Source files
kiro_sources = [
  'main.vala',
  'engine.vala',
  'ui.vala',
  'settings.vala'
]

# Dependencies
kiro_deps = [
  dependency('gtk4'),
  dependency('libadwaita-1', version: '>= 1.0'),
  dependency('vte-2.91-gtk4'),
  dependency('glib-2.0', version: '>= 2.66'),
  dependency('gio-2.0', version: '>= 2.66'),
  dependency('gobject-2.0', version: '>= 2.66')
]

# Vala compiler arguments
kiro_vala_args = [
  '--target-glib=2.66',
  '--pkg=gtk4',
  '--pkg=libadwaita-1',
  '--pkg=vte-2.91-gtk4',
  '--pkg=gio-2.0',
  '--pkg=posix'
]

# C compiler arguments
kiro_c_args = [
  '-DGETTEXT_PACKAGE="kiro"',
  '-DLOCALEDIR="' + join_paths(get_option('prefix'), get_option('localedir')) + '"',
  '-DVERSION="' + meson.project_version() + '"'
]

# Build executable
kiro_exe = executable(
  'kiro',
  kiro_sources,
  dependencies: kiro_deps,
  vala_args: kiro_vala_args,
  c_args: kiro_c_args,
  install: true,
  install_dir: get_option('bindir')
)