#include "napi/native_api.h"
#include "hilog/log.h"

#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_TAG "V2RayBridge"
#define LOG_DOMAIN 0xFADE

#define LOGI(...) OH_LOG_Print(LOG_APP, LOG_INFO, LOG_DOMAIN, LOG_TAG, __VA_ARGS__)
#define LOGE(...) OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_DOMAIN, LOG_TAG, __VA_ARGS__)

// ----- Go-exported functions (from libv2ray_core.a) -----
extern "C" {
    char* GetV2RayVersion();
    int   IsV2RayRunning();
    void  StartV2RayEngine(const char* config, int tunFd);
    void  StopV2RayEngine();
    long  MeasureDelay(const char* url);
    char* QueryTrafficStats();
    void  FreeCString(char* str);

    // Weak callbacks defined in Go preamble; we provide strong overrides
    void onV2RayStartup();
    void onV2RayShutdown();
    void onV2RayEmitStatus(long code, const char* message);
}

// ----- Strong callback overrides (override Go weak stubs) -----
void onV2RayStartup() {
    LOGI("Go callback: onV2RayStartup");
}

void onV2RayShutdown() {
    LOGI("Go callback: onV2RayShutdown");
}

void onV2RayEmitStatus(long code, const char* message) {
    LOGI("Go callback: onV2RayEmitStatus(code=%ld, msg=%s)", code, message ? message : "null");
}

// ----- NAPI wrappers -----

static napi_value NAPI_GetVersion(napi_env env, napi_callback_info info) {
    LOGI("NAPI_GetVersion called");
    char* ver = GetV2RayVersion();
    napi_value result;
    napi_create_string_utf8(env, ver ? ver : "unknown", -1, &result);
    if (ver) FreeCString(ver);
    return result;
}

static napi_value NAPI_IsRunning(napi_env env, napi_callback_info info) {
    int running = IsV2RayRunning();
    napi_value result;
    napi_get_boolean(env, running != 0, &result);
    return result;
}

static napi_value NAPI_StartCore(napi_env env, napi_callback_info info) {
    LOGI("NAPI_StartCore called");

    size_t argc = 2;
    napi_value argv[2];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);

    char configBuf[65536];
    size_t strLen = 0;
    napi_get_value_string_utf8(env, argv[0], configBuf, sizeof(configBuf), &strLen);

    int tunFd = 0;
    if (argc > 1) napi_get_value_int32(env, argv[1], &tunFd);

    LOGI("Starting V2Ray with config (%zu bytes), tunFd=%d", strLen, tunFd);
    StartV2RayEngine(configBuf, tunFd);

    napi_value result;
    napi_get_boolean(env, true, &result);
    return result;
}

static napi_value NAPI_StopCore(napi_env env, napi_callback_info info) {
    LOGI("NAPI_StopCore called");
    StopV2RayEngine();
    napi_value result;
    napi_get_undefined(env, &result);
    return result;
}

static napi_value NAPI_MeasureDelay(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    char urlBuf[4096];
    size_t strLen = 0;
    napi_get_value_string_utf8(env, argv[0], urlBuf, sizeof(urlBuf), &strLen);
    long ms = MeasureDelay(urlBuf);
    napi_value result;
    napi_create_int64(env, ms, &result);
    return result;
}

static napi_value NAPI_QueryTraffic(napi_env env, napi_callback_info info) {
    char* stats = QueryTrafficStats();
    napi_value result;
    napi_create_string_utf8(env, stats ? stats : "{}", -1, &result);
    if (stats) FreeCString(stats);
    return result;
}

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    LOGI("NAPI Init called for v2ray_bridge — Go core is statically linked");

    char* ver = GetV2RayVersion();
    LOGI("Go core version: %{public}s", ver ? ver : "null");
    if (ver) FreeCString(ver);

    napi_property_descriptor desc[] = {
        {"getVersion",   nullptr, NAPI_GetVersion,   nullptr, nullptr, nullptr, napi_default, nullptr},
        {"isRunning",    nullptr, NAPI_IsRunning,    nullptr, nullptr, nullptr, napi_default, nullptr},
        {"startCore",    nullptr, NAPI_StartCore,    nullptr, nullptr, nullptr, napi_default, nullptr},
        {"stopCore",     nullptr, NAPI_StopCore,     nullptr, nullptr, nullptr, napi_default, nullptr},
        {"measureDelay", nullptr, NAPI_MeasureDelay, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"queryTraffic", nullptr, NAPI_QueryTraffic, nullptr, nullptr, nullptr, napi_default, nullptr},
    };

    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    LOGI("NAPI Init complete — 6 exports registered");
    return exports;
}
EXTERN_C_END

static napi_module v2rayBridgeModule = {
    .nm_version     = 1,
    .nm_flags       = 0,
    .nm_filename    = nullptr,
    .nm_register_func = Init,
    .nm_modname     = "v2ray_bridge",
    .nm_priv        = nullptr,
    .reserved       = {0},
};

extern "C" __attribute__((constructor)) void RegisterV2rayBridgeModule(void) {
    napi_module_register(&v2rayBridgeModule);
}
