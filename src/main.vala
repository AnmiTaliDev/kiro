using Gtk;
using Adw;

namespace Kiro {
    public class Application : Adw.Application {
        private const string APP_ID = "kz.anmitali.kiro";
        private const string APP_VERSION = "1.0.0";
        
        private MainWindow? main_window = null;
        private Settings settings;
        
        public Application() {
            Object(
                application_id: APP_ID,
                flags: ApplicationFlags.DEFAULT_FLAGS
            );
            
            settings = new Settings();
        }
        
        protected override void activate() {
            if (main_window == null) {
                main_window = new MainWindow(this, settings);
            }
            
            main_window.present();
        }
        
        protected override void startup() {
            base.startup();
            
            setup_actions();
            setup_shortcuts();
        }
        
        private void setup_actions() {
            var quit_action = new SimpleAction("quit", null);
            quit_action.activate.connect(() => {
                if (main_window != null) {
                    main_window.close();
                }
            });
            add_action(quit_action);
            
            var about_action = new SimpleAction("about", null);
            about_action.activate.connect(show_about_dialog);
            add_action(about_action);
            
            var preferences_action = new SimpleAction("preferences", null);
            preferences_action.activate.connect(() => {
                if (main_window != null) {
                    main_window.show_preferences();
                }
            });
            add_action(preferences_action);
            
            var new_tab_action = new SimpleAction("new-tab", null);
            new_tab_action.activate.connect(() => {
                if (main_window != null) {
                    main_window.new_tab();
                }
            });
            add_action(new_tab_action);
            
            var close_tab_action = new SimpleAction("close-tab", null);
            close_tab_action.activate.connect(() => {
                if (main_window != null) {
                    main_window.close_current_tab();
                }
            });
            add_action(close_tab_action);
        }
        
        private void setup_shortcuts() {
            set_accels_for_action("app.quit", {"<Ctrl>q"});
            set_accels_for_action("app.preferences", {"<Ctrl>comma"});
            set_accels_for_action("app.new-tab", {"<Ctrl><Shift>t"});
            set_accels_for_action("app.close-tab", {"<Ctrl><Shift>w"});
        }
        
        private void show_about_dialog() {
            var about = new Adw.AboutWindow() {
                transient_for = main_window,
                modal = true,
                application_name = "Kiro",
                application_icon = "utilities-terminal",
                version = APP_VERSION,
                developer_name = "AnmiTaliDev",
                website = "https://github.com/AnmiTaliDev/kiro",
                issue_url = "https://github.com/AnmiTaliDev/kiro/issues",
                license_type = License.GPL_3_0,
                copyright = "© 2024 AnmiTaliDev",
                developers = {"AnmiTaliDev <anmitali198@gmail.com>"},
                translator_credits = _("translator-credits")
            };
            
            about.present();
        }
    }
}

int main(string[] args) {
    // Try to bind to different locale directories
    string[] locale_dirs = {
        "/usr/local/share/locale",
        "/usr/share/locale"
    };
    
    bool found_locale = false;
    foreach (string locale_dir in locale_dirs) {
        if (FileUtils.test(locale_dir, FileTest.IS_DIR)) {
            Intl.bindtextdomain("kiro", locale_dir);
            found_locale = true;
            break;
        }
    }
    
    // Fallback if no locale directory found
    if (!found_locale) {
        Intl.bindtextdomain("kiro", "/usr/share/locale");
    }
    
    Intl.bind_textdomain_codeset("kiro", "UTF-8");
    Intl.textdomain("kiro");
    
    var app = new Kiro.Application();
    return app.run(args);
}