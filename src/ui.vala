using Gtk;
using Adw;

namespace Kiro {
    public class MainWindow : Adw.ApplicationWindow {
        private Adw.TabView tab_view;
        private Adw.TabBar tab_bar;
        private Settings settings;
        private Gtk.Box main_box;
        private Adw.HeaderBar header_bar;
        private PreferencesDialog? preferences_dialog = null;

        private GLib.List<TerminalTab> terminal_tabs;

        public MainWindow(Gtk.Application app, Settings settings) {
            Object(
                application: app,
                title: "Kiro",
                default_width: 800,
                default_height: 600,
                icon_name: "utilities-terminal"
            );

            this.settings = settings;
            this.terminal_tabs = new GLib.List<TerminalTab>();

            build_ui();
            setup_actions();
            load_window_state();

            // Create first tab
            new_tab();
        }

        private void build_ui() {
            // Main container
            main_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

            // Header bar
            header_bar = new Adw.HeaderBar();
            header_bar.show_end_title_buttons = true;
            header_bar.show_start_title_buttons = true;

            // Menu button
            var menu_button = new Gtk.MenuButton() {
                icon_name = "open-menu-symbolic",
                tooltip_text = _("Main Menu")
            };

            var menu = new GLib.Menu();
            var window_section = new GLib.Menu();
            window_section.append(_("New Tab"), "app.new-tab");
            window_section.append(_("Preferences"), "app.preferences");
            menu.append_section(null, window_section);

            var app_section = new GLib.Menu();
            app_section.append(_("About Kiro"), "app.about");
            app_section.append(_("Quit"), "app.quit");
            menu.append_section(null, app_section);

            menu_button.menu_model = menu;
            header_bar.pack_end(menu_button);

            // New tab button
            var new_tab_button = new Gtk.Button() {
                icon_name = "tab-new-symbolic",
                tooltip_text = _("New Tab")
            };
            new_tab_button.action_name = "app.new-tab";
            header_bar.pack_start(new_tab_button);

            // Tab view
            tab_view = new Adw.TabView();
            tab_view.vexpand = true;

            // Tab bar
            tab_bar = new Adw.TabBar() {
                view = tab_view,
                autohide = false,
                expand_tabs = true
            };

            // Connect tab signals
            tab_view.close_page.connect(on_close_page);
            tab_view.page_attached.connect(on_page_attached);
            tab_view.page_detached.connect(on_page_detached);
            tab_view.notify["selected-page"].connect(on_page_changed);

            // Assemble UI
            main_box.append(header_bar);
            main_box.append(tab_bar);
            main_box.append(tab_view);

            set_content(main_box);

            // Apply window settings
            apply_window_settings();
        }

        private void setup_actions() {
            // Terminal actions
            var copy_action = new SimpleAction("copy", null);
            copy_action.activate.connect(() => {
                var current_tab = get_current_terminal_tab();
                if (current_tab != null) {
                    current_tab.engine.copy_selection();
                }
            });
            add_action(copy_action);

            var paste_action = new SimpleAction("paste", null);
            paste_action.activate.connect(() => {
                var current_tab = get_current_terminal_tab();
                if (current_tab != null) {
                    current_tab.engine.paste_clipboard();
                }
            });
            add_action(paste_action);

            var select_all_action = new SimpleAction("select-all", null);
            select_all_action.activate.connect(() => {
                var current_tab = get_current_terminal_tab();
                if (current_tab != null) {
                    current_tab.engine.select_all();
                }
            });
            add_action(select_all_action);

            var zoom_in_action = new SimpleAction("zoom-in", null);
            zoom_in_action.activate.connect(() => {
                var current_tab = get_current_terminal_tab();
                if (current_tab != null) {
                    current_tab.engine.increase_font_size();
                }
            });
            add_action(zoom_in_action);

            var zoom_out_action = new SimpleAction("zoom-out", null);
            zoom_out_action.activate.connect(() => {
                var current_tab = get_current_terminal_tab();
                if (current_tab != null) {
                    current_tab.engine.decrease_font_size();
                }
            });
            add_action(zoom_out_action);

            var zoom_normal_action = new SimpleAction("zoom-normal", null);
            zoom_normal_action.activate.connect(() => {
                var current_tab = get_current_terminal_tab();
                if (current_tab != null) {
                    current_tab.engine.reset_font_size();
                }
            });
            add_action(zoom_normal_action);

            var reset_action = new SimpleAction("reset", null);
            reset_action.activate.connect(() => {
                var current_tab = get_current_terminal_tab();
                if (current_tab != null) {
                    current_tab.engine.reset_terminal(false);
                }
            });
            add_action(reset_action);

            var reset_clear_action = new SimpleAction("reset-clear", null);
            reset_clear_action.activate.connect(() => {
                var current_tab = get_current_terminal_tab();
                if (current_tab != null) {
                    current_tab.engine.reset_terminal(true);
                }
            });
            add_action(reset_clear_action);

            // Keyboard shortcuts
            var app = get_application();
            app.set_accels_for_action("win.copy", {"<Ctrl><Shift>c"});
            app.set_accels_for_action("win.paste", {"<Ctrl><Shift>v"});
            app.set_accels_for_action("win.select-all", {"<Ctrl><Shift>a"});
            app.set_accels_for_action("win.zoom-in", {"<Ctrl>plus", "<Ctrl>equal"});
            app.set_accels_for_action("win.zoom-out", {"<Ctrl>minus"});
            app.set_accels_for_action("win.zoom-normal", {"<Ctrl>0"});
            app.set_accels_for_action("win.reset", {"<Ctrl><Shift>r"});
            app.set_accels_for_action("win.reset-clear", {"<Ctrl><Shift>k"});

            // Setup key event controller for terminal shortcuts
            setup_key_controller();
        }

        public void new_tab() {
            var terminal_tab = new TerminalTab(settings);
            terminal_tabs.append(terminal_tab);

            var page = tab_view.append(terminal_tab.scrolled_window);
            page.title = _("Terminal");
            page.icon = new ThemedIcon("utilities-terminal-symbolic");

            // Connect terminal signals
            terminal_tab.engine.window_title_changed.connect((title) => {
                page.title = title != "" ? title : _("Terminal");
            });

            terminal_tab.engine.child_exited.connect((status) => {
                if (settings.close_tab_on_exit) {
                    close_tab(terminal_tab);
                }
            });

            tab_view.selected_page = page;
            terminal_tab.engine.spawn_shell();
        }

        public void close_current_tab() {
            var current_tab = get_current_terminal_tab();
            if (current_tab != null) {
                close_tab(current_tab);
            }
        }

        private void close_tab(TerminalTab tab) {
            var page = tab_view.get_page(tab.scrolled_window);
            if (page != null) {
                tab_view.close_page(page);
            }
        }

        private bool on_close_page(Adw.TabPage page) {
            var terminal_tab = find_terminal_tab_by_widget(page.child);
            if (terminal_tab != null) {
                terminal_tabs.remove(terminal_tab);
            }

            // Close window if no tabs left after this one is closed
            if (tab_view.n_pages <= 1) {
                // Allow the tab to close and then close the window
                Idle.add(() => {
                    close();
                    return false;
                });
            }

            // Return false to allow the tab to close
            return false;
        }

        private void on_page_attached(Adw.TabPage page, int position) {
            // Handle page attached
        }

        private void on_page_detached(Adw.TabPage page, int position) {
            // Handle page detached
        }

        private void on_page_changed() {
            // Update window title based on current tab
            var current_tab = get_current_terminal_tab();
            if (current_tab != null) {
                var page = tab_view.selected_page;
                if (page != null) {
                    title = page.title;
                }
            }
        }

        private TerminalTab? get_current_terminal_tab() {
            var page = tab_view.selected_page;
            if (page != null) {
                return find_terminal_tab_by_widget(page.child);
            }
            return null;
        }

        private TerminalTab? find_terminal_tab_by_widget(Gtk.Widget widget) {
            foreach (var tab in terminal_tabs) {
                if (tab.scrolled_window == widget) {
                    return tab;
                }
            }
            return null;
        }

        public void show_preferences() {
            if (preferences_dialog == null) {
                preferences_dialog = new PreferencesDialog(settings);
                preferences_dialog.closed.connect(() => {
                    preferences_dialog = null;
                });
            }

            preferences_dialog.present(this);
        }

        private void apply_window_settings() {
            // Window transparency
            if (settings.window_transparency > 0.0) {
                // Note: Window transparency would need compositor support
                // For now, we can set the CSS background with alpha
                var css_provider = new Gtk.CssProvider();
                double alpha = 1.0 - settings.window_transparency;
                string css = """
                    window {
                        background-color: rgba(0, 0, 0, %f);
                    }
                """.printf(alpha);

                css_provider.load_from_string(css);
                Gtk.StyleContext.add_provider_for_display(get_display(), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            }

            // Always on top
            if (settings.always_on_top) {
                // GTK4 alternative - use surface properties
                var surface = get_surface();
                if (surface != null && surface is Gdk.Toplevel) {
                    var toplevel = (Gdk.Toplevel) surface;
                    try {
                        toplevel.set_property("above", true);
                    } catch (Error e) {
                        debug("Could not set window above: %s", e.message);
                    }
                } else {
                    // If surface not available yet, set when realized
                    notify["surface"].connect(() => {
                        var realized_surface = get_surface();
                        if (realized_surface != null && realized_surface is Gdk.Toplevel) {
                            var toplevel = (Gdk.Toplevel) realized_surface;
                            try {
                                toplevel.set_property("above", true);
                            } catch (Error e) {
                                debug("Could not set window above: %s", e.message);
                            }
                        }
                    });
                }
            }

            // Connect to settings changes
            settings.changed.connect(on_window_settings_changed);
        }

        private void load_window_state() {
            if (settings.remember_window_size) {
                set_default_size(settings.window_width, settings.window_height);

                if (settings.window_maximized) {
                    maximize();
                }
            }
        }

        private void save_window_state() {
            if (settings.remember_window_size) {
                int width, height;
                get_default_size(out width, out height);

                // Only save if window has reasonable dimensions
                if (width > 200 && height > 150) {
                    settings.window_width = width;
                    settings.window_height = height;
                }
                settings.window_maximized = is_maximized();
            }
        }

        private void on_window_settings_changed(string key) {
            switch (key) {
                case "always-on-top":
                case "window-transparency":
                    apply_window_settings();
                    break;
                case "remember-window-size":
                    if (settings.remember_window_size) {
                        load_window_state();
                    }
                    break;
            }
        }

        public override bool close_request() {
            save_window_state();
            return base.close_request();
        }

        // Auto-save window state periodically and on size changes
        private uint save_timeout_id = 0;

        private void schedule_save_window_state() {
            if (save_timeout_id > 0) {
                Source.remove(save_timeout_id);
            }

            // Save after 2 seconds of no changes
            save_timeout_id = Timeout.add(2000, () => {
                save_window_state();
                save_timeout_id = 0;
                return false;
            });
        }

        public override void size_allocate(int width, int height, int baseline) {
            base.size_allocate(width, height, baseline);

            if (settings.remember_window_size) {
                schedule_save_window_state();
            }
        }

        private void setup_key_controller() {
            var key_controller = new Gtk.EventControllerKey();
            key_controller.key_pressed.connect(on_key_pressed);
            ((Gtk.Widget) this).add_controller(key_controller);
        }

        private bool on_key_pressed(uint keyval, uint keycode, Gdk.ModifierType state) {
            // Handle Ctrl+Shift combinations for terminal
            if ((state & Gdk.ModifierType.CONTROL_MASK) != 0 &&
                (state & Gdk.ModifierType.SHIFT_MASK) != 0) {

                switch (keyval) {
                    case Gdk.Key.C:
                    case Gdk.Key.c:
                        activate_action("copy", null);
                        return true;
                    case Gdk.Key.V:
                    case Gdk.Key.v:
                        activate_action("paste", null);
                        return true;
                    case Gdk.Key.A:
                    case Gdk.Key.a:
                        activate_action("select-all", null);
                        return true;
                    case Gdk.Key.T:
                    case Gdk.Key.t:
                        activate_action("app.new-tab", null);
                        return true;
                    case Gdk.Key.W:
                    case Gdk.Key.w:
                        activate_action("app.close-tab", null);
                        return true;
                }
            }

            // Handle Ctrl combinations
            if ((state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                switch (keyval) {
                    case Gdk.Key.plus:
                    case Gdk.Key.equal:
                        activate_action("zoom-in", null);
                        return true;
                    case Gdk.Key.minus:
                        activate_action("zoom-out", null);
                        return true;
                    case Gdk.Key.@0:
                        activate_action("zoom-normal", null);
                        return true;
                }
            }

            return false;
        }
    }

    public class TerminalTab : Object {
        public TerminalEngine engine { get; set; }
        public Gtk.ScrolledWindow scrolled_window { get; set; }

        public TerminalTab(Settings settings) {
            Object();

            engine = new TerminalEngine(settings);
            scrolled_window = new Gtk.ScrolledWindow() {
                hscrollbar_policy = Gtk.PolicyType.NEVER,
                vscrollbar_policy = Gtk.PolicyType.AUTOMATIC,
                child = engine.terminal
            };

            engine.terminal.grab_focus();
        }
    }

    public class PreferencesDialog : Adw.PreferencesDialog {
        private Settings settings;

        public PreferencesDialog(Settings settings) {
            Object(
                title: _("Preferences"),
                content_width: 600,
                content_height: 500
            );

            this.settings = settings;
            build_ui();
        }

        private void build_ui() {
            // General page
            var general_page = new Adw.PreferencesPage() {
                title = _("General"),
                icon_name = "preferences-system-symbolic"
            };

            add_general_groups(general_page);
            add(general_page);

            // Appearance page
            var appearance_page = new Adw.PreferencesPage() {
                title = _("Appearance"),
                icon_name = "preferences-desktop-theme-symbolic"
            };

            add_appearance_groups(appearance_page);
            add(appearance_page);

            // Behavior page
            var behavior_page = new Adw.PreferencesPage() {
                title = _("Behavior"),
                icon_name = "preferences-desktop-symbolic"
            };

            add_behavior_groups(behavior_page);
            add(behavior_page);

            // Advanced page
            var advanced_page = new Adw.PreferencesPage() {
                title = _("Advanced"),
                icon_name = "preferences-other-symbolic"
            };

            add_advanced_groups(advanced_page);
            add(advanced_page);
        }

        private void add_general_groups(Adw.PreferencesPage page) {
            // Shell group
            var shell_group = new Adw.PreferencesGroup() {
                title = _("Shell")
            };

            var custom_shell_row = new Adw.EntryRow() {
                title = _("Custom Shell Command"),
                text = settings.custom_shell_command
            };
            custom_shell_row.notify["text"].connect(() => {
                settings.custom_shell_command = custom_shell_row.text;
            });
            shell_group.add(custom_shell_row);

            var run_custom_switch = new Adw.SwitchRow() {
                title = _("Run Custom Command Instead of Shell"),
                active = settings.run_custom_command
            };
            run_custom_switch.notify["active"].connect(() => {
                settings.run_custom_command = run_custom_switch.active;
            });
            shell_group.add(run_custom_switch);

            var custom_command_row = new Adw.EntryRow() {
                title = _("Custom Command"),
                text = settings.custom_command,
                sensitive = settings.run_custom_command
            };
            custom_command_row.notify["text"].connect(() => {
                settings.custom_command = custom_command_row.text;
            });
            run_custom_switch.bind_property("active", custom_command_row, "sensitive", BindingFlags.SYNC_CREATE);
            shell_group.add(custom_command_row);

            page.add(shell_group);

            // Window group
            var window_group = new Adw.PreferencesGroup() {
                title = _("Window")
            };

            var remember_size_switch = new Adw.SwitchRow() {
                title = _("Remember Window Size"),
                active = settings.remember_window_size
            };
            remember_size_switch.notify["active"].connect(() => {
                settings.remember_window_size = remember_size_switch.active;
            });
            window_group.add(remember_size_switch);

            var always_on_top_switch = new Adw.SwitchRow() {
                title = _("Always on Top"),
                active = settings.always_on_top
            };
            always_on_top_switch.notify["active"].connect(() => {
                settings.always_on_top = always_on_top_switch.active;
            });
            window_group.add(always_on_top_switch);

            var close_tab_exit_switch = new Adw.SwitchRow() {
                title = _("Close Tab When Process Exits"),
                active = settings.close_tab_on_exit
            };
            close_tab_exit_switch.notify["active"].connect(() => {
                settings.close_tab_on_exit = close_tab_exit_switch.active;
            });
            window_group.add(close_tab_exit_switch);

            page.add(window_group);
        }

        private void add_appearance_groups(Adw.PreferencesPage page) {
            // Font group
            var font_group = new Adw.PreferencesGroup() {
                title = _("Font")
            };

            var font_dialog = new Gtk.FontDialog();
            var font_button = new Gtk.FontDialogButton(font_dialog) {
                font_desc = Pango.FontDescription.from_string(settings.font),
                use_font = true,
                use_size = true
            };
            font_button.notify["font-desc"].connect(() => {
                var desc = font_button.get_font_desc();
                if (desc != null) {
                    settings.font = desc.to_string();
                }
            });

            var font_row = new Adw.ActionRow() {
                title = _("Terminal Font")
            };
            font_row.add_suffix(font_button);
            font_group.add(font_row);

            var allow_bold_switch = new Adw.SwitchRow() {
                title = _("Allow Bold Text"),
                active = settings.allow_bold
            };
            allow_bold_switch.notify["active"].connect(() => {
                settings.allow_bold = allow_bold_switch.active;
            });
            font_group.add(allow_bold_switch);

            page.add(font_group);

            // Colors group
            var colors_group = new Adw.PreferencesGroup() {
                title = _("Colors")
            };

            var use_theme_switch = new Adw.SwitchRow() {
                title = _("Use System Theme Colors"),
                active = settings.use_theme_colors
            };
            use_theme_switch.notify["active"].connect(() => {
                settings.use_theme_colors = use_theme_switch.active;
            });
            colors_group.add(use_theme_switch);

            var fg_color_dialog = new Gtk.ColorDialog() { with_alpha = false };
            var fg_color = new Gtk.ColorDialogButton(fg_color_dialog);
            var fg_rgba = Gdk.RGBA();
            fg_rgba.parse(settings.foreground_color);
            fg_color.rgba = fg_rgba;
            fg_color.notify["rgba"].connect(() => {
                var c = fg_color.get_rgba();
                if (c != null) settings.foreground_color = c.to_string();
            });

            var fg_row = new Adw.ActionRow() {
                title = _("Foreground Color"),
                sensitive = !settings.use_theme_colors
            };
            fg_row.add_suffix(fg_color);
            use_theme_switch.bind_property("active", fg_row, "sensitive", BindingFlags.SYNC_CREATE | BindingFlags.INVERT_BOOLEAN);
            colors_group.add(fg_row);

            var bg_color_dialog = new Gtk.ColorDialog() { with_alpha = false };
            var bg_color = new Gtk.ColorDialogButton(bg_color_dialog);
            var bg_rgba = Gdk.RGBA();
            bg_rgba.parse(settings.background_color);
            bg_color.rgba = bg_rgba;
            bg_color.notify["rgba"].connect(() => {
                var c = bg_color.get_rgba();
                if (c != null) settings.background_color = c.to_string();
            });

            var bg_row = new Adw.ActionRow() {
                title = _("Background Color"),
                sensitive = !settings.use_theme_colors
            };
            bg_row.add_suffix(bg_color);
            use_theme_switch.bind_property("active", bg_row, "sensitive", BindingFlags.SYNC_CREATE | BindingFlags.INVERT_BOOLEAN);
            colors_group.add(bg_row);

            // Transparency
            var transparency_scale = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL, 0.0, 1.0, 0.1) {
                draw_value = true,
                digits = 1,
                hexpand = true
            };
            transparency_scale.set_value(settings.background_transparency);
            transparency_scale.value_changed.connect(() => {
                settings.background_transparency = transparency_scale.get_value();
            });

            var transparency_row = new Adw.ActionRow() {
                title = _("Background Transparency"),
                subtitle = _("0.0 = Opaque, 1.0 = Transparent")
            };
            transparency_row.add_suffix(transparency_scale);
            colors_group.add(transparency_row);

            page.add(colors_group);

            // Cursor group
            var cursor_group = new Adw.PreferencesGroup() {
                title = _("Cursor")
            };

            var cursor_shape_combo = new Adw.ComboRow() {
                title = _("Cursor Shape"),
                model = create_cursor_shape_model(),
                selected = settings.cursor_shape
            };
            cursor_shape_combo.notify["selected"].connect(() => {
                settings.cursor_shape = (int) cursor_shape_combo.selected;
            });
            cursor_group.add(cursor_shape_combo);

            var cursor_blink_switch = new Adw.SwitchRow() {
                title = _("Cursor Blinking"),
                active = settings.cursor_blink
            };
            cursor_blink_switch.notify["active"].connect(() => {
                settings.cursor_blink = cursor_blink_switch.active;
            });
            cursor_group.add(cursor_blink_switch);

            page.add(cursor_group);
        }

        private void add_behavior_groups(Adw.PreferencesPage page) {
            // Scrolling group
            var scrolling_group = new Adw.PreferencesGroup() {
                title = _("Scrolling")
            };

            var scrollback_spin = new Gtk.SpinButton.with_range(100, 100000, 100) {
                value = settings.scrollback_lines
            };
            scrollback_spin.value_changed.connect(() => {
                settings.scrollback_lines = (int) scrollback_spin.value;
            });

            var scrollback_row = new Adw.ActionRow() {
                title = _("Scrollback Lines")
            };
            scrollback_row.add_suffix(scrollback_spin);
            scrolling_group.add(scrollback_row);

            var scroll_output_switch = new Adw.SwitchRow() {
                title = _("Scroll on Output"),
                active = settings.scroll_on_output
            };
            scroll_output_switch.notify["active"].connect(() => {
                settings.scroll_on_output = scroll_output_switch.active;
            });
            scrolling_group.add(scroll_output_switch);

            var scroll_keystroke_switch = new Adw.SwitchRow() {
                title = _("Scroll on Keystroke"),
                active = settings.scroll_on_keystroke
            };
            scroll_keystroke_switch.notify["active"].connect(() => {
                settings.scroll_on_keystroke = scroll_keystroke_switch.active;
            });
            scrolling_group.add(scroll_keystroke_switch);

            page.add(scrolling_group);

            // Mouse group
            var mouse_group = new Adw.PreferencesGroup() {
                title = _("Mouse")
            };

            var mouse_autohide_switch = new Adw.SwitchRow() {
                title = _("Hide Mouse When Typing"),
                active = settings.mouse_autohide
            };
            mouse_autohide_switch.notify["active"].connect(() => {
                settings.mouse_autohide = mouse_autohide_switch.active;
            });
            mouse_group.add(mouse_autohide_switch);

            var copy_select_switch = new Adw.SwitchRow() {
                title = _("Copy on Select"),
                active = settings.copy_on_select
            };
            copy_select_switch.notify["active"].connect(() => {
                settings.copy_on_select = copy_select_switch.active;
            });
            mouse_group.add(copy_select_switch);

            page.add(mouse_group);

            // Bell group
            var bell_group = new Adw.PreferencesGroup() {
                title = _("Bell")
            };

            var audible_bell_switch = new Adw.SwitchRow() {
                title = _("Audible Bell"),
                active = settings.audible_bell
            };
            audible_bell_switch.notify["active"].connect(() => {
                settings.audible_bell = audible_bell_switch.active;
            });
            bell_group.add(audible_bell_switch);

            var urgent_bell_switch = new Adw.SwitchRow() {
                title = _("Urgent Bell (Flash Window)"),
                active = settings.urgent_bell
            };
            urgent_bell_switch.notify["active"].connect(() => {
                settings.urgent_bell = urgent_bell_switch.active;
            });
            bell_group.add(urgent_bell_switch);

            page.add(bell_group);
        }

        private void add_advanced_groups(Adw.PreferencesPage page) {
            // Text group
            var text_group = new Adw.PreferencesGroup() {
                title = _("Text Selection")
            };

            var word_chars_entry = new Adw.EntryRow() {
                title = _("Word Characters"),
                text = settings.word_chars
            };
            word_chars_entry.notify["text"].connect(() => {
                settings.word_chars = word_chars_entry.text;
            });
            text_group.add(word_chars_entry);

            var hyperlinks_switch = new Adw.SwitchRow() {
                title = _("Allow Hyperlinks"),
                active = settings.allow_hyperlinks
            };
            hyperlinks_switch.notify["active"].connect(() => {
                settings.allow_hyperlinks = hyperlinks_switch.active;
            });
            text_group.add(hyperlinks_switch);

            page.add(text_group);

            // Performance group
            var performance_group = new Adw.PreferencesGroup() {
                title = _("Performance")
            };

            // Reset button
            var reset_button = new Gtk.Button() {
                label = _("Reset All Settings"),
                css_classes = {"destructive-action"}
            };
            reset_button.clicked.connect(() => {
                show_reset_dialog();
            });

            var reset_row = new Adw.ActionRow() {
                title = _("Reset Settings"),
                subtitle = _("Reset all preferences to default values")
            };
            reset_row.add_suffix(reset_button);
            performance_group.add(reset_row);

            page.add(performance_group);
        }

        private GLib.ListModel create_cursor_shape_model() {
            var store = new Gtk.StringList(null);
            store.append(_("Block"));
            store.append(_("I-Beam"));
            store.append(_("Underline"));
            return store;
        }

        private void show_reset_dialog() {
            var dialog = new Adw.AlertDialog(
                _("Reset All Settings?"),
                _("This will reset all preferences to their default values. This action cannot be undone.")
            );

            dialog.add_response("cancel", _("Cancel"));
            dialog.add_response("reset", _("Reset"));
            dialog.set_response_appearance("reset", Adw.ResponseAppearance.DESTRUCTIVE);
            dialog.set_default_response("cancel");
            dialog.set_close_response("cancel");

            dialog.response.connect((response) => {
                if (response == "reset") {
                    settings.reset_all();
                    close();
                }
            });

            dialog.present(this);
        }
    }
}
