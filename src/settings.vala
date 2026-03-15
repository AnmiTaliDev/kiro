using GLib;

namespace Kiro {
    public class Settings : Object {
        private GLib.Settings gsettings;
        
        public signal void changed(string key);
        
        // Window settings
        public bool remember_window_size {
            get { return gsettings.get_boolean("remember-window-size"); }
            set { gsettings.set_boolean("remember-window-size", value); }
        }
        
        public int window_width {
            get { return gsettings.get_int("window-width"); }
            set { gsettings.set_int("window-width", value); }
        }
        
        public int window_height {
            get { return gsettings.get_int("window-height"); }
            set { gsettings.set_int("window-height", value); }
        }
        
        public bool window_maximized {
            get { return gsettings.get_boolean("window-maximized"); }
            set { gsettings.set_boolean("window-maximized", value); }
        }
        
        public bool always_on_top {
            get { return gsettings.get_boolean("always-on-top"); }
            set { gsettings.set_boolean("always-on-top", value); }
        }
        
        public double window_transparency {
            get { return gsettings.get_double("window-transparency"); }
            set { gsettings.set_double("window-transparency", value); }
        }
        
        // Terminal appearance
        public string font {
            owned get { return gsettings.get_string("font"); }
            set { gsettings.set_string("font", value); }
        }
        
        public bool use_theme_colors {
            get { return gsettings.get_boolean("use-theme-colors"); }
            set { gsettings.set_boolean("use-theme-colors", value); }
        }
        
        public string foreground_color {
            owned get { return gsettings.get_string("foreground-color"); }
            set { gsettings.set_string("foreground-color", value); }
        }
        
        public string background_color {
            owned get { return gsettings.get_string("background-color"); }
            set { gsettings.set_string("background-color", value); }
        }
        
        public double background_transparency {
            get { return gsettings.get_double("background-transparency"); }
            set { gsettings.set_double("background-transparency", value); }
        }
        
        public string[] palette_colors {
            owned get { return gsettings.get_strv("palette-colors"); }
            set { gsettings.set_strv("palette-colors", value); }
        }
        
        public bool allow_bold {
            get { return gsettings.get_boolean("allow-bold"); }
            set { gsettings.set_boolean("allow-bold", value); }
        }
        
        // Cursor settings  
        public int cursor_shape {
            get { return gsettings.get_int("cursor-shape"); }
            set { gsettings.set_int("cursor-shape", value); }
        }
        
        public bool cursor_blink {
            get { return gsettings.get_boolean("cursor-blink"); }
            set { gsettings.set_boolean("cursor-blink", value); }
        }
        
        // Scrolling
        public int scrollback_lines {
            get { return gsettings.get_int("scrollback-lines"); }
            set { gsettings.set_int("scrollback-lines", value); }
        }
        
        public bool scroll_on_output {
            get { return gsettings.get_boolean("scroll-on-output"); }
            set { gsettings.set_boolean("scroll-on-output", value); }
        }
        
        public bool scroll_on_keystroke {
            get { return gsettings.get_boolean("scroll-on-keystroke"); }
            set { gsettings.set_boolean("scroll-on-keystroke", value); }
        }
        
        // Mouse and selection
        public bool mouse_autohide {
            get { return gsettings.get_boolean("mouse-autohide"); }
            set { gsettings.set_boolean("mouse-autohide", value); }
        }
        
        public bool copy_on_select {
            get { return gsettings.get_boolean("copy-on-select"); }
            set { gsettings.set_boolean("copy-on-select", value); }
        }
        
        public string word_chars {
            owned get { return gsettings.get_string("word-chars"); }
            set { gsettings.set_string("word-chars", value); }
        }
        
        public bool allow_hyperlinks {
            get { return gsettings.get_boolean("allow-hyperlinks"); }
            set { gsettings.set_boolean("allow-hyperlinks", value); }
        }
        
        // Bell settings
        public bool audible_bell {
            get { return gsettings.get_boolean("audible-bell"); }
            set { gsettings.set_boolean("audible-bell", value); }
        }
        
        public bool urgent_bell {
            get { return gsettings.get_boolean("urgent-bell"); }
            set { gsettings.set_boolean("urgent-bell", value); }
        }
        
        // Shell settings
        public string custom_shell_command {
            owned get { return gsettings.get_string("custom-shell-command"); }
            set { gsettings.set_string("custom-shell-command", value); }
        }
        
        public bool run_custom_command {
            get { return gsettings.get_boolean("run-custom-command"); }
            set { gsettings.set_boolean("run-custom-command", value); }
        }
        
        public string custom_command {
            owned get { return gsettings.get_string("custom-command"); }
            set { gsettings.set_string("custom-command", value); }
        }
        
        // Tab settings
        public bool close_tab_on_exit {
            get { return gsettings.get_boolean("close-tab-on-exit"); }
            set { gsettings.set_boolean("close-tab-on-exit", value); }
        }
        
        public Settings() {
            gsettings = new GLib.Settings("dev.anmitali.kiro");
            gsettings.changed.connect((key) => {
                changed(key);
            });
        }
        
        public void reset_all() {
            string[] keys = {
                "remember-window-size",
                "window-width", 
                "window-height",
                "window-maximized",
                "always-on-top",
                "window-transparency",
                "font",
                "use-theme-colors",
                "foreground-color",
                "background-color", 
                "background-transparency",
                "palette-colors",
                "allow-bold",
                "cursor-shape",
                "cursor-blink",
                "scrollback-lines",
                "scroll-on-output",
                "scroll-on-keystroke",
                "mouse-autohide",
                "copy-on-select",
                "word-chars",
                "allow-hyperlinks",
                "audible-bell",
                "urgent-bell",
                "custom-shell-command",
                "run-custom-command",
                "custom-command",
                "close-tab-on-exit"
            };
            
            foreach (string key in keys) {
                gsettings.reset(key);
            }
        }
    }
}