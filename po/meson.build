# Internationalization support
i18n = import('i18n')

# Configure gettext domain
i18n.gettext('kiro',
  preset: 'glib',
  data_dirs: [
    join_paths(meson.project_source_root(), 'data'),
    join_paths(meson.project_source_root(), 'src')
  ]
)