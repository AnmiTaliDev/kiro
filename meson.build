# Kiro Terminal Emulator
project('kiro', ['vala', 'c'],
  version: '1.0.0',
  license: 'GPL-3.0+',
  meson_version: '>= 0.59.0',
  default_options: [
    'warning_level=2',
    'werror=false',
    'c_std=gnu11',
  ]
)

# Project information
app_id = 'kz.anmitali.kiro'
app_name = 'Kiro'
app_version = meson.project_version()

# Import modules
gnome = import('gnome')
i18n = import('i18n')

# Dependencies version requirements
gtk_version = '>= 4.8.0'
adwaita_version = '>= 1.2.0'
vte_version = '>= 0.70.0'
glib_version = '>= 2.66.0'

# Check dependencies
gtk_dep = dependency('gtk4', version: gtk_version)
adwaita_dep = dependency('libadwaita-1', version: adwaita_version)
vte_dep = dependency('vte-2.91-gtk4', version: vte_version)
glib_dep = dependency('glib-2.0', version: glib_version)
gio_dep = dependency('gio-2.0', version: glib_version)
gobject_dep = dependency('gobject-2.0', version: glib_version)

# Find Vala compiler
vala = meson.get_compiler('vala')
vala_version = vala.version()
message('Found Vala compiler version: @0@'.format(vala_version))

if vala_version.version_compare('< 0.56.0')
  error('Vala compiler 0.56.0 or newer is required')
endif

# Configuration data
conf_data = configuration_data()
conf_data.set_quoted('APP_ID', app_id)
conf_data.set_quoted('APP_NAME', app_name)
conf_data.set_quoted('VERSION', app_version)
conf_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf_data.set_quoted('LOCALEDIR', 
  join_paths(get_option('prefix'), get_option('localedir'))
)

# Subdirectories
subdir('data')
subdir('src')
subdir('po')

# Post-install scripts
gnome.post_install(
  glib_compile_schemas: true,
  gtk_update_icon_cache: true,
  update_desktop_database: true,
)

# Summary
summary({
  'Application ID': app_id,
  'Version': app_version,
  'Prefix': get_option('prefix'),
  'Bindir': get_option('bindir'),
  'Datadir': get_option('datadir'),
  'Localedir': get_option('localedir'),
}, section: 'Configuration')

summary({
  'GTK4': gtk_dep.version(),
  'LibAdwaita': adwaita_dep.version(),
  'VTE': vte_dep.version(),
  'GLib': glib_dep.version(),
  'Vala': vala_version,
}, section: 'Dependencies')