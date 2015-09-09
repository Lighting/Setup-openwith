#!/bin/sh
#
# Setup-openwith script by Lit
# Version 1.3
# https://github.com/Lighting/Setup-openwith
#

# --------------------------------------------------------------------------
# List of known readers names
#
# READERS_APP - list of readers executable files (/mnt/ext1/system/bin/)
# READERS_NAME - list of readers full names
#
READERS_APP="AdobeViewer.app,fbreader.app,djviewer.app,picviewer.app,browser.app,cr3-pb.app,pbimageviewer.app,koreader.app"
READERS_NAME="@OpenWithAdobe,@OpenWithFbreader,DjView,@Gallery,@Browser,Cool Reader 3,Pbimageviewer,KOReader"
#
# --------------------------------------------------------------------------

FAST_SWITCH_APP="cr3-pb.app"

EBRMAIN_CONFIG="/ebrmain/config"
EBRMAIN_LANG="/ebrmain/language"
EBRMAIN_THEME="/ebrmain/themes"
SYSTEM_PATH="/mnt/ext1/system"
SYSTEM_BIN="$SYSTEM_PATH/bin"
SYSTEM_CONFIG="$SYSTEM_PATH/config"
SYSTEM_SETTINGS="$SYSTEM_CONFIG/settings"
LNG="`awk -F= '/^language=/ {print $2}' "$SYSTEM_CONFIG/global.cfg"`"
READERS_COUNT="`echo "$READERS_APP" | awk -F, '{print NF}'`"

Get_word()
{
 w="`awk -F= '/^@'"$2"'=/ {print $2}' "$EBRMAIN_LANG/${LNG:-en}.txt"`"
 eval "$1=\"${w:-$2}\""
}

Get_word w1 "Install"
Get_word w2 "Advanced"
Get_word w3 "PersonalSettings"
Get_word w4 "OpenWith"
/ebrmain/bin/dialog 2 "" "$w1: $w2
\"$w3 -> $w4\"" "@Install_q" "@Cancel"
[ "$?" != 1 ] && exit 1

Get_reader_name()
{
 app_count=1
 for app in $READERS_APP; do
  if [ "$app" = "$2" ]; then
   app_name="`echo "$READERS_NAME" | cut -d , -f$app_count`"
   eval "$1=\"$app_name\""
   return
  fi
  app_count="`expr $app_count + 1`"
 done
 eval "$1=\"${2%.app}\""
}

extensions=""
count=1
for str in `awk /:/ "$EBRMAIN_CONFIG/extensions.cfg"`; do
 ext="${str%%:*}"
 apps="`echo "$str" | cut -d : -f4`"
 extensions="$extensions,$ext"
 eval "APP_EXT$count=\"$apps\""
 [ "$apps" != "${apps/,}" ] && eval "APP_SYS$count=1"
 count="`expr $count + 1`"
done
extensions=${extensions:1}

for str in `awk /:/ "$SYSTEM_CONFIG/extensions.cfg"`; do
 ext="${str%%:*}"
 [ "$extensions" = "${extensions/,$ext}" ] && extensions="$extensions,$ext" && continue
 count=1
 IFS=,
 apps="`echo "$str" | cut -d : -f4`"
 for ext_def in $extensions; do
  if [ "$ext_def" = "$ext" ]; then
   eval "APP_EXT$count=\"\$APP_EXT$count,$apps\""
   eval "APP_DEF$count=\"${apps%%,*}\""
   break
  fi
  count="`expr $count + 1`"
 done
done

mkdir -p "$SYSTEM_SETTINGS"
sed -e :a -e '/^\n*$/{$d;N;};/\n$/ba' "$EBRMAIN_CONFIG/settings/personalize.json" | head -n -1 > "$SYSTEM_SETTINGS/personalize.json"
echo -e ',
\t{
\t\t"control_type" : "submenu",
\t\t"icon_id" : "ci_panel_config",
\t\t"id" : "openwith",
\t\t"from_file" : "./openwith.json",
\t\t"title_id" : "@OpenWith"
\t}
]' >> "$SYSTEM_SETTINGS/personalize.json"

echo -e '[
\t{
\t\t"control_type" : "executable",
\t\t"icon_id" : "ci_optimize_db",
\t\t"id" : "openwith_apply",
\t\t"storage" : [ "${SYSTEM_APPLICATION_PATH}/openwith_apply.app" ],
\t\t"title_id" : "@PS_ApplyingChanges"
\t},
\t{
\t\t"control_type" : "executable",
\t\t"icon_id" : "ci_scanmode",
\t\t"id" : "openwith_clear",
\t\t"storage" : [ "${SYSTEM_APPLICATION_PATH}/openwith_clear.app" ],
\t\t"title_id" : "@BrowserClearHistory"
\t},' > "$SYSTEM_SETTINGS/openwith.json"

Get_word w1 "Default"
IFS=,
count=0
for ext in $extensions; do
 count="`expr $count + 1`"
 eval "apps=\"\$APP_EXT$count\""
 [ "$apps" = "${apps/,}" ] && continue
 reader_app_first="${apps%%,*}"
 Get_reader_name reader_name_first "$reader_app_first"
 echo -e '\t{
\t\t"control_type" : "list",
\t\t"icon_id" : "ci_dict",
\t\t"id" : "ext_'"$ext"'",
\t\t"kind" : "text",
\t\t"default" : ":'"$reader_app_first:$reader_name_first"'",
\t\t"storage" : [ "${SYSTEM_CONFIG_PATH}/openwith.cfg, '"$ext"'" ],
\t\t"values" : [' >> "$SYSTEM_SETTINGS/openwith.json"
 reader_apps=""
 for reader_app in $apps; do
  [ "$reader_app" = "$FAST_SWITCH_APP" ] && fast_switch=1
  [ "$reader_apps" != "${reader_apps/,$reader_app}" ] && continue
  reader_apps="$reader_apps,$reader_app"
  Get_reader_name reader_name "$reader_app"
  echo -e '\t\t\t":'"$reader_app:$reader_name"'",' >> "$SYSTEM_SETTINGS/openwith.json"
 done
 echo -ne '\t\t\t],
\t\t"title_id" : ".'"$ext" >> "$SYSTEM_SETTINGS/openwith.json"
 eval "reader_app_sys=\"\$APP_SYS$count\""
 if [ "$reader_app_sys" = 1 ]; then
  reader_name_def="${reader_name_first/@}"
  [ "$reader_name_def" != "$reader_name_first" ] && Get_word reader_name_def "$reader_name_def"
  echo -n " ($w1 $reader_name_def)" >> "$SYSTEM_SETTINGS/openwith.json"
 fi
 echo -e '"
\t},' >> "$SYSTEM_SETTINGS/openwith.json"
 eval "reader_app_def=\"\$APP_DEF$count\""
 [ -z "$reader_app_def" ] || /ebrmain/bin/iv2sh WriteConfig "$SYSTEM_CONFIG/openwith.cfg" "$ext" "$reader_app_def"
done

echo -e '\t{
\t\t"control_type" : "executable",
\t\t"icon_id" : "ci_remove_packages",
\t\t"id" : "openwith_remove",
\t\t"storage" : [ "${SYSTEM_APPLICATION_PATH}/openwith_remove.app" ],
\t\t"title_id" : "@Delete"
\t}
]' >> "$SYSTEM_SETTINGS/openwith.json"

echo '#!/bin/sh
Set_default()
{
 apps="`echo "$str" | cut -d : -f4`"
 new_apps="$def_app`echo ",$apps" | sed "s/,*$def_app//g" | sed s/,,*/,/g`"
 sed -i "/^$ext:/s:\:$apps\::\:$new_apps\::" "'"$SYSTEM_CONFIG/extensions.cfg"'"
}

while read def_str; do
 apply=0
 def_ext="${def_str%%=*}"
 def_app="${def_str#*=}"
 for str in `awk /:/ "'"$SYSTEM_CONFIG/extensions.cfg"'"`; do
  ext="${str%%:*}"
  [ "$ext" != "$def_ext" ] && continue
  Set_default
  apply=1
 done
 if [ $apply = 0 ]; then
 for str in `awk /:/ "'"$EBRMAIN_CONFIG/extensions.cfg"'"`; do
  ext="${str%%:*}"
  [ "$ext" != "$def_ext" ] && continue
  echo "$str" >> "'"$SYSTEM_CONFIG/extensions.cfg"'"
  Set_default
 done
 fi
done < "'"$SYSTEM_CONFIG/openwith.cfg"'"
sync' > "$SYSTEM_BIN/openwith_apply.app"

echo '#!/bin/sh
LNG="`awk -F= '\''/^language=/ {print $2}'\'' '"$SYSTEM_CONFIG"'/global.cfg`"

Get_word()
{
 w="`awk -F= '\''/^@'\''"$2"'\''=/ {print $2}'\'' "'"$EBRMAIN_LANG"'/${LNG:-en}.txt"`"
 eval "$1=\"${w:-$2}\""
}

Get_word w1 "BrowserClearHistory"
Get_word w2 "BooksOpened"
Get_word w3 "APP_file"
/ebrmain/bin/dialog 2 "" "$w1:
$w2 - $w3
(handlers.cfg)" "@Clear"
[ "$?" = 1 ] && rm -f /mnt/ext1/system/config/handlers.cfg && sync' > "$SYSTEM_BIN/openwith_clear.app"

echo '#!/bin/sh
LNG="`awk -F= '\''/^language=/ {print $2}'\'' '"$SYSTEM_CONFIG"'/global.cfg`"

Get_word()
{
 w="`awk -F= '\''/^@'\''"$2"'\''=/ {print $2}'\'' "'"$EBRMAIN_LANG"'/${LNG:-en}.txt"`"
 eval "$1=\"${w:-$2}\""
}

Get_word w1 "Delete"
Get_word w2 "Advanced"
Get_word w3 "OpenWith"
/ebrmain/bin/dialog 4 "" "$w1
$w2
\"$w3\"?" "@Delete"
if [ "$?" = 1 ]; then
 rm -f "'"$SYSTEM_SETTINGS"'/personalize.json"
 rm -f "'"$SYSTEM_SETTINGS"'/openwith.json"
 rm -f "'"$SYSTEM_CONFIG"'/openwith.cfg"
 openwith="'"$SYSTEM_PATH"'/profiles/*/config/settings/openwith.json"
 if [ "$openwith" = "`echo $openwith`" ]; then
  rm -f "'"$SYSTEM_BIN"'/openwith_apply.app"
  rm -f "'"$SYSTEM_BIN"'/openwith_clear.app"
  rm -f "'"$SYSTEM_BIN"'/openwith_remove.app"
  rm -f "'"$SYSTEM_BIN"'/openwith_fb2.app"
  /ebrmain/bin/iv2sh WriteConfig "'"$SYSTEM_CONFIG"'/global.cfg" theme ""
  rm -f "'"$SYSTEM_PATH"'/themes/OpenWith.pbt"
 fi
 sync
 killall settings.app || true
fi' > "$SYSTEM_BIN/openwith_remove.app"

if [ "$fast_switch" = 1 ]; then
 Get_word w1 "SearchFound"
 Get_reader_name w2 "$FAST_SWITCH_APP"
 Get_word w3 "Delete"
 Get_word w4 "KA_srch"
 Get_word w5 "Add"
 Get_word w6 "OpenWith"
 Get_word w7 "Sudoku_select"
 Get_word w8 "OpenWithFbreader"
 Get_word w9 "Select"
 Get_word w10 "Settings"
 Get_word w11 "PersonalSettings"
 Get_word w12 "Theme"
 /ebrmain/bin/dialog 2 "" "$w1 $w2
$w3 \"$w4\, $w5 \"FB2\"?
$w3:
$w8 <-> $w2
($w9 $w10->$w11->$w12:\"OpenWith\")" "@No" "@Yes"
 if [ "$?" = 2 ]; then
  echo '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
+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' | base64 -d | gzip -d > "$SYSTEM_BIN/pbtheme-openwith"
  $SYSTEM_BIN/pbtheme-openwith -e "$EBRMAIN_THEME/Line.pbt" /tmp/theme.cfg
  sed -i 's/^\(control\.panel\.shortcut\.5\.icon\.name=\).*$/\1desktop_launcher_library/' /tmp/theme.cfg
  sed -i 's/^\(control\.panel\.shortcut\.5\.focus\.icon\.name=\).*$/\1desktop_launcher_library_f/' /tmp/theme.cfg
  sed -i 's/^\(control\.panel\.shortcut\.5\.text=\).*$/\1FictionBook/' /tmp/theme.cfg
  sed -i 's:^\(control\.panel\.shortcut\.5\.\)type=.*$:\1path='"$SYSTEM_BIN/openwith_fb2.app"':' /tmp/theme.cfg
  $SYSTEM_BIN/pbtheme-openwith -r "$EBRMAIN_THEME/Line.pbt" /tmp/theme.cfg "$SYSTEM_PATH/themes/OpenWith.pbt"
  rm -f $SYSTEM_BIN/pbtheme-openwith
  rm -f /tmp/theme.cfg
  /ebrmain/bin/iv2sh WriteConfig "$SYSTEM_CONFIG/global.cfg" theme "OpenWith"
  echo '#!/bin/sh
Set_default()
{
 apps="`echo "$str" | cut -d : -f4`"
 def_app="fbreader.app"
 [ "$def_app" = "${apps%%,*}" ] && def_app="'"$FAST_SWITCH_APP"'"
 new_apps="$def_app`echo ",$apps" | sed "s/,*$def_app//g" | sed s/,,*/,/g`"
 sed -i "/^$ext:/s:\:$apps\::\:$new_apps\::" "'"$SYSTEM_CONFIG/extensions.cfg"'"
 /ebrmain/bin/iv2sh WriteConfig "$SYSTEM_CONFIG/openwith.cfg" "$ext" "$def_app"
 sync
}

apply=0
for str in `awk /:/ "'"$SYSTEM_CONFIG/extensions.cfg"'"`; do
 ext="${str%%:*}"
 [ "$ext" != "fb2" ] && continue
 Set_default
 apply=1
done
if [ $apply = 0 ]; then
 for str in `awk /:/ "'"$EBRMAIN_CONFIG/extensions.cfg"'"`; do
  ext="${str%%:*}"
  [ "$ext" != "fb2" ] && continue
  echo "$str" >> "'"$SYSTEM_CONFIG/extensions.cfg"'"
  Set_default
 done
fi' > "$SYSTEM_BIN/openwith_fb2.app"
 fi
fi

Get_word w1 "Install_complete"
Get_word w2 "Delete_book"
/ebrmain/bin/dialog 4 "" "$w1
$w2
(`basename ""$0"" .app`)" "@No" "@Yes"
[ "$?" = 2 ] && rm -f "$0"
sync
killall settings.app || true
