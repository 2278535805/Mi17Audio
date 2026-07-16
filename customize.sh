SKIPUNZIP=0

print_modname() {
	ui_print "*********************************"
	ui_print "-       小米 17 音频优化"
	ui_print "*********************************"
}

set_permissions() {
	set_perm_recursive $MODPATH 0 0 0755 0644
	set_perm_recursive $MODPATH/odm/etc 0 0 0755 0644
	set_perm_recursive $MODPATH/system/vendor/etc 0 0 0755 0644 u:object_r:vendor_configs_file:s0
}

replace_so() {
  SO_FILES="libaudioclientimpl.so libaudioflingerimpl.so libaudiopolicyserviceimpl.so libmiaudiopolicymanager.so"
  SEARCH_PATHS="system/lib64 system/system_ext/lib64 system/vendor/lib64 odm/vendor/lib64"
  for path in $SEARCH_PATHS; do
    for so in $SO_FILES; do
      if [ -f "/$path/$so" ]; then
        mkdir -p "$MODPATH/$path"
        touch "$MODPATH/$path/$so"
        ui_print "- Replacing: /$path/$so"
      fi
    done
  done
}

print_modname
replace_so
set_permissions
