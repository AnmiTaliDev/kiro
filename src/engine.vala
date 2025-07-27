using Gtk;
using Vte;

namespace Kiro {
    public class TerminalEngine : Object {
        public Vte.Terminal terminal { get; construct; }
        public Settings settings { get; construct; }
        
        private Vte.Pty? pty = null;
        private GLib.Pid child_pid = -1;
        
        public signal void window_title_changed(string title);
        public signal void child_exited(int status);
        
        public TerminalEngine(Settings settings) {
            Object(
                terminal: new Vte.Terminal(),
                settings: settings
            );
            
            setup_terminal();
            connect_signals();
        }
        
        private void setup_terminal() {
            // Basic terminal configuration
            terminal.audible_bell = settings.audible_bell;
            terminal.cursor_blink_mode = settings.cursor_blink ? Vte.CursorBlinkMode.ON : Vte.CursorBlinkMode.OFF;
            terminal.cursor_shape = (Vte.CursorShape) settings.cursor_shape;
            
            // Mouse autohide - use event controller for modern implementation
            var motion_controller = new Gtk.EventControllerMotion();
            var autohide_timeout_id = 0u;
            
            motion_controller.motion.connect(() => {
                if (settings.mouse_autohide) {
                    terminal.set_cursor_from_name("text");
                    if (autohide_timeout_id > 0) {
                        Source.remove(autohide_timeout_id);
                    }
                    autohide_timeout_id = Timeout.add(3000, () => {
                        terminal.set_cursor_from_name("none");
                        autohide_timeout_id = 0;
                        return false;
                    });
                }
            });
            terminal.add_controller(motion_controller);
            
            terminal.allow_hyperlink = settings.allow_hyperlinks;
            terminal.scroll_on_output = settings.scroll_on_output;
            terminal.scroll_on_keystroke = settings.scroll_on_keystroke;
            terminal.rewrap_on_resize = true;
            
            // Set UTF-8 encoding explicitly 
            try {
                terminal.set_encoding("UTF-8");
            } catch (Error e) {
                debug("Could not set UTF-8 encoding: %s", e.message);
            }
            
            // Scrollback
            terminal.set_scrollback_lines(settings.scrollback_lines);
            
            // Font
            update_font();
            
            // Colors
            update_colors();
            
            // Text selection
            terminal.set_word_char_exceptions(settings.word_chars);
            
            // Bell urgent functionality - use window urgency hint
            if (settings.urgent_bell) {
                terminal.bell.connect(() => {
                    var toplevel = terminal.get_root() as Gtk.Window;
                    if (toplevel != null) {
                        // GTK4 doesn't have set_urgency_hint, use native window operations
                        var display = toplevel.get_display();
                        if (display != null) {
                            display.beep(); // Fallback to system beep
                        }
                    }
                });
            }
            
            // Encoding
            // UTF-8 encoding is default in modern VTE versions
            // No need to explicitly set encoding
            
            // Allow bold text - handled through CSS styling
            if (settings.allow_bold) {
                var css_provider = new Gtk.CssProvider();
                css_provider.load_from_data("terminal text { font-weight: bold; }".data);
                terminal.get_style_context().add_provider(css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            }
            
            // Context menu
            setup_context_menu();
            
            // Drag and drop
            setup_drag_and_drop();
            
            // URL detection
            setup_url_detection();
        }
        
        private void setup_context_menu() {
            var click_gesture = new Gtk.GestureClick();
            click_gesture.button = 3; // Right click
            click_gesture.pressed.connect((n_press, x, y) => {
                show_context_menu(x, y);
            });
            terminal.add_controller(click_gesture);
        }
        
        private void connect_signals() {
            settings.changed.connect(on_settings_changed);
            
            terminal.window_title_changed.connect(() => {
                window_title_changed(terminal.get_window_title() ?? "Terminal");
            });
            
            terminal.child_exited.connect((status) => {
                child_exited(status);
            });
            
            terminal.selection_changed.connect(() => {
                if (terminal.get_has_selection() && settings.copy_on_select) {
                    copy_selection();
                }
            });
        }
        
        public void spawn_shell() {
            string[] spawn_env = Environ.get();
            
            // Set terminal environment variables
            spawn_env += "TERM=xterm-256color";
            spawn_env += "COLORTERM=truecolor";
            spawn_env += "VTE_VERSION=6003";
            
            // Preserve user's locale if set, otherwise use UTF-8
            string current_lang = Environment.get_variable("LANG");
            if (current_lang == null || current_lang == "") {
                spawn_env += "LANG=C.UTF-8";
                spawn_env += "LC_ALL=C.UTF-8";
            } else {
                // Only ensure UTF-8 if the locale doesn't already have UTF-8 encoding
                if (!current_lang.has_suffix(".UTF-8") && !current_lang.has_suffix(".utf8")) {
                    // For locales like "ru_RU.UTF-8", don't modify them
                    if (current_lang.contains(".")) {
                        // Replace existing encoding with UTF-8
                        string[] parts = current_lang.split(".");
                        if (parts.length >= 1) {
                            current_lang = parts[0] + ".UTF-8";
                        }
                    } else {
                        // Add UTF-8 encoding if no encoding specified
                        current_lang = current_lang + ".UTF-8";
                    }
                    spawn_env += "LANG=" + current_lang;
                } else {
                    // Locale already has UTF-8, use as-is
                    spawn_env += "LANG=" + current_lang;
                }
            }
            
            string shell = settings.custom_shell_command;
            if (shell == "") {
                shell = Environment.get_variable("SHELL") ?? "/bin/bash";
            }
            
            // Validate shell/command exists and is executable
            string[] spawn_argv;
            if (settings.run_custom_command) {
                try {
                    Shell.parse_argv(settings.custom_command, out spawn_argv);
                    
                    // Validate custom command
                    if (spawn_argv.length > 0) {
                        string command_path = spawn_argv[0];
                        if (!validate_command(command_path)) {
                            warning("Custom command '%s' not found or not executable, falling back to shell", command_path);
                            spawn_argv = {shell};
                        }
                    }
                } catch (ShellError e) {
                    warning("Failed to parse custom command: %s", e.message);
                    spawn_argv = {shell};
                }
            } else {
                spawn_argv = {shell};
            }
            
            // Final validation of shell
            if (spawn_argv.length > 0 && !validate_command(spawn_argv[0])) {
                warning("Shell '%s' not found or not executable, trying fallback shells", spawn_argv[0]);
                
                // Try common fallback shells
                string[] fallback_shells = {"/bin/bash", "/bin/sh", "/usr/bin/bash", "/usr/bin/sh"};
                bool found_shell = false;
                
                foreach (string fallback in fallback_shells) {
                    if (validate_command(fallback)) {
                        spawn_argv = {fallback};
                        found_shell = true;
                        debug("Using fallback shell: %s", fallback);
                        break;
                    }
                }
                
                if (!found_shell) {
                    warning("No usable shell found, terminal may not work properly");
                    // Still try the original command - maybe it will work
                }
            }
            
            try {
                terminal.spawn_async(
                    Vte.PtyFlags.DEFAULT,
                    null, // working directory
                    spawn_argv,
                    spawn_env,
                    SpawnFlags.SEARCH_PATH,
                    null, // child setup
                    -1, // timeout
                    null, // cancellable
                    (terminal, pid, error) => {
                        if (error != null) {
                            warning("Failed to spawn shell: %s", error.message);
                            show_spawn_error(error.message);
                        } else {
                            child_pid = pid;
                            debug("Successfully spawned shell with PID: %d", (int)pid);
                        }
                    }
                );
            } catch (Error e) {
                warning("Failed to spawn shell: %s", e.message);
                show_spawn_error(e.message);
            }
        }
        
        private bool validate_command(string command_path) {
            // Check if command exists and is executable
            var file = File.new_for_path(command_path);
            
            // First check if absolute path exists
            if (command_path.has_prefix("/")) {
                if (!file.query_exists()) {
                    return false;
                }
                
                try {
                    var info = file.query_info(FileAttribute.ACCESS_CAN_EXECUTE, FileQueryInfoFlags.NONE);
                    return info.get_attribute_boolean(FileAttribute.ACCESS_CAN_EXECUTE);
                } catch (Error e) {
                    debug("Cannot check executable status for '%s': %s", command_path, e.message);
                    return false;
                }
            } else {
                // For relative commands, check if they exist in PATH
                string? full_path = Environment.find_program_in_path(command_path);
                return full_path != null;
            }
        }
        
        private void show_spawn_error(string error_message) {
            // Send error message to terminal
            string error_text = "Failed to start shell: %s\r\n".printf(error_message);
            error_text += "Please check your shell configuration in preferences.\r\n";
            error_text += "Press Ctrl+, to open preferences or Ctrl+Shift+T for a new tab.\r\n\r\n";
            
            try {
                terminal.feed(error_text.data);
            } catch (Error e) {
                warning("Failed to display error in terminal: %s", e.message);
            }
        }
        
        public void copy_selection() {
            if (terminal.get_has_selection()) {
                string text = terminal.get_text_selected(Vte.Format.TEXT);
                var clipboard = Gdk.Display.get_default().get_clipboard();
                clipboard.set_text(text);
            }
        }
        
        public void paste_clipboard() {
            var clipboard = Gdk.Display.get_default().get_clipboard();
            clipboard.read_text_async.begin(null, (obj, res) => {
                try {
                    string? text = clipboard.read_text_async.end(res);
                    if (text != null && text.length > 0) {
                        terminal.paste_text(text);
                    }
                } catch (Error e) {
                    warning("Failed to paste: %s", e.message);
                }
            });
        }
        
        public void select_all() {
            terminal.select_all();
        }
        
        public void reset_terminal(bool clear_history = false) {
            terminal.reset(true, clear_history);
        }
        
        public void send_text(string text) {
            try {
                terminal.feed_child(text.data);
            } catch (Error e) {
                warning("Failed to send text: %s", e.message);
            }
        }
        
        public void increase_font_size() {
            var font_desc = terminal.get_font();
            var current_size = font_desc.get_size();
            if (current_size < 72 * Pango.SCALE) {
                font_desc.set_size(current_size + Pango.SCALE);
                terminal.set_font(font_desc);
            }
        }
        
        public void decrease_font_size() {
            var font_desc = terminal.get_font();
            var current_size = font_desc.get_size();
            if (current_size > 6 * Pango.SCALE) {
                font_desc.set_size(current_size - Pango.SCALE);
                terminal.set_font(font_desc);
            }
        }
        
        public void reset_font_size() {
            update_font();
        }
        
        private void update_font() {
            var font_desc = Pango.FontDescription.from_string(settings.font);
            terminal.set_font(font_desc);
        }
        
        private void update_colors() {
            Gdk.RGBA foreground = {1.0f, 1.0f, 1.0f, 1.0f};
            Gdk.RGBA background = {0.0f, 0.0f, 0.0f, 1.0f};
            
            if (settings.use_theme_colors) {
                // Use system theme colors from CSS provider
                var css_provider = new Gtk.CssProvider();
                css_provider.load_from_data("terminal { color: @theme_fg_color; background-color: @theme_bg_color; }".data);
                
                var context = terminal.get_style_context();
                context.add_provider(css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
                
                // Get colors from computed style
                var fg_color = context.get_color();
                foreground = {(float)fg_color.red, (float)fg_color.green, (float)fg_color.blue, (float)fg_color.alpha};
                
                // For background, use a reasonable default based on theme
                var display = terminal.get_display();
                var default_settings = Gtk.Settings.get_for_display(display);
                string theme_name;
                default_settings.get("gtk-theme-name", out theme_name);
                
                // Check if dark theme
                bool prefer_dark = false;
                default_settings.get("gtk-application-prefer-dark-theme", out prefer_dark);
                bool is_dark_theme = theme_name.down().contains("dark") || prefer_dark;
                
                if (is_dark_theme) {
                    background = {0.1f, 0.1f, 0.1f, 1.0f}; // Dark background
                } else {
                    background = {0.95f, 0.95f, 0.95f, 1.0f}; // Light background
                }
            } else {
                // Use custom colors
                foreground.parse(settings.foreground_color);
                background.parse(settings.background_color);
            }
            
            terminal.set_colors(foreground, background, null);
            
            // Set palette colors
            if (!settings.use_theme_colors && settings.palette_colors.length == 16) {
                Gdk.RGBA[] palette = new Gdk.RGBA[16];
                for (int i = 0; i < 16; i++) {
                    palette[i].parse(settings.palette_colors[i]);
                }
                terminal.set_colors(foreground, background, palette);
            }
            
            // Set transparency
            if (settings.background_transparency > 0.0) {
                background.alpha = (float)(1.0 - settings.background_transparency);
                terminal.set_colors(foreground, background, null);
            }
        }
        
        private void on_settings_changed(string key) {
            switch (key) {
                case "font":
                    update_font();
                    break;
                case "foreground-color":
                case "background-color":
                case "use-theme-colors":
                case "palette-colors":
                case "background-transparency":
                    update_colors();
                    break;
                case "audible-bell":
                    terminal.audible_bell = settings.audible_bell;
                    break;
                case "cursor-blink":
                    terminal.cursor_blink_mode = settings.cursor_blink ? 
                        Vte.CursorBlinkMode.ON : Vte.CursorBlinkMode.OFF;
                    break;
                case "cursor-shape":
                    terminal.cursor_shape = (Vte.CursorShape) settings.cursor_shape;
                    break;
                case "scrollback-lines":
                    terminal.set_scrollback_lines(settings.scrollback_lines);
                    break;
                case "mouse-autohide":
                    // Mouse autohide is handled by motion controller setup
                    // Re-setup terminal to apply changes
                    setup_terminal();
                    break;
                case "allow-bold":
                    // Update CSS styling for bold text
                    var context = terminal.get_style_context();
                    if (settings.allow_bold) {
                        var css_provider = new Gtk.CssProvider();
                        css_provider.load_from_data("terminal text { font-weight: bold; }".data);
                        context.add_provider(css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
                    } else {
                        // Remove bold styling - simplified approach
                        var css_provider = new Gtk.CssProvider();
                        css_provider.load_from_data("terminal text { font-weight: normal; }".data);
                        context.add_provider(css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
                    }
                    break;
                case "allow-hyperlinks":
                    terminal.allow_hyperlink = settings.allow_hyperlinks;
                    break;
                case "scroll-on-output":
                    terminal.scroll_on_output = settings.scroll_on_output;
                    break;
                case "scroll-on-keystroke":
                    terminal.scroll_on_keystroke = settings.scroll_on_keystroke;
                    break;
                case "urgent-bell":
                    // Urgent bell is handled by bell signal connection
                    // Re-setup terminal to apply changes
                    setup_terminal();
                    break;
                case "word-chars":
                    terminal.set_word_char_exceptions(settings.word_chars);
                    break;
            }
        }
        
        private void show_context_menu(double x, double y) {
            var menu = new Gtk.PopoverMenu.from_model(null);
            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 6);
            box.add_css_class("menu");
            
            if (terminal.get_has_selection()) {
                var copy_button = new Gtk.Button.with_label(_("Copy"));
                copy_button.add_css_class("flat");
                copy_button.halign = Gtk.Align.FILL;
                copy_button.clicked.connect(() => {
                    copy_selection();
                    menu.popdown();
                });
                box.append(copy_button);
            }
            
            var paste_button = new Gtk.Button.with_label(_("Paste"));
            paste_button.add_css_class("flat");
            paste_button.halign = Gtk.Align.FILL;
            paste_button.clicked.connect(() => {
                paste_clipboard();
                menu.popdown();
            });
            box.append(paste_button);
            
            var select_all_button = new Gtk.Button.with_label(_("Select All"));
            select_all_button.add_css_class("flat");
            select_all_button.halign = Gtk.Align.FILL;
            select_all_button.clicked.connect(() => {
                select_all();
                menu.popdown();
            });
            box.append(select_all_button);
            
            menu.child = box;
            menu.set_parent(terminal);
            
            var rect = Gdk.Rectangle() {
                x = (int) x,
                y = (int) y,
                width = 1,
                height = 1
            };
            menu.set_pointing_to(rect);
            menu.popup();
        }
        
        private void setup_drag_and_drop() {
            // Set up drop target for files
            var drop_target = new Gtk.DropTarget(typeof(Gdk.FileList), Gdk.DragAction.COPY);
            drop_target.drop.connect(on_drop);
            drop_target.enter.connect(on_drag_enter);
            drop_target.leave.connect(on_drag_leave);
            terminal.add_controller(drop_target);
        }
        
        private bool on_drop(Gtk.DropTarget target, Value val, double x, double y) {
            if (val.holds(typeof(Gdk.FileList))) {
                var file_list = (Gdk.FileList) val.get_object();
                var files = file_list.get_files();
                
                if (files.length() > 0) {
                    StringBuilder sb = new StringBuilder();
                    bool first = true;
                    
                    foreach (var file in files) {
                        if (!first) sb.append(" ");
                        first = false;
                        
                        string path = file.get_path();
                        if (path != null) {
                            // Escape spaces and special characters
                            if (path.contains(" ") || path.contains("'") || path.contains("\"")) {
                                sb.append("'%s'".printf(path.replace("'", "'\\''")));
                            } else {
                                sb.append(path);
                            }
                        } else {
                            // Fallback to URI for non-local files
                            sb.append("'%s'".printf(file.get_uri()));
                        }
                    }
                    
                    // Send the file paths to terminal
                    send_text(sb.str);
                    return true;
                }
            }
            return false;
        }
        
        private Gdk.DragAction on_drag_enter(Gtk.DropTarget target, double x, double y) {
            // Simple visual feedback during drag
            terminal.set_opacity(0.8);
            return Gdk.DragAction.COPY;
        }
        
        private void on_drag_leave(Gtk.DropTarget target) {
            // Restore normal appearance
            terminal.set_opacity(1.0);
        }
        
        private void setup_url_detection() {
            try {
                // Modern VTE regex pattern for URL matching
                string[] url_patterns = {
                    // HTTP/HTTPS URLs
                    "(https?://[\\w.-]+(?:\\.[\\w\\.-]+)+[\\w\\-\\._~:/?#[\\]@!\\$&'\\(\\)\\*\\+,;=.]+)",
                    // FTP URLs
                    "(ftp://[\\w.-]+(?:\\.[\\w\\.-]+)+[\\w\\-\\._~:/?#[\\]@!\\$&'\\(\\)\\*\\+,;=.]*)",
                    // File paths (absolute)
                    "(/[\\w\\-\\._~/]+)",
                    // Email addresses
                    "([\\w\\.-]+@[\\w\\.-]+\\.[a-zA-Z]{2,})"
                };
                
                foreach (string pattern in url_patterns) {
                    try {
                        var regex = new Vte.Regex.for_match(
                            pattern, 
                            pattern.length, 
                            0x40080408u // PCRE2_UTF | PCRE2_NO_UTF_CHECK | PCRE2_CASELESS | PCRE2_MULTILINE
                        );
                        
                        // Add JIT compilation for performance
                        try {
                            regex.jit(0x00000001u); // PCRE2_JIT_COMPLETE
                        } catch (Error jit_error) {
                            // JIT compilation is optional, continue without it
                            debug("JIT compilation failed for pattern '%s': %s", pattern, jit_error.message);
                        }
                        
                        // Add regex to terminal
                        int tag = terminal.match_add_regex(regex, 0);
                        debug("Added URL regex pattern: %s (tag: %d)", pattern, tag);
                        
                    } catch (Error regex_error) {
                        warning("Failed to compile regex pattern '%s': %s", pattern, regex_error.message);
                        continue;
                    }
                }
                
                // Setup click handler for URLs
                var click_gesture = new Gtk.GestureClick();
                click_gesture.button = 1; // Left click
                click_gesture.pressed.connect((n_press, x, y) => {
                    if (n_press == 1) { // Single click
                        string? match;
                        int tag;
                        terminal.match_check((long)x, (long)y, out tag);
                        match = terminal.match_check((long)x, (long)y, out tag);
                        
                        if (match != null && match.length > 0) {
                            try {
                                // Try to open URL/file
                                if (match.has_prefix("http://") || match.has_prefix("https://") || 
                                    match.has_prefix("ftp://") || match.contains("@")) {
                                    var launcher = new Gtk.UriLauncher(match);
                                    launcher.launch.begin(terminal.get_root() as Gtk.Window, null);
                                } else if (match.has_prefix("/")) {
                                    // File path - open with default application
                                    var file = File.new_for_path(match);
                                    if (file.query_exists()) {
                                        var launcher = new Gtk.FileLauncher(file);
                                        launcher.launch.begin(terminal.get_root() as Gtk.Window, null);
                                    }
                                }
                            } catch (Error e) {
                                warning("Failed to open URL/file '%s': %s", match, e.message);
                            }
                        }
                    }
                });
                terminal.add_controller(click_gesture);
                
            } catch (Error e) {
                warning("Failed to setup URL detection: %s", e.message);
            }
        }
    }
}
