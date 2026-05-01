#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"
#include <map>
#include <string>

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  FlMethodChannel* method_channel;
  std::map<std::string, std::string>* translations;
  GtkListStore* store;
};

static std::string get_i18n_string(MyApplication* self, const std::string& key, const std::string& fallback) {
    if (self->translations && self->translations->find(key) != self->translations->end()) {
        return (*self->translations)[key];
    }
    return fallback;
}

static void fetch_data(MyApplication* self, int step) {
    if (step == 0) {
        fl_method_channel_invoke_method(self->method_channel, "getTranslations", nullptr, nullptr, [](GObject* source_object, GAsyncResult* res, gpointer user_data) {
            MyApplication* self = MY_APPLICATION(user_data);
            g_autoptr(GError) error = nullptr;
            g_autoptr(FlMethodResponse) response = fl_method_channel_invoke_method_finish(FL_METHOD_CHANNEL(source_object), res, &error);
            if (response) {
                FlValue* result = fl_method_response_get_result(response, nullptr);
                if (result && fl_value_get_type(result) == FL_VALUE_TYPE_MAP) {
                    size_t size = fl_value_get_length(result);
                    for (size_t i = 0; i < size; ++i) {
                        FlValue* key = fl_value_get_map_key(result, i);
                        FlValue* val = fl_value_get_map_value(result, i);
                        if (fl_value_get_type(key) == FL_VALUE_TYPE_STRING && fl_value_get_type(val) == FL_VALUE_TYPE_STRING) {
                            (*self->translations)[fl_value_get_string(key)] = fl_value_get_string(val);
                        }
                    }
                }
            }
            gtk_list_store_clear(self->store);
            fetch_data(self, 1);
        }, self);
    } else if (step == 1) {
        fl_method_channel_invoke_method(self->method_channel, "getServers", nullptr, nullptr, [](GObject* source_object, GAsyncResult* res, gpointer user_data) {
            MyApplication* self = MY_APPLICATION(user_data);
            g_autoptr(GError) error = nullptr;
            g_autoptr(FlMethodResponse) response = fl_method_channel_invoke_method_finish(FL_METHOD_CHANNEL(source_object), res, &error);
            if (response) {
                FlValue* result = fl_method_response_get_result(response, nullptr);
                if (result && fl_value_get_type(result) == FL_VALUE_TYPE_LIST) {
                    std::string title = get_i18n_string(self, "nav_servers", "--- Servers ---");
                    GtkTreeIter iter;
                    gtk_list_store_append(self->store, &iter);
                    gtk_list_store_set(self->store, &iter, 0, title.c_str(), -1);
                    size_t length = fl_value_get_length(result);
                    for (size_t i = 0; i < length; ++i) {
                        FlValue* item = fl_value_get_list_value(result, i);
                        if (fl_value_get_type(item) == FL_VALUE_TYPE_MAP) {
                            FlValue* name_val = fl_value_lookup_string(item, "name");
                            if (name_val && fl_value_get_type(name_val) == FL_VALUE_TYPE_STRING) {
                                gtk_list_store_append(self->store, &iter);
                                gtk_list_store_set(self->store, &iter, 0, fl_value_get_string(name_val), -1);
                            }
                        }
                    }
                }
            }
            fetch_data(self, 2);
        }, self);
    } else if (step == 2) {
        g_autoptr(FlValue) args = fl_value_new_map();
        fl_value_set_string_take(args, "path", fl_value_new_string("/"));
        fl_method_channel_invoke_method(self->method_channel, "getFiles", args, nullptr, [](GObject* source_object, GAsyncResult* res, gpointer user_data) {
            MyApplication* self = MY_APPLICATION(user_data);
            g_autoptr(GError) error = nullptr;
            g_autoptr(FlMethodResponse) response = fl_method_channel_invoke_method_finish(FL_METHOD_CHANNEL(source_object), res, &error);
            if (response) {
                FlValue* result = fl_method_response_get_result(response, nullptr);
                if (result && fl_value_get_type(result) == FL_VALUE_TYPE_LIST) {
                    std::string title = get_i18n_string(self, "nav_files", "--- Files ---");
                    GtkTreeIter iter;
                    gtk_list_store_append(self->store, &iter);
                    gtk_list_store_set(self->store, &iter, 0, title.c_str(), -1);
                    size_t length = fl_value_get_length(result);
                    for (size_t i = 0; i < length; ++i) {
                        FlValue* item = fl_value_get_list_value(result, i);
                        if (fl_value_get_type(item) == FL_VALUE_TYPE_MAP) {
                            FlValue* name_val = fl_value_lookup_string(item, "name");
                            if (name_val && fl_value_get_type(name_val) == FL_VALUE_TYPE_STRING) {
                                gtk_list_store_append(self->store, &iter);
                                gtk_list_store_set(self->store, &iter, 0, fl_value_get_string(name_val), -1);
                            }
                        }
                    }
                }
            }
            fetch_data(self, 3);
        }, self);
    } else if (step == 3) {
        fl_method_channel_invoke_method(self->method_channel, "getApps", nullptr, nullptr, [](GObject* source_object, GAsyncResult* res, gpointer user_data) {
            MyApplication* self = MY_APPLICATION(user_data);
            g_autoptr(GError) error = nullptr;
            g_autoptr(FlMethodResponse) response = fl_method_channel_invoke_method_finish(FL_METHOD_CHANNEL(source_object), res, &error);
            if (response) {
                FlValue* result = fl_method_response_get_result(response, nullptr);
                if (result && fl_value_get_type(result) == FL_VALUE_TYPE_LIST) {
                    std::string title = get_i18n_string(self, "nav_apps", "--- Apps ---");
                    GtkTreeIter iter;
                    gtk_list_store_append(self->store, &iter);
                    gtk_list_store_set(self->store, &iter, 0, title.c_str(), -1);
                    size_t length = fl_value_get_length(result);
                    for (size_t i = 0; i < length; ++i) {
                        FlValue* item = fl_value_get_list_value(result, i);
                        if (fl_value_get_type(item) == FL_VALUE_TYPE_MAP) {
                            FlValue* name_val = fl_value_lookup_string(item, "name");
                            if (name_val && fl_value_get_type(name_val) == FL_VALUE_TYPE_STRING) {
                                gtk_list_store_append(self->store, &iter);
                                gtk_list_store_set(self->store, &iter, 0, fl_value_get_string(name_val), -1);
                            }
                        }
                    }
                }
            }
            fetch_data(self, 4);
        }, self);
    } else if (step == 4) {
        fl_method_channel_invoke_method(self->method_channel, "getWebsites", nullptr, nullptr, [](GObject* source_object, GAsyncResult* res, gpointer user_data) {
            MyApplication* self = MY_APPLICATION(user_data);
            g_autoptr(GError) error = nullptr;
            g_autoptr(FlMethodResponse) response = fl_method_channel_invoke_method_finish(FL_METHOD_CHANNEL(source_object), res, &error);
            if (response) {
                FlValue* result = fl_method_response_get_result(response, nullptr);
                if (result && fl_value_get_type(result) == FL_VALUE_TYPE_LIST) {
                    std::string title = get_i18n_string(self, "nav_websites", "--- Websites ---");
                    GtkTreeIter iter;
                    gtk_list_store_append(self->store, &iter);
                    gtk_list_store_set(self->store, &iter, 0, title.c_str(), -1);
                    size_t length = fl_value_get_length(result);
                    for (size_t i = 0; i < length; ++i) {
                        FlValue* item = fl_value_get_list_value(result, i);
                        if (fl_value_get_type(item) == FL_VALUE_TYPE_MAP) {
                            FlValue* name_val = fl_value_lookup_string(item, "primaryDomain");
                            if (name_val && fl_value_get_type(name_val) == FL_VALUE_TYPE_STRING) {
                                gtk_list_store_append(self->store, &iter);
                                gtk_list_store_set(self->store, &iter, 0, fl_value_get_string(name_val), -1);
                            }
                        }
                    }
                }
            }
            fetch_data(self, 5);
        }, self);
    } else if (step == 5) {
        fl_method_channel_invoke_method(self->method_channel, "getMonitoring", nullptr, nullptr, [](GObject* source_object, GAsyncResult* res, gpointer user_data) {
            MyApplication* self = MY_APPLICATION(user_data);
            g_autoptr(GError) error = nullptr;
            g_autoptr(FlMethodResponse) response = fl_method_channel_invoke_method_finish(FL_METHOD_CHANNEL(source_object), res, &error);
            if (response) {
                FlValue* result = fl_method_response_get_result(response, nullptr);
                if (result && fl_value_get_type(result) == FL_VALUE_TYPE_MAP) {
                    std::string title = get_i18n_string(self, "nav_monitoring", "--- Monitoring ---");
                    GtkTreeIter iter;
                    gtk_list_store_append(self->store, &iter);
                    gtk_list_store_set(self->store, &iter, 0, title.c_str(), -1);
                    
                    FlValue* cpu_val = fl_value_lookup_string(result, "cpu");
                    if (cpu_val && fl_value_get_type(cpu_val) == FL_VALUE_TYPE_FLOAT) {
                        gchar* cpu_str = g_strdup_printf("CPU: %.2f%%", fl_value_get_float(cpu_val));
                        gtk_list_store_append(self->store, &iter);
                        gtk_list_store_set(self->store, &iter, 0, cpu_str, -1);
                        g_free(cpu_str);
                    }
                    
                    FlValue* mem_val = fl_value_lookup_string(result, "memory");
                    if (mem_val && fl_value_get_type(mem_val) == FL_VALUE_TYPE_FLOAT) {
                        gchar* mem_str = g_strdup_printf("Memory: %.2f%%", fl_value_get_float(mem_val));
                        gtk_list_store_append(self->store, &iter);
                        gtk_list_store_set(self->store, &iter, 0, mem_str, -1);
                        g_free(mem_str);
                    }
                }
            }
            fetch_data(self, 6);
        }, self);
    } else if (step == 6) {
        fl_method_channel_invoke_method(self->method_channel, "getContainers", nullptr, nullptr, [](GObject* source_object, GAsyncResult* res, gpointer user_data) {
            MyApplication* self = MY_APPLICATION(user_data);
            g_autoptr(GError) error = nullptr;
            g_autoptr(FlMethodResponse) response = fl_method_channel_invoke_method_finish(FL_METHOD_CHANNEL(source_object), res, &error);
            if (response) {
                FlValue* result = fl_method_response_get_result(response, nullptr);
                if (result && fl_value_get_type(result) == FL_VALUE_TYPE_LIST) {
                    std::string title = get_i18n_string(self, "nav_containers", "--- Containers ---");
                    GtkTreeIter iter;
                    gtk_list_store_append(self->store, &iter);
                    gtk_list_store_set(self->store, &iter, 0, title.c_str(), -1);
                    size_t length = fl_value_get_length(result);
                    for (size_t i = 0; i < length; ++i) {
                        FlValue* item = fl_value_get_list_value(result, i);
                        if (fl_value_get_type(item) == FL_VALUE_TYPE_MAP) {
                            FlValue* name_val = fl_value_lookup_string(item, "name");
                            if (name_val && fl_value_get_type(name_val) == FL_VALUE_TYPE_STRING) {
                                gtk_list_store_append(self->store, &iter);
                                gtk_list_store_set(self->store, &iter, 0, fl_value_get_string(name_val), -1);
                            }
                        }
                    }
                }
            }
            fetch_data(self, 7);
        }, self);
    } else if (step == 7) {
        fl_method_channel_invoke_method(self->method_channel, "getSettings", nullptr, nullptr, [](GObject* source_object, GAsyncResult* res, gpointer user_data) {
            MyApplication* self = MY_APPLICATION(user_data);
            g_autoptr(GError) error = nullptr;
            g_autoptr(FlMethodResponse) response = fl_method_channel_invoke_method_finish(FL_METHOD_CHANNEL(source_object), res, &error);
            if (response) {
                FlValue* result = fl_method_response_get_result(response, nullptr);
                if (result && fl_value_get_type(result) == FL_VALUE_TYPE_MAP) {
                    std::string title = get_i18n_string(self, "nav_settings", "--- Settings ---");
                    GtkTreeIter iter;
                    gtk_list_store_append(self->store, &iter);
                    gtk_list_store_set(self->store, &iter, 0, title.c_str(), -1);
                    
                    FlValue* ver_val = fl_value_lookup_string(result, "version");
                    if (ver_val && fl_value_get_type(ver_val) == FL_VALUE_TYPE_STRING) {
                        gchar* ver_str = g_strdup_printf("Version: %s", fl_value_get_string(ver_val));
                        gtk_list_store_append(self->store, &iter);
                        gtk_list_store_set(self->store, &iter, 0, ver_str, -1);
                        g_free(ver_str);
                    }
                }
            }
        }, self);
    }
}

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "1Panel Client");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "1Panel Client");
  }

  gtk_window_set_default_size(window, 1280, 720);
  gtk_widget_show(GTK_WIDGET(window));

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_entrypoint_arguments);

  GtkWidget* box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
  gtk_widget_show(box);
  gtk_container_add(GTK_CONTAINER(window), box);

  GtkWidget* scrolled_window = gtk_scrolled_window_new(nullptr, nullptr);
  gtk_widget_set_size_request(scrolled_window, 220, -1);
  gtk_widget_show(scrolled_window);
  gtk_box_pack_start(GTK_BOX(box), scrolled_window, FALSE, FALSE, 0);

  GtkTreeIter init_iter;
  gtk_list_store_append(self->store, &init_iter);
  gtk_list_store_set(self->store, &init_iter, 0, "Loading...", -1);

  GtkWidget* tree_view = gtk_tree_view_new_with_model(GTK_TREE_MODEL(self->store));
  gtk_tree_view_set_headers_visible(GTK_TREE_VIEW(tree_view), FALSE);
  // Optional styling for TreeView
  gtk_widget_set_margin_start(tree_view, 8);
  gtk_widget_set_margin_end(tree_view, 8);
  gtk_widget_set_margin_top(tree_view, 8);
  gtk_widget_set_margin_bottom(tree_view, 8);
  
  GtkCellRenderer* renderer = gtk_cell_renderer_text_new();
  g_object_set(renderer, "ypad", 8, "xpad", 8, nullptr);
  GtkTreeViewColumn* column = gtk_tree_view_column_new_with_attributes("Items", renderer, "text", 0, nullptr);
  gtk_tree_view_append_column(GTK_TREE_VIEW(tree_view), column);
  gtk_widget_show(tree_view);
  gtk_container_add(GTK_CONTAINER(scrolled_window), tree_view);

  FlView* view = fl_view_new(project);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_box_pack_start(GTK_BOX(box), GTK_WIDGET(view), TRUE, TRUE, 0);

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  // SubTask 4.1: Native channel for communication with Flutter Engine
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->method_channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)),
      "com.onepanel.client/method",
      FL_METHOD_CODEC(codec));
      
  // Check UIRenderMode
  fl_method_channel_invoke_method(
      self->method_channel,
      "getUIRenderMode",
      nullptr,
      nullptr,
      [](GObject* source_object, GAsyncResult* res, gpointer user_data) {
          GtkWidget* scrolled_window = GTK_WIDGET(user_data);
          g_autoptr(GError) error = nullptr;
          g_autoptr(FlMethodResponse) response = fl_method_channel_invoke_method_finish(FL_METHOD_CHANNEL(source_object), res, &error);
          if (!response) return;
          FlValue* result = fl_method_response_get_result(response, nullptr);
          if (result && fl_value_get_type(result) == FL_VALUE_TYPE_STRING) {
              const gchar* mode = fl_value_get_string(result);
              if (g_strcmp0(mode, "md3") == 0) {
                  gtk_widget_hide(scrolled_window);
                  gtk_widget_destroy(scrolled_window);
              }
          }
      },
      scrolled_window);

  // SubTask 5.1 & 5.2: Invoke Dart side to get data sequentially
  fetch_data(self, 0);

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application, gchar*** arguments, int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
     g_warning("Failed to register: %s", error->message);
     *exit_status = 1;
     return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  //MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  //MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  g_clear_object(&self->method_channel);
  if (self->translations) {
      delete self->translations;
      self->translations = nullptr;
  }
  if (self->store) {
      g_object_unref(self->store);
      self->store = nullptr;
  }
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line = my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {
    self->translations = new std::map<std::string, std::string>();
    self->store = gtk_list_store_new(1, G_TYPE_STRING);
}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID,
                                     "flags", G_APPLICATION_NON_UNIQUE,
                                     nullptr));
}
