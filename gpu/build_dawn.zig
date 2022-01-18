const std = @import("std");
const Builder = std.build.Builder;
const glfw = @import("libs/mach-glfw/build.zig");
const system_sdk = @import("libs/mach-glfw/system_sdk.zig");

pub const LinuxWindowManager = enum {
    X11,
    Wayland,
};

pub const Options = struct {
    /// Defaults to X11 on Linux.
    linux_window_manager: ?LinuxWindowManager = null,

    /// Defaults to true on Windows
    d3d12: ?bool = null,

    /// Defaults to true on Darwin
    metal: ?bool = null,

    /// Defaults to true on Linux, Fuchsia
    // TODO(build-system): enable on Windows if we can cross compile Vulkan
    vulkan: ?bool = null,

    /// Defaults to true on Windows, Linux
    // TODO(build-system): not respected on Windows currently
    desktop_gl: ?bool = null,

    /// Defaults to true on Android, Linux, Windows, Emscripten
    // TODO(build-system): not respected at all currently
    opengl_es: ?bool = null,

    /// Whether or not minimal debug symbols should be emitted. This is -g1 in most cases, enough to
    /// produce stack traces but omitting debug symbols for locals. For spirv-tools and tint in
    /// specific, -g0 will be used (no debug symbols at all) to save an additional ~39M.
    ///
    /// When enabled, a debug build of the static library goes from ~947M to just ~53M.
    minimal_debug_symbols: bool = true,

    /// Detects the default options to use for the given target.
    pub fn detectDefaults(self: Options, target: std.Target) Options {
        const tag = target.os.tag;
        const linux_desktop_like = isLinuxDesktopLike(target);

        var options = self;
        if (options.linux_window_manager == null and linux_desktop_like) options.linux_window_manager = .X11;
        if (options.d3d12 == null) options.d3d12 = tag == .windows;
        if (options.metal == null) options.metal = tag.isDarwin();
        if (options.vulkan == null) options.vulkan = tag == .fuchsia or linux_desktop_like;

        // TODO(build-system): respect these options / defaults
        if (options.desktop_gl == null) options.desktop_gl = linux_desktop_like; // TODO(build-system): add windows
        options.opengl_es = false;
        // if (options.opengl_es == null) options.opengl_es = tag == .windows or tag == .emscripten or target.isAndroid() or linux_desktop_like;
        return options;
    }

    pub fn appendFlags(self: Options, flags: *std.ArrayList([]const u8), zero_debug_symbols: bool) !void {
        if (self.minimal_debug_symbols) {
            if (zero_debug_symbols) try flags.append("-g0") else try flags.append("-g1");
        }
    }
};

pub fn linkyLinky(step: *std.build.LibExeObjStep) void {
    //dawn_complete_static_libs=true

    step.addLibPath(thisDir() ++ "/libs/dawn/out/Debug/");
    //step.addLibPath("C:/Program Files (x86)/Microsoft Visual Studio/2019/Community/VC/Tools/MSVC/14.29.30133/lib/x64/");

    step.addLibPath(thisDir() ++ "/libs/dawn/out/Debug/obj/src/utils/");
    step.addLibPath(thisDir() ++ "/libs/dawn/out/Debug/obj/src/common/");

    step.linkSystemLibrary("oleaut32");
    step.linkSystemLibrary("ole32");
    step.linkSystemLibrary("msvcrtd");
    step.linkSystemLibrary("msvcrt");

    step.linkSystemLibrary("dawn_native.dll");
    step.linkSystemLibrary("dawn_platform.dll");
    step.linkSystemLibrary("dawn_proc.dll");
    step.linkSystemLibrary("dawn_wire.dll");

    step.linkSystemLibrary("dawn_bindings");
    step.linkSystemLibrary("dawn_utils");
    step.linkSystemLibrary("common");

    //step.linkSystemLibrary("VkICD_mock_icd.dll");
    //step.linkSystemLibrary("VkLayer_khronos_validation.dll");
    //step.linkSystemLibrary("libEGL.dll");
    //step.linkSystemLibrary("libGLESv2.dll");
    step.linkSystemLibrary("libc++.dll");
    //step.linkSystemLibrary("vk_swiftshader.dll");
    //step.linkSystemLibrary("vulkan-1.dll");
    //step.linkSystemLibrary("zlib.dll");
}

pub fn link(b: *Builder, step: *std.build.LibExeObjStep, options: Options) void {
    const target = (std.zig.system.NativeTargetInfo.detect(b.allocator, step.target) catch unreachable).target;
    const opt = options.detectDefaults(target);

    const lib_mach_dawn_native = buildLibMachDawnNative(b, step, opt);
    step.linkLibrary(lib_mach_dawn_native);
    step.linkSystemLibrary("oleaut32");
    step.linkSystemLibrary("ole32");

    //if (target.os.tag == .windows) {
    //    linkyLinky(step);
    //    return;
    //}
    //step.addLibPath("C:/Program Files (x86)/Microsoft Visual Studio/2019/Community/VC/Tools/MSVC/14.29.30133/lib/x64/");
    //step.linkSystemLibrary("oldnames");
    //step.addLibPath("C:/Program Files (x86)/Windows Kits/10/Lib/10.0.19041.0/um/x64/");
    step.linkSystemLibrary("D3d12");
    step.linkSystemLibrary("D3D12");
    //step.linkSystemLibrary("vcruntime140d");

    //step.addLibPath("C:/Program Files (x86)/Microsoft SDKs/Windows Kits/10/ExtensionSDKs/Microsoft.UniversalCRT.Debug/10.0.19041.0/Redist/Debug/x64/");
    //step.linkSystemLibrary("ucrtbased");
 
    //step.addLibPath("C:/Program Files/mingw-w64/x86_64-8.1.0-posix-seh-rt_v6-rev0/mingw64/x86_64-w64-mingw32/lib/");
    //step.linkSystemLibrary("dxguid");
    step.linkSystemLibrary("dxguid");
    step.linkSystemLibrary("dbghelp");
    step.addLibPath("C:\\Program Files\\mingw-w64\\x86_64-8.1.0-posix-seh-rt_v6-rev0\\mingw64\\x86_64-w64-mingw32\\lib");
    step.linkLibCpp();

        // step.linkSystemLibrary("dxcompiler");
        // step.addLibPath("C:\\tmp2\\lib");

    const lib_dawn_common = buildLibDawnCommon(b, step, opt);
    step.linkLibrary(lib_dawn_common);

    const lib_dawn_platform = buildLibDawnPlatform(b, step, opt);
    step.linkLibrary(lib_dawn_platform);

    // dawn-native
    const lib_abseil_cpp = buildLibAbseilCpp(b, step, opt);
    step.linkLibrary(lib_abseil_cpp);
    const lib_dxcompiler = buildLibDxcompiler(b, step, opt);
    step.linkLibrary(lib_dxcompiler);
    const lib_dawn_native = buildLibDawnNative(b, step, opt);
    lib_dawn_native.linkLibrary(lib_dxcompiler);
    step.linkLibrary(lib_dawn_native);

    const lib_dawn_wire = buildLibDawnWire(b, step, opt);
    step.linkLibrary(lib_dawn_wire);

    const lib_dawn_utils = buildLibDawnUtils(b, step, opt);
    step.linkLibrary(lib_dawn_utils);

    const lib_spirv_tools = buildLibSPIRVTools(b, step, opt);
    step.linkLibrary(lib_spirv_tools);

    const lib_tint = buildLibTint(b, step, opt);
    step.linkLibrary(lib_tint);
}

fn isLinuxDesktopLike(target: std.Target) bool {
    const tag = target.os.tag;
    return !tag.isDarwin() and tag != .windows and tag != .fuchsia and tag != .emscripten and !target.isAndroid();
}

fn buildLibMachDawnNative(b: *Builder, step: *std.build.LibExeObjStep, options: Options) *std.build.LibExeObjStep {
    var main_abs = std.fs.path.join(b.allocator, &.{ thisDir(), "src/dawn/dummy.zig" }) catch unreachable;
    const lib = b.addStaticLibrary("dawn-native-mach", main_abs);
    lib.install();
    lib.setBuildMode(step.build_mode);
    lib.setTarget(step.target);
    //linkyLinky(lib);
    lib.linkLibCpp();

    // TODO(build-system): pass system SDK options through
    glfw.link(b, lib, .{ .system_sdk = .{ .set_sysroot = false } });

    var flags = std.ArrayList([]const u8).init(b.allocator);
    options.appendFlags(&flags, false) catch unreachable;
    appendDawnEnableBackendTypeFlags(&flags, options) catch unreachable;
    flags.appendSlice(&.{
        include("libs/mach-glfw/upstream/glfw/include"),
        include("libs/dawn/out/Debug/gen/src/include"),
        include("libs/dawn/out/Debug/gen/src"),
        include("libs/dawn/src/include"),
        include("libs/dawn/src"),
        "-D_DEBUG",
        "-D_MT",
        "-D_DLL",
    }) catch unreachable;

    lib.addCSourceFile("src/dawn/dawn_native_mach.cpp", flags.items);
    return lib;
}

// Builds common sources; derived from src/common/BUILD.gn
fn buildLibDawnCommon(b: *Builder, step: *std.build.LibExeObjStep, options: Options) *std.build.LibExeObjStep {
    var main_abs = std.fs.path.join(b.allocator, &.{ thisDir(), "src/dawn/dummy.zig" }) catch unreachable;
    const lib = b.addStaticLibrary("dawn-common", main_abs);
    lib.setBuildMode(step.build_mode);
    lib.setTarget(step.target);
    lib.linkLibCpp();

    var flags = std.ArrayList([]const u8).init(b.allocator);
    options.appendFlags(&flags, false) catch unreachable;
    flags.append(include("libs/dawn/src")) catch unreachable;

    var sources = std.ArrayList([]const u8).init(b.allocator);
    for ([_][]const u8{
        "src/common/Assert.cpp",
        "src/common/DynamicLib.cpp",
        "src/common/GPUInfo.cpp",
        "src/common/Log.cpp",
        "src/common/Math.cpp",
        "src/common/RefCounted.cpp",
        "src/common/Result.cpp",
        "src/common/SlabAllocator.cpp",
        "src/common/SystemUtils.cpp",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        sources.append(abs_path) catch unreachable;
    }

    const target = (std.zig.system.NativeTargetInfo.detect(b.allocator, step.target) catch unreachable).target;
    if (target.os.tag == .macos) {
        // TODO(build-system): pass system SDK options through
        system_sdk.include(b, lib, .{});
        lib.linkFramework("Foundation");
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn/src/common/SystemUtils_mac.mm" }) catch unreachable;
        sources.append(abs_path) catch unreachable;
    }

    if (target.os.tag == .windows) {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn/src/common/WindowsUtils.cpp" }) catch unreachable;
        sources.append(abs_path) catch unreachable;
    }
    lib.addCSourceFiles(sources.items, flags.items);
    return lib;
}

// Build dawn platform sources; derived from src/dawn_platform/BUILD.gn
fn buildLibDawnPlatform(b: *Builder, step: *std.build.LibExeObjStep, options: Options) *std.build.LibExeObjStep {
    var main_abs = std.fs.path.join(b.allocator, &.{ thisDir(), "src/dawn/dummy.zig" }) catch unreachable;
    const lib = b.addStaticLibrary("dawn-platform", main_abs);
    lib.install();
    lib.setBuildMode(step.build_mode);
    lib.setTarget(step.target);
    lib.linkLibCpp();

    var flags = std.ArrayList([]const u8).init(b.allocator);
    options.appendFlags(&flags, false) catch unreachable;
    flags.appendSlice(&.{
        include("libs/dawn/src"),
        include("libs/dawn/src/include"),

        include("libs/dawn/out/Debug/gen/src/include"),
    }) catch unreachable;

    var sources = std.ArrayList([]const u8).init(b.allocator);
    for ([_][]const u8{
        "src/dawn_platform/DawnPlatform.cpp",
        "src/dawn_platform/WorkerThread.cpp",
        "src/dawn_platform/tracing/EventTracer.cpp",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        sources.append(abs_path) catch unreachable;
    }
    lib.addCSourceFiles(sources.items, flags.items);
    return lib;
}

fn appendDawnEnableBackendTypeFlags(flags: *std.ArrayList([]const u8), options: Options) !void {
    const d3d12 = "-DDAWN_ENABLE_BACKEND_D3D12";
    const metal = "-DDAWN_ENABLE_BACKEND_METAL";
    const vulkan = "-DDAWN_ENABLE_BACKEND_VULKAN";
    const opengl = "-DDAWN_ENABLE_BACKEND_OPENGL";
    const desktop_gl = "-DDAWN_ENABLE_BACKEND_DESKTOP_GL";
    const opengl_es = "-DDAWN_ENABLE_BACKEND_OPENGLES";
    const backend_null = "-DDAWN_ENABLE_BACKEND_NULL";

    try flags.append(backend_null);
    if (options.d3d12.?) try flags.append(d3d12);
    if (options.metal.?) try flags.append(metal);
    if (options.vulkan.?) try flags.append(vulkan);
    if (options.desktop_gl.?) try flags.appendSlice(&.{ opengl, desktop_gl });
    if (options.opengl_es.?) try flags.appendSlice(&.{ opengl, opengl_es });
}

// Builds dawn native sources; derived from src/dawn_native/BUILD.gn
fn buildLibDawnNative(b: *Builder, step: *std.build.LibExeObjStep, options: Options) *std.build.LibExeObjStep {
    var main_abs = std.fs.path.join(b.allocator, &.{ thisDir(), "src/dawn/dummy.zig" }) catch unreachable;
    const lib = b.addStaticLibrary("dawn-native", main_abs);
    lib.install();
    lib.setBuildMode(step.build_mode);
    lib.setTarget(step.target);
    lib.linkLibCpp();
    system_sdk.include(b, lib, .{});

    var flags = std.ArrayList([]const u8).init(b.allocator);
    options.appendFlags(&flags, false) catch unreachable;
    appendDawnEnableBackendTypeFlags(&flags, options) catch unreachable;
    if (options.desktop_gl.?) {
        // OpenGL requires spriv-cross until Dawn moves OpenGL shader generation to Tint.
        flags.append(include("libs/dawn/third_party/vulkan-deps/spirv-cross/src")) catch unreachable;

        const lib_spirv_cross = buildLibSPIRVCross(b, step, options);
        step.linkLibrary(lib_spirv_cross);
    }
    flags.appendSlice(&.{
        include("libs/dawn"),
        include("libs/dawn/src"),
        include("libs/dawn/src/include"),
        include("libs/dawn/third_party/vulkan-deps/spirv-tools/src/include"),
        include("libs/dawn/third_party/abseil-cpp"),
        include("libs/dawn/third_party/khronos"),

        // TODO(build-system): make these optional
        "-DTINT_BUILD_SPV_READER=1",
        "-DTINT_BUILD_SPV_WRITER=1",
        "-DTINT_BUILD_WGSL_READER=1",
        "-DTINT_BUILD_WGSL_WRITER=1",
        "-DTINT_BUILD_MSL_WRITER=1",
        "-DTINT_BUILD_HLSL_WRITER=1",
        include("libs/dawn/third_party/tint"),
        include("libs/dawn/third_party/tint/include"),

        include("libs/dawn/out/Debug/gen/src/include"),
        include("libs/dawn/out/Debug/gen/src"),
    }) catch unreachable;

    var sources = std.ArrayList([]const u8).init(b.allocator);
    sources.appendSlice(&.{
        thisDir() ++ "/src/dawn/sources/dawn_native.cpp",
        thisDir() ++ "/libs/dawn/out/Debug/gen/src/dawn/dawn_proc.c",
    }) catch unreachable;

    // dawn_native_utils_gen
    sources.append(thisDir() ++ "/src/dawn/sources/dawn_native_utils_gen.cpp") catch unreachable;

    // TODO(build-system): could allow enable_vulkan_validation_layers here. See src/dawn_native/BUILD.gn
    // TODO(build-system): allow use_angle here. See src/dawn_native/BUILD.gn
    // TODO(build-system): could allow use_swiftshader here. See src/dawn_native/BUILD.gn

    if (options.d3d12.?) {
        // TODO(build-system): windows
        //     libs += [ "dxguid.lib" ]
        lib.linkSystemLibrary("dxguid");
        lib.addLibPath("C:\\Program Files\\mingw-w64\\x86_64-8.1.0-posix-seh-rt_v6-rev0\\mingw64\\x86_64-w64-mingw32\\lib");

        //lib.linkSystemLibrary("dxcompiler");
        //lib.addLibPath("C:\\tmp2\\lib");
        flags.appendSlice(&.{
            "-IC:\\tmp2",
            //"-IC:\\Program Files (x86)\\Windows Kits\\10\\Include\\10.0.19041.0\\um",
            //"-IC:\\Program Files (x86)\\Windows Kits\\10\\Include\\10.0.19041.0\\shared",
            //"-IC:\\Program Files (x86)\\Windows Kits\\10\\Include\\10.0.19041.0\\winrt",
            "-D__EMULATE_UUID=1",
            "-Wno-nonportable-include-path",
            "-Wno-extern-c-compat",
            "-Wno-invalid-noreturn",
            "-Wno-pragma-pack",
            "-Wno-microsoft-template-shadow",
            "-Wno-unused-command-line-argument",
            "-Wno-microsoft-exception-spec",
            "-Wno-implicit-exception-spec-mismatch",
            "-Wno-unknown-attributes",
            "-Wno-c++20-extensions",
            "-D_CRT_SECURE_NO_WARNINGS",

            "-DWIN32_LEAN_AND_MEAN",
            "-DD3D10_ARBITRARY_HEADER_ORDERING",
            "-D_Maybenull_=",
            "-D__in=",
            "-D__out=",
            "-DNOMINMAX",
        }) catch unreachable;

        sources.append(thisDir() ++ "/src/dawn/sources/dawn_native_d3d12.cpp") catch unreachable;
    }
    if (options.metal.?) {
        lib.linkFramework("Metal");
        lib.linkFramework("CoreGraphics");
        lib.linkFramework("Foundation");
        lib.linkFramework("IOKit");
        lib.linkFramework("IOSurface");
        lib.linkFramework("QuartzCore");

        sources.appendSlice(&.{
            thisDir() ++ "/src/dawn/sources/dawn_native_metal.mm",
            thisDir() ++ "/libs/dawn/src/dawn_native/metal/BackendMTL.mm",
        }) catch unreachable;
    }

    if (options.linux_window_manager != null and options.linux_window_manager.? == .X11) {
        lib.linkSystemLibrary("X11");
        for ([_][]const u8{
            "src/dawn_native/XlibXcbFunctions.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            sources.append(abs_path) catch unreachable;
        }
    }

    for ([_][]const u8{
        "src/dawn_native/null/DeviceNull.cpp",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        sources.append(abs_path) catch unreachable;
    }

    if (options.desktop_gl.? or options.vulkan.?) {
        for ([_][]const u8{
            "src/dawn_native/SpirvValidation.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            sources.append(abs_path) catch unreachable;
        }
    }

    if (options.desktop_gl.?) {
        for ([_][]const u8{
            "out/Debug/gen/src/dawn_native/opengl/OpenGLFunctionsBase_autogen.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            sources.append(abs_path) catch unreachable;
        }

        // TODO(build-system): reduce build units
        for ([_][]const u8{
            "src/dawn_native/opengl/BackendGL.cpp",
            "src/dawn_native/opengl/BindGroupGL.cpp",
            "src/dawn_native/opengl/BindGroupLayoutGL.cpp",
            "src/dawn_native/opengl/BufferGL.cpp",
            "src/dawn_native/opengl/CommandBufferGL.cpp",
            "src/dawn_native/opengl/ComputePipelineGL.cpp",
            "src/dawn_native/opengl/DeviceGL.cpp",
            "src/dawn_native/opengl/GLFormat.cpp",
            "src/dawn_native/opengl/NativeSwapChainImplGL.cpp",
            "src/dawn_native/opengl/OpenGLFunctions.cpp",
            "src/dawn_native/opengl/OpenGLVersion.cpp",
            "src/dawn_native/opengl/PersistentPipelineStateGL.cpp",
            "src/dawn_native/opengl/PipelineGL.cpp",
            "src/dawn_native/opengl/PipelineLayoutGL.cpp",
            "src/dawn_native/opengl/QuerySetGL.cpp",
            "src/dawn_native/opengl/QueueGL.cpp",
            "src/dawn_native/opengl/RenderPipelineGL.cpp",
            "src/dawn_native/opengl/SamplerGL.cpp",
            "src/dawn_native/opengl/ShaderModuleGL.cpp",
            "src/dawn_native/opengl/SpirvUtils.cpp",
            "src/dawn_native/opengl/SwapChainGL.cpp",
            "src/dawn_native/opengl/TextureGL.cpp",
            "src/dawn_native/opengl/UtilsGL.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            sources.append(abs_path) catch unreachable;
        }
    }

    const target = (std.zig.system.NativeTargetInfo.detect(b.allocator, step.target) catch unreachable).target;
    if (options.vulkan.?) {
        // TODO(build-system): reduce build units
        for ([_][]const u8{
            "src/dawn_native/vulkan/AdapterVk.cpp",
            "src/dawn_native/vulkan/BackendVk.cpp",
            "src/dawn_native/vulkan/BindGroupLayoutVk.cpp",
            "src/dawn_native/vulkan/BindGroupVk.cpp",
            "src/dawn_native/vulkan/BufferVk.cpp",
            "src/dawn_native/vulkan/CommandBufferVk.cpp",
            "src/dawn_native/vulkan/ComputePipelineVk.cpp",
            "src/dawn_native/vulkan/DescriptorSetAllocator.cpp",
            "src/dawn_native/vulkan/DeviceVk.cpp",
            "src/dawn_native/vulkan/FencedDeleter.cpp",
            "src/dawn_native/vulkan/NativeSwapChainImplVk.cpp",
            "src/dawn_native/vulkan/PipelineLayoutVk.cpp",
            "src/dawn_native/vulkan/QuerySetVk.cpp",
            "src/dawn_native/vulkan/QueueVk.cpp",
            "src/dawn_native/vulkan/RenderPassCache.cpp",
            "src/dawn_native/vulkan/RenderPipelineVk.cpp",
            "src/dawn_native/vulkan/ResourceHeapVk.cpp",
            "src/dawn_native/vulkan/ResourceMemoryAllocatorVk.cpp",
            "src/dawn_native/vulkan/SamplerVk.cpp",
            "src/dawn_native/vulkan/ShaderModuleVk.cpp",
            "src/dawn_native/vulkan/StagingBufferVk.cpp",
            "src/dawn_native/vulkan/SwapChainVk.cpp",
            "src/dawn_native/vulkan/TextureVk.cpp",
            "src/dawn_native/vulkan/UtilsVulkan.cpp",
            "src/dawn_native/vulkan/VulkanError.cpp",
            "src/dawn_native/vulkan/VulkanExtensions.cpp",
            "src/dawn_native/vulkan/VulkanFunctions.cpp",
            "src/dawn_native/vulkan/VulkanInfo.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            sources.append(abs_path) catch unreachable;
        }

        if (isLinuxDesktopLike(target)) {
            for ([_][]const u8{
                "src/dawn_native/vulkan/external_memory/MemoryServiceOpaqueFD.cpp",
                "src/dawn_native/vulkan/external_semaphore/SemaphoreServiceFD.cpp",
            }) |path| {
                var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
                lib.addCSourceFile(abs_path, flags.items);
                sources.append(abs_path) catch unreachable;
            }
        } else if (target.os.tag == .fuchsia) {
            for ([_][]const u8{
                "src/dawn_native/vulkan/external_memory/MemoryServiceZirconHandle.cpp",
                "src/dawn_native/vulkan/external_semaphore/SemaphoreServiceZirconHandle.cpp",
            }) |path| {
                var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
                sources.append(abs_path) catch unreachable;
            }
        } else {
            for ([_][]const u8{
                "src/dawn_native/vulkan/external_memory/MemoryServiceNull.cpp",
                "src/dawn_native/vulkan/external_semaphore/SemaphoreServiceNull.cpp",
            }) |path| {
                var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
                sources.append(abs_path) catch unreachable;
            }
        }
    }

    // TODO(build-system): fuchsia: add is_fuchsia here from upstream source file

    if (options.vulkan.?) {
        // TODO(build-system): vulkan
        //     if (enable_vulkan_validation_layers) {
        //       defines += [
        //         "DAWN_ENABLE_VULKAN_VALIDATION_LAYERS",
        //         "DAWN_VK_DATA_DIR=\"$vulkan_data_subdir\"",
        //       ]
        //     }
        //     if (enable_vulkan_loader) {
        //       data_deps += [ "${dawn_vulkan_loader_dir}:libvulkan" ]
        //       defines += [ "DAWN_ENABLE_VULKAN_LOADER" ]
        //     }
    }
    // TODO(build-system): swiftshader
    //     if (use_swiftshader) {
    //       data_deps += [
    //         "${dawn_swiftshader_dir}/src/Vulkan:icd_file",
    //         "${dawn_swiftshader_dir}/src/Vulkan:swiftshader_libvulkan",
    //       ]
    //       defines += [
    //         "DAWN_ENABLE_SWIFTSHADER",
    //         "DAWN_SWIFTSHADER_VK_ICD_JSON=\"${swiftshader_icd_file_name}\"",
    //       ]
    //     }
    //   }

    if (options.opengl_es.?) {
        // TODO(build-system): gles
        //   if (use_angle) {
        //     data_deps += [
        //       "${dawn_angle_dir}:libEGL",
        //       "${dawn_angle_dir}:libGLESv2",
        //     ]
        //   }
        // }
    }

    for ([_][]const u8{
        "src/dawn_native/DawnNative.cpp",
        "src/dawn_native/null/NullBackend.cpp",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        sources.append(abs_path) catch unreachable;
    }

    if (options.d3d12.?) {
        for ([_][]const u8{
            "src/dawn_native/d3d12/D3D12Backend.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            sources.append(abs_path) catch unreachable;
        }
    }
    if (options.desktop_gl.?) {
        for ([_][]const u8{
            "src/dawn_native/opengl/OpenGLBackend.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            sources.append(abs_path) catch unreachable;
        }
    }
    if (options.vulkan.?) {
        for ([_][]const u8{
            "src/dawn_native/vulkan/VulkanBackend.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            sources.append(abs_path) catch unreachable;
        }
        // TODO(build-system): vulkan
        //     if (enable_vulkan_validation_layers) {
        //       data_deps =
        //           [ "${dawn_vulkan_validation_layers_dir}:vulkan_validation_layers" ]
        //       if (!is_android) {
        //         data_deps +=
        //             [ "${dawn_vulkan_validation_layers_dir}:vulkan_gen_json_files" ]
        //       }
        //     }
    }
    lib.addCSourceFiles(sources.items, flags.items);
    return lib;
}

// Builds third party tint sources; derived from third_party/tint/src/BUILD.gn
fn buildLibTint(b: *Builder, step: *std.build.LibExeObjStep, options: Options) *std.build.LibExeObjStep {
    var main_abs = std.fs.path.join(b.allocator, &.{ thisDir(), "src/dawn/dummy.zig" }) catch unreachable;
    const lib = b.addStaticLibrary("tint", main_abs);
    lib.install();
    lib.setBuildMode(step.build_mode);
    lib.setTarget(step.target);
    lib.linkLibCpp();

    var flags = std.ArrayList([]const u8).init(b.allocator);
    options.appendFlags(&flags, true) catch unreachable;
    flags.appendSlice(&.{
        // TODO(build-system): make these optional
        "-DTINT_BUILD_SPV_READER=1",
        "-DTINT_BUILD_SPV_WRITER=1",
        "-DTINT_BUILD_WGSL_READER=1",
        "-DTINT_BUILD_WGSL_WRITER=1",
        "-DTINT_BUILD_MSL_WRITER=1",
        "-DTINT_BUILD_HLSL_WRITER=1",
        "-DTINT_BUILD_GLSL_WRITER=1",

        include("libs/dawn"),
        include("libs/dawn/third_party/tint"),
        include("libs/dawn/third_party/tint/include"),

        // Required for TINT_BUILD_SPV_READER=1 and TINT_BUILD_SPV_WRITER=1, if specified
        include("libs/dawn/third_party/vulkan-deps"),
        include("libs/dawn/third_party/vulkan-deps/spirv-tools/src"),
        include("libs/dawn/third_party/vulkan-deps/spirv-tools/src/include"),
        include("libs/dawn/third_party/vulkan-deps/spirv-headers/src/include"),
        include("libs/dawn/out/Debug/gen/third_party/vulkan-deps/spirv-tools/src"),
        include("libs/dawn/out/Debug/gen/third_party/vulkan-deps/spirv-tools/src/include"),
    }) catch unreachable;

    // libtint_core_all_src
    var sources = std.ArrayList([]const u8).init(b.allocator);
    sources.appendSlice(&.{
        thisDir() ++ "/src/dawn/sources/tint_core_all_src.cc",
        thisDir() ++ "/src/dawn/sources/tint_core_all_src_2.cc",
        thisDir() ++ "/libs/dawn/third_party/tint/src/ast/node.cc",
        thisDir() ++ "/libs/dawn/third_party/tint/src/ast/texture.cc",
    }) catch unreachable;

    const target = (std.zig.system.NativeTargetInfo.detect(b.allocator, step.target) catch unreachable).target;
    switch (target.os.tag) {
        .windows => sources.append(thisDir() ++ "/libs/dawn/third_party/tint/src/diagnostic/printer_windows.cc") catch unreachable,
        .linux => sources.append(thisDir() ++ "/libs/dawn/third_party/tint/src/diagnostic/printer_linux.cc") catch unreachable,
        else => sources.append(thisDir() ++ "/libs/dawn/third_party/tint/src/diagnostic/printer_other.cc") catch unreachable,
    }

    // libtint_sem_src
    sources.appendSlice(&.{
        thisDir() ++ "/src/dawn/sources/tint_sem_src.cc",
        thisDir() ++ "/src/dawn/sources/tint_sem_src_2.cc",
        thisDir() ++ "/libs/dawn/third_party/tint/src/sem/node.cc",
        thisDir() ++ "/libs/dawn/third_party/tint/src/sem/texture_type.cc",
    }) catch unreachable;

    // libtint_spv_reader_src
    sources.append(thisDir() ++ "/src/dawn/sources/tint_spv_reader_src.cc") catch unreachable;

    // libtint_spv_writer_src
    sources.append(thisDir() ++ "/src/dawn/sources/tint_spv_writer_src.cc") catch unreachable;

    // TODO(build-system): make optional
    // libtint_wgsl_reader_src
    for ([_][]const u8{
        "third_party/tint/src/reader/wgsl/lexer.cc",
        "third_party/tint/src/reader/wgsl/parser.cc",
        "third_party/tint/src/reader/wgsl/parser_impl.cc",
        "third_party/tint/src/reader/wgsl/token.cc",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        sources.append(abs_path) catch unreachable;
    }

    // TODO(build-system): make optional
    // libtint_wgsl_writer_src
    for ([_][]const u8{
        "third_party/tint/src/writer/wgsl/generator.cc",
        "third_party/tint/src/writer/wgsl/generator_impl.cc",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        sources.append(abs_path) catch unreachable;
    }

    // TODO(build-system): make optional
    // libtint_msl_writer_src
    for ([_][]const u8{
        "third_party/tint/src/writer/msl/generator.cc",
        "third_party/tint/src/writer/msl/generator_impl.cc",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        sources.append(abs_path) catch unreachable;
    }

    // TODO(build-system): make optional
    // libtint_hlsl_writer_src
    for ([_][]const u8{
        "third_party/tint/src/writer/hlsl/generator.cc",
        "third_party/tint/src/writer/hlsl/generator_impl.cc",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        sources.append(abs_path) catch unreachable;
    }

    // TODO(build-system): make optional
    // libtint_glsl_writer_src
    for ([_][]const u8{
        "third_party/tint/src/transform/glsl.cc",
        "third_party/tint/src/writer/glsl/generator.cc",
        "third_party/tint/src/writer/glsl/generator_impl.cc",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        sources.append(abs_path) catch unreachable;
    }
    lib.addCSourceFiles(sources.items, flags.items);
    return lib;
}

// Builds third_party/vulkan-deps/spirv-tools sources; derived from third_party/vulkan-deps/spirv-tools/src/BUILD.gn
fn buildLibSPIRVTools(b: *Builder, step: *std.build.LibExeObjStep, options: Options) *std.build.LibExeObjStep {
    var main_abs = std.fs.path.join(b.allocator, &.{ thisDir(), "src/dawn/dummy.zig" }) catch unreachable;
    const lib = b.addStaticLibrary("spirv-tools", main_abs);
    lib.install();
    lib.setBuildMode(step.build_mode);
    lib.setTarget(step.target);
    lib.linkLibCpp();

    var flags = std.ArrayList([]const u8).init(b.allocator);
    options.appendFlags(&flags, true) catch unreachable;
    flags.appendSlice(&.{
        include("libs/dawn"),
        include("libs/dawn/third_party/vulkan-deps/spirv-tools/src"),
        include("libs/dawn/third_party/vulkan-deps/spirv-tools/src/include"),
        include("libs/dawn/third_party/vulkan-deps/spirv-headers/src/include"),
        include("libs/dawn/out/Debug/gen/third_party/vulkan-deps/spirv-tools/src"),
        include("libs/dawn/out/Debug/gen/third_party/vulkan-deps/spirv-tools/src/include"),
    }) catch unreachable;

    // spvtools
    var sources = std.ArrayList([]const u8).init(b.allocator);
    sources.appendSlice(&.{
        thisDir() ++ "/src/dawn/sources/spirv_tools.cpp",
        thisDir() ++ "/libs/dawn/third_party/vulkan-deps/spirv-tools/src/source/operand.cpp",
        thisDir() ++ "/libs/dawn/third_party/vulkan-deps/spirv-tools/src/source/spirv_reducer_options.cpp",
    }) catch unreachable;

    // spvtools_val
    sources.append(thisDir() ++ "/src/dawn/sources/spirv_tools_val.cpp") catch unreachable;

    // spvtools_opt
    sources.appendSlice(&.{
        thisDir() ++ "/src/dawn/sources/spirv_tools_opt.cpp",
        thisDir() ++ "/src/dawn/sources/spirv_tools_opt_2.cpp",
        thisDir() ++ "/libs/dawn/third_party/vulkan-deps/spirv-tools/src/source/opt/local_single_store_elim_pass.cpp",
        thisDir() ++ "/libs/dawn/third_party/vulkan-deps/spirv-tools/src/source/opt/loop_unswitch_pass.cpp",
        thisDir() ++ "/libs/dawn/third_party/vulkan-deps/spirv-tools/src/source/opt/mem_pass.cpp",
        thisDir() ++ "/libs/dawn/third_party/vulkan-deps/spirv-tools/src/source/opt/ssa_rewrite_pass.cpp",
        thisDir() ++ "/libs/dawn/third_party/vulkan-deps/spirv-tools/src/source/opt/vector_dce.cpp",
    }) catch unreachable;

    // spvtools_link
    for ([_][]const u8{
        "third_party/vulkan-deps/spirv-tools/src/source/link/linker.cpp",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        sources.append(abs_path) catch unreachable;
    }
    lib.addCSourceFiles(sources.items, flags.items);
    return lib;
}

// Builds third_party/vulkan-deps/spirv-tools sources; derived from third_party/vulkan-deps/spirv-tools/src/BUILD.gn
fn buildLibSPIRVCross(b: *Builder, step: *std.build.LibExeObjStep, options: Options) *std.build.LibExeObjStep {
    var main_abs = std.fs.path.join(b.allocator, &.{ thisDir(), "src/dawn/dummy.zig" }) catch unreachable;
    const lib = b.addStaticLibrary("spirv-cross", main_abs);
    lib.install();
    lib.setBuildMode(step.build_mode);
    lib.setTarget(step.target);
    lib.linkLibCpp();

    var flags = std.ArrayList([]const u8).init(b.allocator);
    options.appendFlags(&flags, false) catch unreachable;
    flags.appendSlice(&.{
        "-DSPIRV_CROSS_EXCEPTIONS_TO_ASSERTIONS",
        include("libs/dawn/third_party/vulkan-deps/spirv-cross/src"),
        include("libs/dawn"),
        "-Wno-extra-semi",
        "-Wno-ignored-qualifiers",
        "-Wno-implicit-fallthrough",
        "-Wno-inconsistent-missing-override",
        "-Wno-missing-field-initializers",
        "-Wno-newline-eof",
        "-Wno-sign-compare",
        "-Wno-unused-variable",
    }) catch unreachable;

    const target = (std.zig.system.NativeTargetInfo.detect(b.allocator, step.target) catch unreachable).target;
    if (target.os.tag != .windows) flags.append("-fno-exceptions") catch unreachable;

    // spvtools_link
    lib.addCSourceFile(thisDir() ++ "/src/dawn/sources/spirv_cross.cpp", flags.items);
    return lib;
}

// Builds third_party/abseil sources; derived from:
//
// ```
// $ find third_party/abseil-cpp/absl | grep '\.cc' | grep -v 'test' | grep -v 'benchmark' | grep -v gaussian_distribution_gentables | grep -v print_hash_of | grep -v chi_square
// ```
//
fn buildLibAbseilCpp(b: *Builder, step: *std.build.LibExeObjStep, options: Options) *std.build.LibExeObjStep {
    var main_abs = std.fs.path.join(b.allocator, &.{ thisDir(), "src/dawn/dummy.zig" }) catch unreachable;
    const lib = b.addStaticLibrary("abseil-cpp", main_abs);
    lib.install();
    lib.setBuildMode(step.build_mode);
    lib.setTarget(step.target);
    lib.linkLibCpp();
    system_sdk.include(b, lib, .{});
    lib.linkSystemLibrary("bcrypt");

    const target = (std.zig.system.NativeTargetInfo.detect(b.allocator, step.target) catch unreachable).target;
    if (target.os.tag == .macos) lib.linkFramework("CoreFoundation");

    var flags = std.ArrayList([]const u8).init(b.allocator);
    options.appendFlags(&flags, false) catch unreachable;
    flags.appendSlice(&.{
        include("libs/dawn"),
        include("libs/dawn/third_party/abseil-cpp"),
    }) catch unreachable;
    if (target.os.tag == .windows) flags.appendSlice(&.{
        "-DABSL_FORCE_THREAD_IDENTITY_MODE=2",
        "-DWIN32_LEAN_AND_MEAN",
        "-DD3D10_ARBITRARY_HEADER_ORDERING",
        "-D_Maybenull_=",
        "-D__in=",
        "-D__out=",
        "-D_CRT_SECURE_NO_WARNINGS",
        "-DNOMINMAX",
    }) catch unreachable;

    // absl
    lib.addCSourceFiles(&.{
        thisDir() ++ "/src/dawn/sources/abseil.cc",
        thisDir() ++ "/libs/dawn/third_party/abseil-cpp/absl/strings/numbers.cc",
        thisDir() ++ "/libs/dawn/third_party/abseil-cpp/absl/time/internal/cctz/src/time_zone_posix.cc",
        thisDir() ++ "/libs/dawn/third_party/abseil-cpp/absl/time/format.cc",
        thisDir() ++ "/libs/dawn/third_party/abseil-cpp/absl/random/internal/randen_hwaes.cc",
    }, flags.items);
    return lib;
}

// Buids dawn wire sources; derived from src/dawn_wire/BUILD.gn
fn buildLibDawnWire(b: *Builder, step: *std.build.LibExeObjStep, options: Options) *std.build.LibExeObjStep {
    var main_abs = std.fs.path.join(b.allocator, &.{ thisDir(), "src/dawn/dummy.zig" }) catch unreachable;
    const lib = b.addStaticLibrary("dawn-wire", main_abs);
    lib.install();
    lib.setBuildMode(step.build_mode);
    lib.setTarget(step.target);
    lib.linkLibCpp();

    var flags = std.ArrayList([]const u8).init(b.allocator);
    options.appendFlags(&flags, false) catch unreachable;
    flags.appendSlice(&.{
        include("libs/dawn"),
        include("libs/dawn/src"),
        include("libs/dawn/src/include"),
        include("libs/dawn/out/Debug/gen/src/include"),
        include("libs/dawn/out/Debug/gen/src"),
    }) catch unreachable;

    lib.addCSourceFile(thisDir() ++ "/src/dawn/sources/dawn_wire_gen.cpp", flags.items);
    return lib;
}

// Builds dawn utils sources; derived from src/utils/BUILD.gn
fn buildLibDawnUtils(b: *Builder, step: *std.build.LibExeObjStep, options: Options) *std.build.LibExeObjStep {
    var main_abs = std.fs.path.join(b.allocator, &.{ thisDir(), "src/dawn/dummy.zig" }) catch unreachable;
    const lib = b.addStaticLibrary("dawn-utils", main_abs);
    lib.install();
    lib.setBuildMode(step.build_mode);
    lib.setTarget(step.target);
    lib.linkLibCpp();

    glfw.link(b, lib, .{ .system_sdk = .{ .set_sysroot = false } });

    var flags = std.ArrayList([]const u8).init(b.allocator);
    options.appendFlags(&flags, false) catch unreachable;
    appendDawnEnableBackendTypeFlags(&flags, options) catch unreachable;
    flags.appendSlice(&.{
        include("libs/mach-glfw/upstream/glfw/include"),
        include("libs/dawn/src"),
        include("libs/dawn/src/include"),
        include("libs/dawn/out/Debug/gen/src/include"),
    }) catch unreachable;

    var sources = std.ArrayList([]const u8).init(b.allocator);
    for ([_][]const u8{
        "src/utils/BackendBinding.cpp",
        "src/utils/NullBinding.cpp",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        sources.append(abs_path) catch unreachable;
    }

    if (options.d3d12.?) {
        // TODO(build-system): keep these in sync with other windows d3d12 flags
        flags.appendSlice(&.{
            "-IC:\\tmp2",
            //"-IC:\\Program Files (x86)\\Windows Kits\\10\\Include\\10.0.19041.0\\um",
            //"-IC:\\Program Files (x86)\\Windows Kits\\10\\Include\\10.0.19041.0\\shared",
            //"-IC:\\Program Files (x86)\\Windows Kits\\10\\Include\\10.0.19041.0\\winrt",
            "-D__EMULATE_UUID=1",
            "-Wno-nonportable-include-path",
            "-Wno-extern-c-compat",
            "-Wno-invalid-noreturn",
            "-Wno-pragma-pack",
            "-Wno-microsoft-template-shadow",
            "-Wno-unused-command-line-argument",
            "-Wno-microsoft-exception-spec",
            "-Wno-implicit-exception-spec-mismatch",
            "-Wno-unknown-attributes",
            "-Wno-c++20-extensions",
            "-D_CRT_SECURE_NO_WARNINGS",

            "-DWIN32_LEAN_AND_MEAN",
            "-DD3D10_ARBITRARY_HEADER_ORDERING",
            "-D_Maybenull_=",
            "-D__in=",
            "-D__out=",
            "-DNOMINMAX",
        }) catch unreachable;

        for ([_][]const u8{
            "src/utils/D3D12Binding.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            sources.append(abs_path) catch unreachable;
        }
    }
    if (options.metal.?) {
        for ([_][]const u8{
            "src/utils/MetalBinding.mm",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            sources.append(abs_path) catch unreachable;
        }
    }

    if (options.desktop_gl.?) {
        for ([_][]const u8{
            "src/utils/OpenGLBinding.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            sources.append(abs_path) catch unreachable;
        }
    }

    if (options.vulkan.?) {
        for ([_][]const u8{
            "src/utils/VulkanBinding.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            sources.append(abs_path) catch unreachable;
        }
    }
    lib.addCSourceFiles(sources.items, flags.items);
    return lib;
}

// Buids dxcompiler sources; derived from libs/DirectXShaderCompiler/CMakeLists.txt
fn buildLibDxcompiler(b: *Builder, step: *std.build.LibExeObjStep, options: Options) *std.build.LibExeObjStep {
    var main_abs = std.fs.path.join(b.allocator, &.{ thisDir(), "src/dawn/dummy.zig" }) catch unreachable;
    const lib = b.addStaticLibrary("dxcompiler", main_abs);
    lib.install();
    lib.setBuildMode(step.build_mode);
    lib.setTarget(step.target);
    lib.linkLibCpp();

    var flags = std.ArrayList([]const u8).init(b.allocator);
    options.appendFlags(&flags, false) catch unreachable;
    flags.appendSlice(&.{
        include("libs/"), 
        include("libs/DirectXShaderCompiler/include/llvm/llvm_assert"),
        include("libs/DirectXShaderCompiler/include"),
        include("libs/DirectXShaderCompiler/build/include"),
        include("libs/DirectXShaderCompiler/build/lib/HLSL"),
        include("libs/DirectXShaderCompiler/build/lib/DxilPIXPasses"),
        include("libs/DirectXShaderCompiler/build/include"),
        "-IC:\\tmp2",
        "-D_In_=",
        "-D_Out_=",
        "-D_Out_opt_=",
        "-D_Ret_notnull_=",
        "-D_Inout_=",
        "-D_Maybenull_=",
        "-D_Outptr_opt_=",
        "-D_In_range_(lb, ub)=",
        "-D_Out_writes_z_(size)=",
        "-D_Use_decl_annotations_=",
        "-D_Out_writes_(size)=",
        "-D_In_opt_count_(size)=",
        "-D_Outptr_result_maybenull_=",
        "-D_Analysis_assume_(expr)=",
        "-D_Field_size_full_(size)=",
        "-D_In_reads_bytes_(size)=",
        "-D_Field_size_opt_(size)=",
        "-D_In_NLS_string_(size)=",
        "-D_Outptr_=",
        "-DUNREFERENCED_PARAMETER(x)=",
        //"-DGET_INTRINSIC_ENUM_VALUES",
        "-Wno-inconsistent-missing-override",
        "-Wno-missing-exception-spec",
        "-Wno-switch",
        "-Wno-macro-redefined", // regex2.h and regcomp.c requires this for OUT redefinition
        "-DMSFT_SUPPORTS_CHILD_PROCESSES=1",
        "-DHAVE_LIBPSAPI=1",
        "-DHAVE_LIBSHELL32=1",
    }) catch unreachable;

    const source_dirs = &[_][]const u8{
        "lib/Analysis/IPA",
        "lib/Analysis",
        "lib/AsmParser",
        "lib/Bitcode/Writer",
        "lib/DxcBindingTable",
        "lib/DxcSupport",
        "lib/DxilContainer",
        "lib/DxilPIXPasses",
        "lib/DxilRootSignature",
        "lib/DXIL",
        "lib/DxrFallback",
        "lib/HLSL",
        "lib/IRReader",
        "lib/IR",
        "lib/Linker",
        "lib/miniz",
        "lib/Option",
        "lib/PassPrinters",
        "lib/Passes",
        "lib/ProfileData",
        "lib/Target",
        "lib/Transforms/InstCombine",
        "lib/Transforms/IPO",
        "lib/Transforms/Scalar",
        "lib/Transforms/Utils",
        "lib/Transforms/Vectorize",
    };
    var sources = std.ArrayList([]const u8).init(b.allocator);
    scanSources(b, &sources, "libs/DirectXShaderCompiler/lib/Support", &.{".cpp", ".c"}, &.{
        "DynamicLibrary.cpp", // ignore, HLSL_IGNORE_SOURCES
        "PluginLoader.cpp", // ignore, HLSL_IGNORE_SOURCES
        "Path.cpp", // ignore, LLVM_INCLUDE_TESTS
        "DynamicLibrary.cpp", // ignore
    }) catch unreachable;
    inline for (source_dirs) |dir| {
        scanSources(b, &sources, "libs/DirectXShaderCompiler/" ++ dir, &.{".cpp", ".c"}, &.{}) catch unreachable;
    }
    scanSources(b, &sources, "libs/DirectXShaderCompiler/lib/Bitcode/Reader", &.{".cpp", ".c"}, &.{
        "BitReader.cpp" // ignore
    }) catch unreachable;
    addCSourceFiles(b, lib, sources.items, flags.items);

    // scanSources(b, &sources, "src/dawn/sources/dxcompiler", &.{".cpp"}, &.{
    //     "sources.cpp",
    //     "bitcode.cpp",
    //     "transforms.cpp",
    // }) catch unreachable;
    //std.debug.print("{s}\n", .{sources.items});
    return lib;
}

fn include(comptime rel: []const u8) []const u8 {
    return "-I" ++ thisDir() ++ "/" ++ rel;
}

fn thisDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}

// TODO(build-system): This and divideSources are needed to avoid Windows process creation argument
// length limits. This should probably be fixed in Zig itself, not worked around here.
fn addCSourceFiles(b: *Builder, step: *std.build.LibExeObjStep, sources: []const []const u8, flags: []const []const u8) void {
    for (divideSources(b, sources) catch unreachable) |divided| step.addCSourceFiles(divided, flags);
}

fn divideSources(b: *Builder, sources: []const []const u8) ![]const []const []const u8 {
    var divided = std.ArrayList([]const []const u8).init(b.allocator);
    var current = std.ArrayList([]const u8).init(b.allocator);
    var current_size: usize = 0;
    for (sources) |src| {
        if (current_size + src.len >= 30000) {
            try divided.append(current.items);
            current = std.ArrayList([]const u8).init(b.allocator);
            current_size = 0;
        }
        current_size += src.len;
        try current.append(src);
    }
    return divided.items;
}

fn scanSources(b: *Builder, dst: *std.ArrayList([]const u8), comptime rel_dir: []const u8, extensions: []const []const u8, excluding: []const []const u8) !void {
    const abs_dir = thisDir() ++ "/" ++ rel_dir;
    var dir = try std.fs.openDirAbsolute(abs_dir, .{.iterate = true});
    defer dir.close();
    var dir_it = dir.iterate();
    while (try dir_it.next()) |entry| {
        if (entry.kind != .File) continue;
        var abs_path = try std.fs.path.join(b.allocator, &.{abs_dir, entry.name});
        abs_path = try std.fs.realpathAlloc(b.allocator, abs_path);

        const allowed_extension = blk: {
            const ours = std.fs.path.extension(entry.name);
            for (extensions) |ext| {
                if (std.mem.eql(u8, ours, ext)) break :blk true;
            }
            break :blk false;
        };
        if (!allowed_extension) continue;

        const excluded = blk: {
            for (excluding) |excluded| {
                if (std.mem.eql(u8, entry.name, excluded)) break :blk true;
            }
            break :blk false;
        };
        if (excluded) continue;

        try dst.append(abs_path);
    }
}