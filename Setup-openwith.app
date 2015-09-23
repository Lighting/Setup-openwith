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
 Get_reader_name fast_switch_app_name "$FAST_SWITCH_APP"
 Get_word w3 "ChangeWidget"
 Get_word w4 "KA_srch"
 Get_word w5 "OpenWith"
 Get_word w6 "Sudoku_select"
 Get_word fast_switch_fbreader_name "OpenWithFbreader"
 Get_word w8 "Select"
 Get_word w9 "Settings"
 Get_word w10 "PersonalSettings"
 Get_word w11 "Theme"
 /ebrmain/bin/dialog 2 "" "$w1 $fast_switch_app_name.

$w3 \"$w4\"
.fb2 $w5
$w6: $fast_switch_fbreader_name <-> $fast_switch_app_name

($w8 $w9->
$w10->
$w11:OpenWith)" "@No" "@Yes"
 if [ "$?" = 2 ]; then
  echo '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
EvZc39xnC+SKl5D7N8YSXVV0HAAA' | base64 -d | gzip -d > "$SYSTEM_BIN/pbtheme-openwith"
  $SYSTEM_BIN/pbtheme-openwith -e "$EBRMAIN_THEME/Line.pbt" /tmp/theme.cfg
  sed -i 's/^\(control\.panel\.shortcut\.5\.icon\.name=\).*$/\1desktop_launcher_library/' /tmp/theme.cfg
  sed -i 's/^\(control\.panel\.shortcut\.5\.focus\.icon\.name=\).*$/\1desktop_launcher_library_f/' /tmp/theme.cfg
  sed -i 's/^\(control\.panel\.shortcut\.5\.text=\).*$/\1fb2/' /tmp/theme.cfg
  sed -i 's:^\(control\.panel\.shortcut\.5\.\)type=.*$:\1path='"$SYSTEM_BIN/openwith_fb2.app"':' /tmp/theme.cfg
  $SYSTEM_BIN/pbtheme-openwith -r "$EBRMAIN_THEME/Line.pbt" /tmp/theme.cfg "$SYSTEM_PATH/themes/OpenWith.pbt"
  rm -f $SYSTEM_BIN/pbtheme-openwith
  rm -f /tmp/theme.cfg
#  /ebrmain/bin/iv2sh WriteConfig "$SYSTEM_CONFIG/global.cfg" theme "OpenWith"
  echo '#!/bin/sh
LNG="`awk -F= '\''/^language=/ {print $2}'\'' '"$SYSTEM_CONFIG"'/global.cfg`"

Get_word()
{
 w="`awk -F= '\''/^@'\''"$2"'\''=/ {print $2}'\'' "'"$EBRMAIN_LANG"'/${LNG:-en}.txt"`"
 eval "$1=\"${w:-$2}\""
}

Set_default()
{
 apps="`echo "$str" | cut -d : -f4`"
 def_app="fbreader.app"
 Get_reader_name
 def_app_name="'"$fast_switch_fbreader_name"'"
 [ "$def_app" = "${apps%%,*}" ] && def_app="'"$FAST_SWITCH_APP"'" && def_app_name="'"$fast_switch_app_name"'"
 new_apps="$def_app`echo ",$apps" | sed "s/,*$def_app//g" | sed s/,,*/,/g`"
 sed -i "/^$ext:/s:\:$apps\::\:$new_apps\::" "'"$SYSTEM_CONFIG/extensions.cfg"'"
 /ebrmain/bin/iv2sh WriteConfig "'"$SYSTEM_CONFIG/openwith.cfg"'" "$ext" "$def_app"
 sync
 
 Get_word w1 "SelectBooks"
 /ebrmain/bin/dialog 0 "" "$w1 $def_app_name" &
 sleep 2
 kill $!
 
 exit 0
}

for str in `awk /:/ "'"$SYSTEM_CONFIG/extensions.cfg"'"`; do
 ext="${str%%:*}"
 [ "$ext" != "fb2" ] && continue
 Set_default
done
for str in `awk /:/ "'"$EBRMAIN_CONFIG/extensions.cfg"'"`; do
 ext="${str%%:*}"
 [ "$ext" != "fb2" ] && continue
 echo "$str" >> "'"$SYSTEM_CONFIG/extensions.cfg"'"
 Set_default
done' > "$SYSTEM_BIN/openwith_fb2.app"
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
