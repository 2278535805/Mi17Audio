SKIPUNZIP=0

print_modname() {
	ui_print "*********************************"
	ui_print "-       小米 17 音频优化"
	ui_print "*********************************"
}

copy_dax_files() {
	mkdir -p $MODPATH/system/vendor/etc/dolby/
	cp -rf $MODPATH/odm/etc/dolby/* $MODPATH/system/vendor/etc/dolby/
}

set_permissions() {
	set_perm_recursive $MODPATH 0 0 0755 0644
	set_perm_recursive $MODPATH/system/system_ext/etc 0 0 0755 0644
	set_perm_recursive $MODPATH/system/vendor/etc 0 0 0755 0644 u:object_r:vendor_configs_file:s0
}

print_modname
copy_dax_files
set_permissions
