/*
 * hypr_gtkblur.c — Wayland preload helper to enable Hyprland background blur for GTK4 apps.
 *
 * Hyprland skips background blur when:
 * 1. ext_background_effect_manager_v1 is bound but no blur region is set (GTK 4.24 issue).
 * 2. wl_surface.set_opaque_region covers the window.
 *
 * This shim:
 * - Hides ext_background_effect_manager_v1 from the wl_registry globals.
 * - Clears wl_surface.set_opaque_region requests.
 */

#define _GNU_SOURCE
#include <dlfcn.h>
#include <string.h>
#include <stdint.h>
#include <wayland-client.h>

static int (*orig_wl_proxy_add_listener)(struct wl_proxy *proxy, void (**implementation)(void), void *data) = NULL;
static void (*orig_global)(void *data, struct wl_registry *registry, uint32_t id, const char *interface, uint32_t version) = NULL;
static struct wl_registry_listener my_listener;

static void my_global(void *data, struct wl_registry *registry, uint32_t id, const char *interface, uint32_t version) {
    if (interface && strcmp(interface, "ext_background_effect_manager_v1") == 0) {
        // Drop this global so GTK4 never binds it
        return;
    }
    if (orig_global) {
        orig_global(data, registry, id, interface, version);
    }
}

int wl_proxy_add_listener(struct wl_proxy *proxy, void (**implementation)(void), void *data) {
    if (!orig_wl_proxy_add_listener) {
        orig_wl_proxy_add_listener = dlsym(RTLD_NEXT, "wl_proxy_add_listener");
    }
    const char *iface = wl_proxy_get_class(proxy);
    if (iface && strcmp(iface, "wl_registry") == 0 && implementation) {
        struct wl_registry_listener *reg_listener = (struct wl_registry_listener *)implementation;
        if (reg_listener->global) {
            orig_global = reg_listener->global;
            my_listener.global = my_global;
            my_listener.global_remove = reg_listener->global_remove;
            return orig_wl_proxy_add_listener(proxy, (void (**)(void))&my_listener, data);
        }
    }
    return orig_wl_proxy_add_listener(proxy, implementation, data);
}

struct wl_proxy *
wl_proxy_marshal_array_flags(struct wl_proxy *proxy, uint32_t opcode,
                             const struct wl_interface *interface,
                             uint32_t version,
                             uint32_t flags,
                             union wl_argument *args) {
    static struct wl_proxy * (*orig_marshal_array_flags)(struct wl_proxy *, uint32_t, const struct wl_interface *, uint32_t, uint32_t, union wl_argument *) = NULL;
    if (!orig_marshal_array_flags) {
        orig_marshal_array_flags = dlsym(RTLD_NEXT, "wl_proxy_marshal_array_flags");
    }

    const char *iface = wl_proxy_get_class(proxy);
    // wl_surface opcode 4 is set_opaque_region
    if (iface && strcmp(iface, "wl_surface") == 0 && opcode == 4) {
        if (args) {
            args[0].o = NULL;
        }
    }

    return orig_marshal_array_flags(proxy, opcode, interface, version, flags, args);
}
