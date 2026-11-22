#!/bin/bash
# It is an ACE compilation flag that cannot be manually modified.
isAceBuildFlag="$ACEBUILDFLAG"
if [ "$isAceBuildFlag" = "true" ]; then
  exit 0
fi

# Select whether you want to execute the compile arkts script.
scriptBuildFlag=true
if [ "$scriptBuildFlag" = "false" ]; then
  exit 0
fi

project_path="__PROJECT_PATH__"
ohpm_path="__OHPM_PATH__"
arkuiXSdkPath="__ARKUIX_SDK_PATH__"

# You can change the module name you want to compile.
moduleLists=entry

# You can change the android arkuix path to the specified path.
android_arkuix_path="$project_path/.arkui-x/android/app/src/main/assets/arkui-x"

# You can change the android systemRes path to the specified path.
android_systemRes_path="$project_path/.arkui-x/android/app/src/main/assets/arkui-x/systemres"

# You can change the ios arkuix path to the specified path.
ios_arkuix_path="$project_path/.arkui-x/ios/arkui-x"

# You can change the ios systemRes path to the specified path.
ios_systemRes_path="$project_path/.arkui-x/ios/arkui-x/systemres"

cd $project_path
$ohpm_path update
chmod 755 hvigorw
./hvigorw default@CompileArkTS -p module=$moduleLists
IFS=',' read -ra folders <<< "$moduleLists"

copyStageBundleToAndroidAndIOS() {
    deleteFile "$ios_arkuix_path"
    deleteFile "$android_arkuix_path"
    copyStageBundleToAndroidAndIOSByTarget "default" ""
    systemResPath="$arkuiXSdkPath/engine/systemres"
    copy "$systemResPath" "$ios_systemRes_path" 
    copy "$systemResPath" "$android_systemRes_path"
}

deleteFile() {
    for folder in "${folders[@]}"
    do
        local path="$1/$folder"
        if [ -d "$path" ]; then
            rm -rf "$path"
        fi
    done
}

copyStageBundleToAndroidAndIOSByTarget() {
    for folder in "${folders[@]}"
    do
        local src="$project_path/$folder/build/default/intermediates/loader_out/$1/ets"
        local resindex="$project_path/$folder/build/default/intermediates/res/$1/resources.index"
        local resPath="$project_path/$folder/build/default/intermediates/res/$1/resources"
        local moduleJsonPath="$project_path/$folder/build/default/intermediates/res/$1/module.json"
        local destClassName="$folder$2"
        local distAndroid="$android_arkuix_path/$destClassName/ets"
        local distIOS="$ios_arkuix_path/$destClassName/ets"
        local resindexAndroid="$android_arkuix_path/$destClassName/resources.index"
        local resPathAndroid="$android_arkuix_path/$destClassName/resources"
        local moduleJsonPathAndroid="$android_arkuix_path/$destClassName/module.json"
        local resindexIOS="$ios_arkuix_path/$destClassName/resources.index"
        local resPathIOS="$ios_arkuix_path/$destClassName/resources"
        local moduleJsonPathIOS="$ios_arkuix_path/$destClassName/module.json"
        mkdir -p "$distAndroid"
        copy "$src" "$distAndroid"
        copy "$resPath" "$resPathAndroid"
        cp "$resindex" "$resindexAndroid"
        cp "$moduleJsonPath" "$moduleJsonPathAndroid"
        mkdir -p "$distIOS"
        copy "$src" "$distIOS"
        copy "$resPath" "$resPathIOS"
        cp "$resindex" "$resindexIOS"
        cp "$moduleJsonPath" "$moduleJsonPathIOS"
    done
}

copy() {
  local src="$1"
  local dst="$2"
  for item in "$src"/*; do
    if [[ "${item##*/}" != "." ]]; then
      src_file="$src/${item##*/}"
      dst_file="$dst/${item##*/}"
      if [[ -f "$src_file" ]]; then
        parent_dir="$(dirname "$dst_file")"
        if [ ! -d "$parent_dir" ]; then
            mkdir -p "$parent_dir"
        fi
        cp "$src_file" "$dst_file"
      elif [[ -d "$src_file" ]]; then
        if [ ! -d "$dst_file" ]; then
            mkdir -p "$dst_file"
        fi
        copy "$src_file" "$dst_file"
      fi
    fi
  done
}

copyStageBundleToAndroidAndIOS