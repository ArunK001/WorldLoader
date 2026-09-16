#!/usr/bin/env python3
"""Regenerate WorldLoader.xcodeproj/project.pbxproj including map JSON resources."""
import uuid
import os

root = "/Users/pcsi/Documents/WorldLoader"
app_root = os.path.join(root, "WorldLoader")

sources = []
metal_sources = []
for dirpath, _, filenames in os.walk(app_root):
    for f in filenames:
        rel = os.path.relpath(os.path.join(dirpath, f), root)
        if f.endswith(".swift"):
            sources.append(rel)
        elif f.endswith(".metal"):
            metal_sources.append(rel)
sources.sort()
metal_sources.sort()
all_compile = sources + metal_sources


json_resources = []
maps_dir = os.path.join(app_root, "Resources", "Maps")
if os.path.isdir(maps_dir):
    for f in sorted(os.listdir(maps_dir)):
        if f.endswith(".json"):
            json_resources.append(os.path.relpath(os.path.join(maps_dir, f), root))


def uid():
    return uuid.uuid4().hex[:24].upper()


project_id = uid()
target_id = uid()
sources_phase = uid()
resources_phase = uid()
frameworks_phase = uid()
product_ref = uid()
main_group = uid()
products_group = uid()
app_group = uid()
core_group = uid()
models_group = uid()
engine_group = uid()
maps_code_group = uid()
views_group = uid()
demo_group = uid()
resources_group = uid()
maps_res_group = uid()
assets_ref = uid()
assets_build = uid()
config_list_project = uid()
config_list_target = uid()
debug_project = uid()
release_project = uid()
debug_target = uid()
release_target = uid()

file_refs = {s: uid() for s in all_compile}
build_files = {s: uid() for s in all_compile}
json_refs = {j: uid() for j in json_resources}
json_builds = {j: uid() for j in json_resources}
metal_group = uid()

top_files, core_models, core_engine, core_maps, core_metal, views, demo = [], [], [], [], [], [], []
for s in all_compile:
    if "/Core/Models/" in s:
        core_models.append(s)
    elif "/Core/Engine/" in s:
        core_engine.append(s)
    elif "/Core/Maps/" in s:
        core_maps.append(s)
    elif "/Core/Metal/" in s:
        core_metal.append(s)
    elif "/Views/" in s:
        views.append(s)
    elif "/Demo/" in s:
        demo.append(s)
    else:
        top_files.append(s)


def refs(paths, lookup):
    return "\n".join(f"\t\t\t\t{lookup[p]} /* {os.path.basename(p)} */," for p in paths)


def file_type(path):
    if path.endswith(".metal"):
        return "sourcecode.metal"
    return "sourcecode.swift"


nl = "\n"
build_file_lines = nl.join(
    f"\t\t{build_files[s]} /* {os.path.basename(s)} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[s]} /* {os.path.basename(s)} */; }};"
    for s in all_compile
)
json_build_lines = nl.join(
    f"\t\t{json_builds[j]} /* {os.path.basename(j)} in Resources */ = {{isa = PBXBuildFile; fileRef = {json_refs[j]} /* {os.path.basename(j)} */; }};"
    for j in json_resources
)
file_ref_lines = nl.join(
    f'\t\t{file_refs[s]} /* {os.path.basename(s)} */ = {{isa = PBXFileReference; lastKnownFileType = {file_type(s)}; path = {os.path.basename(s)}; sourceTree = "<group>"; }};'
    for s in all_compile
)
json_ref_lines = nl.join(
    f'\t\t{json_refs[j]} /* {os.path.basename(j)} */ = {{isa = PBXFileReference; lastKnownFileType = text.json; path = {os.path.basename(j)}; sourceTree = "<group>"; }};'
    for j in json_resources
)
source_build_lines = nl.join(
    f"\t\t\t\t{build_files[s]} /* {os.path.basename(s)} in Sources */," for s in all_compile
)
resource_build_lines = nl.join(
    [f"\t\t\t\t{assets_build} /* Assets.xcassets in Resources */,"]
    + [f"\t\t\t\t{json_builds[j]} /* {os.path.basename(j)} in Resources */," for j in json_resources]
)

pbx = f'''// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 56;
	objects = {{

/* Begin PBXBuildFile section */
{build_file_lines}
{json_build_lines}
		{assets_build} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {assets_ref} /* Assets.xcassets */; }};
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
		{product_ref} /* WorldLoader.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = WorldLoader.app; sourceTree = BUILT_PRODUCTS_DIR; }};
{file_ref_lines}
{json_ref_lines}
		{assets_ref} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; }};
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		{frameworks_phase} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		{main_group} = {{
			isa = PBXGroup;
			children = (
				{app_group} /* WorldLoader */,
				{products_group} /* Products */,
			);
			sourceTree = "<group>";
		}};
		{products_group} /* Products */ = {{
			isa = PBXGroup;
			children = (
				{product_ref} /* WorldLoader.app */,
			);
			name = Products;
			sourceTree = "<group>";
		}};
		{app_group} /* WorldLoader */ = {{
			isa = PBXGroup;
			children = (
{refs(top_files, file_refs)}
				{core_group} /* Core */,
				{views_group} /* Views */,
				{demo_group} /* Demo */,
				{resources_group} /* Resources */,
				{assets_ref} /* Assets.xcassets */,
			);
			path = WorldLoader;
			sourceTree = "<group>";
		}};
		{core_group} /* Core */ = {{
			isa = PBXGroup;
			children = (
				{models_group} /* Models */,
				{engine_group} /* Engine */,
				{maps_code_group} /* Maps */,
				{metal_group} /* Metal */,
			);
			path = Core;
			sourceTree = "<group>";
		}};
		{models_group} /* Models */ = {{
			isa = PBXGroup;
			children = (
{refs(core_models, file_refs)}
			);
			path = Models;
			sourceTree = "<group>";
		}};
		{engine_group} /* Engine */ = {{
			isa = PBXGroup;
			children = (
{refs(core_engine, file_refs)}
			);
			path = Engine;
			sourceTree = "<group>";
		}};
		{maps_code_group} /* Maps */ = {{
			isa = PBXGroup;
			children = (
{refs(core_maps, file_refs)}
			);
			path = Maps;
			sourceTree = "<group>";
		}};
		{metal_group} /* Metal */ = {{
			isa = PBXGroup;
			children = (
{refs(core_metal, file_refs)}
			);
			path = Metal;
			sourceTree = "<group>";
		}};
		{views_group} /* Views */ = {{
			isa = PBXGroup;
			children = (
{refs(views, file_refs)}
			);
			path = Views;
			sourceTree = "<group>";
		}};
		{demo_group} /* Demo */ = {{
			isa = PBXGroup;
			children = (
{refs(demo, file_refs)}
			);
			path = Demo;
			sourceTree = "<group>";
		}};
		{resources_group} /* Resources */ = {{
			isa = PBXGroup;
			children = (
				{maps_res_group} /* Maps */,
			);
			path = Resources;
			sourceTree = "<group>";
		}};
		{maps_res_group} /* Maps */ = {{
			isa = PBXGroup;
			children = (
{refs(json_resources, json_refs)}
			);
			path = Maps;
			sourceTree = "<group>";
		}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		{target_id} /* WorldLoader */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {config_list_target} /* Build configuration list for PBXNativeTarget "WorldLoader" */;
			buildPhases = (
				{sources_phase} /* Sources */,
				{frameworks_phase} /* Frameworks */,
				{resources_phase} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = WorldLoader;
			productName = WorldLoader;
			productReference = {product_ref} /* WorldLoader.app */;
			productType = "com.apple.product-type.application";
		}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		{project_id} /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1610;
				LastUpgradeCheck = 1610;
				TargetAttributes = {{
					{target_id} = {{
						CreatedOnToolsVersion = 16.1;
					}};
				}};
			}};
			buildConfigurationList = {config_list_project} /* Build configuration list for PBXProject "WorldLoader" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = {main_group};
			productRefGroup = {products_group} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				{target_id} /* WorldLoader */,
			);
		}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		{resources_phase} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{resource_build_lines}
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		{sources_phase} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{source_build_lines}
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		{debug_project} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_TESTABILITY = YES;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_OPTIMIZATION_LEVEL = 0;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			}};
			name = Debug;
		}};
		{release_project} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				VALIDATE_PRODUCT = YES;
			}};
			name = Release;
		}};
		{debug_target} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_CFBundleDisplayName = "World Loader";
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.worldloader.demo;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SUPPORTS_MACCATALYST = NO;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Debug;
		}};
		{release_target} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_CFBundleDisplayName = "World Loader";
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.worldloader.demo;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SUPPORTS_MACCATALYST = NO;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Release;
		}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		{config_list_project} /* Build configuration list for PBXProject "WorldLoader" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{debug_project} /* Debug */,
				{release_project} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{config_list_target} /* Build configuration list for PBXNativeTarget "WorldLoader" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{debug_target} /* Debug */,
				{release_target} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
/* End XCConfigurationList section */
	}};
	rootObject = {project_id} /* Project object */;
}}
'''

out = os.path.join(root, "WorldLoader.xcodeproj", "project.pbxproj")
with open(out, "w") as f:
    f.write(pbx)

# Keep scheme BlueprintIdentifier in sync
scheme_path = os.path.join(root, "WorldLoader.xcodeproj", "xcshareddata", "xcschemes", "WorldLoader.xcscheme")
if os.path.exists(scheme_path):
    text = open(scheme_path).read()
    import re
    text = re.sub(
        r'BlueprintIdentifier = "[A-F0-9]{24}"',
        f'BlueprintIdentifier = "{target_id}"',
        text,
    )
    open(scheme_path, "w").write(text)

print(f"Wrote {out}")
print(f"Swift: {len(sources)}  Metal: {len(metal_sources)}  JSON: {len(json_resources)}  target: {target_id}")
