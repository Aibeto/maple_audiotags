//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <audiotags/audiotags_plugin_c_api.h>
#include <dynamic_color/dynamic_color_plugin_c_api.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  AudiotagsPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("AudiotagsPluginCApi"));
  DynamicColorPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("DynamicColorPluginCApi"));
}
