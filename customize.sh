SKIPUNZIP=0

set_permissions() {
  set_perm_recursive $MODPATH 0 0 0755 0644
  set_perm_recursive $MODPATH/odm/etc 0 0 0755 0644
  set_perm_recursive $MODPATH/system/vendor/etc 0 0 0755 0644 u:object_r:vendor_configs_file:s0
}

replace_targets() {
  for path in $1; do
    for file in $2; do
      if [ -f "/$path/$file" ]; then
        mkdir -p "$MODPATH/$path"
        touch "$MODPATH/$path/$file"
        ui_print "- Replacing: /$path/$file"
      fi
    done
  done
}

remove_files() {
  replace_targets \
    "system/lib64 system/system_ext/lib64 system/vendor/lib64 odm/vendor/lib64" \
    "libaudioclientimpl.so libaudioflingerimpl.so libaudiopolicyserviceimpl.so libmiaudiopolicymanager.so"

  replace_targets \
    "system/etc/audio system/system_ext/etc/audio system/vendor/etc/audio odm/etc/audio" \
    "audio_lowpower_app_list.xml"
}

remove_files
set_permissions
