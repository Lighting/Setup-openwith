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

$w3 \"$w4\":
.fb2 $w5
($w6 \"$fast_switch_fbreader_name\" / \"$fast_switch_app_name\")

$w8 $w9->
$w10->
$w11:OpenWith" "@No" "@Yes"
 if [ "$?" = 2 ]; then
  echo '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
XcSe65v7bIFc8SJy/waBq3QQdBwAAA==' | base64 -d | gzip -d > "$SYSTEM_BIN/pbtheme-openwith"
  CURRENT_THEME="`awk -F= '\''/^theme=/ {print $2}'\'' '"$SYSTEM_CONFIG"'/global.cfg`"
  $SYSTEM_BIN/pbtheme-openwith -e "$EBRMAIN_THEME/${CURRENT_THEME:-Line}.pbt" /tmp/theme.cfg
  sed -i 's/^\(control\.panel\.shortcut\.5\.icon\.name=\).*$/\1desktop_launcher_library/' /tmp/theme.cfg
  sed -i 's/^\(control\.panel\.shortcut\.5\.focus\.icon\.name=\).*$/\1desktop_launcher_library_f/' /tmp/theme.cfg
  sed -i 's/^\(control\.panel\.shortcut\.5\.text=\).*$/\1fb2/' /tmp/theme.cfg
  sed -i 's:^\(control\.panel\.shortcut\.5\.\)type=.*$:\1path='"$SYSTEM_BIN/openwith_fb2.app"':' /tmp/theme.cfg
  $SYSTEM_BIN/pbtheme-openwith -r "$EBRMAIN_THEME/${CURRENT_THEME:-Line}.pbt" /tmp/theme.cfg "$SYSTEM_PATH/themes/OpenWith.pbt"
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
 /ebrmain/bin/dialog 0 "" "$w1: \"$def_app_name\"" &
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
# SendEventTo ALLTASKS EVT_CONFIGCHANGED
/ebrmain/bin/iv2sh SendEventTo -1 154
