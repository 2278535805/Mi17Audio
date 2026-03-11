MODPATH=${0%/*}

# MODPATH=/data/adb/modules/Mi17Audio

# replace_files /my_product
replace_files() {
  folder="$1"
  find "$MODPATH/$folder" -type f 2>/dev/null | while read -r src; do
    dst="${src#$MODPATH}"
    [[ -f "$dst" ]] && mount --bind "$src" "$dst"
  done
}

# 通过 OverlayFS 挂载目录
overlay_mount(){
  parent=$1
  folder=$2
  if [[ "$folder" == "" ]]; then
    folder="$parent"
  fi
  src=$MODPATH/$parent
  any=$(find "$src" -mindepth 1 -type f | head -1)
  # 目录下有文件才执行挂载
  if [[ "$any" != "" ]]; then
    tmp=/dev/swap_$parent
    mkdir -p $tmp && /system/bin/cp -af --preserve=all "$src" "$tmp"
    mount -t overlay -o lowerdir="$tmp/$folder:$folder" overlay $folder
  fi
}

# 需要手动挂载的目录
mount_folders='odm'
if [[ "$KSU" == "true" ]] || [[ $(which ksud) != "" ]] || [[ $(which apd) != "" ]]; then
  mount_folders='odm'
fi

for parent in $mount_folders; do
  if [ -d "$MODPATH/$parent" ] && [ -d "/$parent" ]; then
    overlay_mount $parent /$parent/etc/extension || replace_files $parent
  fi
done

# 示例：单独挂载某个目录
# module=scene_swap_controller
# target=/my_product/etc/extension
# originTarget=/mnt/vendor$target
# source=/data/adb/modules/$module$target
# mkdir -p $source
# mount -t overlay overlay -o lowerdir=$source:$originTarget $originTarget
