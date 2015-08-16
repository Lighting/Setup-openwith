#!/bin/sh
#
# Setup-openwith script by Lit
# Version 1.1
#

# --------------------------------------------------------------------------
# Start of configure readers name
#
# READERS_APP - list of reader executable files (/mnt/ext1/system/bin/)
# READERS_NAME - list of readers name
#
READERS_APP="AdobeViewer.app,fbreader.app,djviewer.app,picviewer.app,browser.app,cr3-pb.app,pbimageviewer.app,koreader.app"
READERS_NAME="@OpenWithAdobe,@OpenWithFbreader,DjView,@Gallery,@Browser,Cool Reader 3,Pbimageviewer,KOReader"
#
# End of configure readers name
# --------------------------------------------------------------------------


EBRMAIN_CONFIG="/ebrmain/config"
EBRMAIN_LANG="/ebrmain/language"
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
 rm -f "'"$SYSTEM_BIN"'/openwith_apply.app"
 rm -f "'"$SYSTEM_BIN"'/openwith_clear.app"
 rm -f "'"$SYSTEM_BIN"'/openwith_remove.app"
 killall settings.app
fi
sync' > "$SYSTEM_BIN/openwith_remove.app"

Get_word w1 "Install_complete"
Get_word w2 "Delete_book"
/ebrmain/bin/dialog 2 "" "$w1
$w2
(`basename ""$0"" .app`)" "@No" "@Yes"
[ "$?" = 2 ] && rm -f "$0"
sync
killall settings.app
