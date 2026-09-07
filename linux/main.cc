#include <glib.h>

#include "my_application.h"

static void set_quickjsc_c_bridge_plugin_path() {
  g_autofree gchar *executable_path =
      g_file_read_link("/proc/self/exe", nullptr);
  if (executable_path == nullptr) {
    return;
  }

  g_autofree gchar *executable_dir = g_path_get_dirname(executable_path);
  g_autofree gchar *lib_path = g_build_filename(
      executable_dir, "lib", "libquickjs_c_bridge_plugin.so", nullptr);
  g_setenv("LIBQUICKJSC_PATH", lib_path, FALSE);
}

int main(int argc, char **argv) {
  set_quickjsc_c_bridge_plugin_path();

  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
