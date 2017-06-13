#!/bin/sh
#
# Setup-openwith script by Lit
VERSION="1.5"
# https://github.com/Lighting/Setup-openwith
#

# --------------------------------------------------------------------------
# List of known readers names
#
# READERS_APPS - list of readers executable files (in bin/ directory)
# READERS_NAMES - list of readers title names
#
READERS_APPS="AdobeViewer.app,fbreader.app,eink-reader.app,djviewer.app,picviewer.app,browser.app,cr3-pb.app,pbimageviewer.app,koreader.app"
READERS_NAMES="@OpenWithAdobe,@OpenWithFbreader,@eink-reader,DjView,@Gallery,@Browser,Cool Reader 3,Pbimageviewer,KOReader"
#
READER_EXT1="asp:@HTML_file:1:cr3-pb.app:ICON_HTM"
READER_EXT2="cgi:@HTML_file:1:cr3-pb.app:ICON_HTM"
READER_EXT3="chm:@Z_HTML_file:1:cr3-pb.app:ICON_CHM"
READER_EXT4="epub:@EPUB_file:1:cr3-pb.app:ICON_EPUB"
READER_EXT5="fb2:@FB2_file:1:cr3-pb.app:ICON_FB2"
READER_EXT6="htm:@HTML_file:1:cr3-pb.app:ICON_HTM"
READER_EXT7="htm:@HTML_file:1:cr3-pb.app:ICON_HTM"
READER_EXT8="jsp:@HTML_file:1:cr3-pb.app:ICON_HTM"
READER_EXT9="mht:@HTML_file:1:cr3-pb.app:ICON_HTM"
READER_EXT10="php:@HTML_file:1:cr3-pb.app:ICON_HTM"
READER_EXT11="pl:@HTML_file:1:cr3-pb.app:ICON_HTM"
READER_EXT12="rtf:@RTF_file:1:cr3-pb.app:ICON_RTF"
READER_EXT13="txt:@Text_file:1:cr3-pb.app:ICON_TXT"
READER_EXT14="tar:@TAR_file:1:pbimageviewer.app:ICON_JPG"
READER_EXT15="tar.gz:@TAR_file:1:pbimageviewer.app:ICON_JPG"
READER_EXT16="tgz:@TAR_file:1:pbimageviewer.app:ICON_JPG"
READER_EXT17="tar.bz2:@TAR_file:1:pbimageviewer.app:ICON_JPG"
READER_EXT18="tbz2:@TAR_file:1:pbimageviewer.app:ICON_JPG"
READER_EXT19="zip:@ZIP_file:1:pbimageviewer.app:ICON_JPG"
READER_EXT20="cbz:@ZIP_file:1:pbimageviewer.app:ICON_JPG"
READER_EXT21="rar:@RAR_file:1:pbimageviewer.app:ICON_JPG"
READER_EXT22="cbr:@RAR_file:1:pbimageviewer.app:ICON_JPG"
READER_EXT23="7z:@ZIP_file:1:pbimageviewer.app:ICON_JPG"
READER_EXT24="cb7:@ZIP_file:1:pbimageviewer.app:ICON_JPG"
READER_EXT25="cbt:@TAR_file:1:pbimageviewer.app:ICON_JPG"
READER_EXT26="jpg:@JPEG_image:2:pbimageviewer.app:ICON_JPG"
READER_EXT27="jpeg:@JPEG_image:2:pbimageviewer.app:ICON_JPG"
READER_EXT28="png:@PNG_image:2:pbimageviewer.app:ICON_PNG"
READER_EXT29="bmp:@BMP_image:2:pbimageviewer.app:ICON_BMP"
READER_EXT30="tif:@TIFF_image:2:pbimageviewer.app:ICON_TIFF"
READER_EXT31="tiff:@TIFF_image:2:pbimageviewer.app:ICON_TIFF"
READER_EXT32="pdf:@PDF_file:1:koreader.app:ICON_PDF"
READER_EXT33="djvu:@DJVU_file:1:koreader.app:ICON_DJVU"
READER_EXT34="epub:@EPUB_file:1:koreader.app:ICON_EPUB"
READER_EXT35="fb2:@FB2_file:1:koreader.app:ICON_FB2"
READER_EXT36="mobi:@MOBI_file:1:koreader.app:ICON_MOBI"
READER_EXT37="zip:@ZIP_file:1:koreader.app:ICON_ZIP"
READER_EXT38="cbz:@ZIP_file:1:koreader.app:ICON_ZIP"
# --------------------------------------------------------------------------

# --------------------------------------------------------------------------
# Fast-switch feature for .fb2 extension
#
# FAST_SWITCH_APP - new app for fast-switch
# default_switch_app - default app switched with new app and vice versa
# ALTERNATE_SWITCH_APP - alternate default app if founded for .fb2 extension
# FAST_SWITCH_SHORTCUT - element in theme replaced by fast-switch
#
FAST_SWITCH_APP="cr3-pb.app"
default_switch_app="fbreader.app"
ALTERNATE_SWITCH_APP="eink-reader.app"
FAST_SWITCH_SHORTCUT="control.panel.shortcut.5."
FAST_SWITCH_TEXT="FB2:"
OPEN_SWITCH_NAME="OpenWith"
FAST_SWITCH_SUFFIX="(CR3)"
DEFAULT_SWITCH_SUFFIX="(Reader)"
# --------------------------------------------------------------------------

DEFAULT_THEME="Line"
TEMP_THEME="/tmp/theme.pbt"
TEMP_THEME_CFG="/tmp/theme.cfg"
TEMP_THEME2_CFG="/tmp/theme2.cfg"
EBRMAIN_CONFIG="/ebrmain/config"
EBRMAIN_LANG="/ebrmain/language"
EBRMAIN_THEME="/ebrmain/themes"
SYSTEM_PATH="/mnt/ext1/system"
SYSTEM_BIN="$SYSTEM_PATH/bin"
SYSTEM_SETTINGS="$SYSTEM_PATH/config/settings"
EBRMAIN_EXTENSIONS_CFG="$EBRMAIN_CONFIG/extensions.cfg"
SYSTEM_EXTENSIONS_CFG="$SYSTEM_PATH/config/extensions.cfg"
SYSTEM_GLOBAL_CFG="$SYSTEM_PATH/config/global.cfg"
SYSTEM_OPENWITH_CFG="$SYSTEM_PATH/config/openwith.cfg"
LNG="`awk -F= '/^language=/ {print $2}' "$SYSTEM_GLOBAL_CFG"|tr -d '\r'`"

Get_word()
{
 w="`awk -F= '/^'"$2"'=/ {print $2}' "$EBRMAIN_LANG/${LNG:-en}.txt"|tr -d '\r'`"
 eval "$1=\"${w:-$2}\""
}

Get_word w1 "@Install"
Get_word w2 "@Advanced"
Get_word w3 "@PersonalSettings"
Get_word w4 "@OpenWith"
/ebrmain/bin/dialog 2 "" "$w1: $w2
\"$w3 -> $w4\" v$VERSION" "@Install_q" "@Cancel"
[ "$?" != 1 ] && exit 1

Get_reader_name()
{
 app_count=1
 for app in $READERS_APPS; do
  if [ "$app" = "$2" ]; then
   app_name="`echo "$READERS_NAMES"|cut -d , -f$app_count`"
   eval "$1=\"$app_name\""
   return
  fi
  app_count="`expr $app_count + 1`"
 done
 eval "$1=\"${2%.app}\""
}

extensions=""
count=1
for str in `awk /:/ "$EBRMAIN_EXTENSIONS_CFG"|tr -d '\r'`; do
 ext="${str%%:*}"
 apps="`echo "$str"|cut -d : -f4`"
 extensions="$extensions,$ext"
 eval "APP_EXT$count=\"$apps\""
 [ "$apps" != "${apps/,}" ] && eval "APP_SYS$count=1"
 count="`expr $count + 1`"
done
extensions=${extensions:1}

for str in `awk /:/ "$SYSTEM_EXTENSIONS_CFG"|tr -d '\r'`; do
 ext="${str%%:*}"
 [ "$extensions" = "${extensions/,$ext}" ] && extensions="$extensions,$ext" && continue
 count=1
 IFS=,
 apps="`echo "$str"|cut -d : -f4`"
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
sed -e :a -e '/^\n*$/{$d;N;};/\n$/ba' "$EBRMAIN_CONFIG/settings/personalize.json"|head -n -1 > "$SYSTEM_SETTINGS/personalize.json"
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

Get_word w1 "@Default"
IFS=,
count=0
for ext in $extensions; do
 count="`expr $count + 1`"
 eval "apps=\"\$APP_EXT$count\""
 [ "$ext" = "fb2" -a "${apps/$ALTERNATE_SWITCH_APP}" != "$apps" ] && default_switch_app="$ALTERNATE_SWITCH_APP"
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
 if [ "$reader_app_sys" = "1" ]; then
  Get_word reader_name_def "$reader_name_first"
  echo -n " ($w1 $reader_name_def)" >> "$SYSTEM_SETTINGS/openwith.json"
 fi
 echo -e '"
\t},' >> "$SYSTEM_SETTINGS/openwith.json"
 eval "reader_app_def=\"\$APP_DEF$count\""
 [ -z "$reader_app_def" ] || /ebrmain/bin/iv2sh WriteConfig "$SYSTEM_OPENWITH_CFG" "$ext" "$reader_app_def"
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
LNG="`awk -F= '\''/^language=/ {print $2}'\'' "'"$SYSTEM_GLOBAL_CFG"'"|tr -d '\''\r'\''`"

Get_word()
{
 w="`awk -F= '\''/^'\''"$2"'\''=/ {print $2}'\'' "'"$EBRMAIN_LANG"'/${LNG:-en}.txt"|tr -d '\''\r'\''`"
 eval "$1=\"${w:-$2}\""
}

Get_word w1 "@Delete"
Get_word w2 "@Advanced"
Get_word w3 "@OpenWith"
/ebrmain/bin/dialog 4 "" "$w1
$w2
\"$w3\"?" "@Delete"
if [ "$?" = "1" ]; then
 rm -f "'"$SYSTEM_SETTINGS/personalize.json"'"
 rm -f "'"$SYSTEM_SETTINGS/openwith.json"'"
 rm -f "'"$SYSTEM_OPENWITH_CFG"'"
 openwith="'"$SYSTEM_PATH"'/profiles/*/config/settings/openwith.json"
 if [ "$openwith" = "`echo $openwith`" ]; then
  rm -f "'"$SYSTEM_BIN/openwith_apply.app"'"
  rm -f "'"$SYSTEM_BIN/openwith_clear.app"'"
  rm -f "'"$SYSTEM_BIN/openwith_remove.app"'"
  rm -f "'"$SYSTEM_BIN/openwith_fb2.app"'"
  GLOBAL_THEME="`awk -F= '\''/^theme=/ {print $2}'\'' "'"$SYSTEM_GLOBAL_CFG"'"|tr -d '\''\r'\''`"
  [ "${GLOBAL_THEME%'"-$OPEN_SWITCH_NAME"'*}" != "$GLOBAL_THEME" ] && /ebrmain/bin/iv2sh WriteConfig "'"$SYSTEM_GLOBAL_CFG"'" theme ""
  rm -f "'"$SYSTEM_PATH"'/themes/"*"'"$OPEN_SWITCH_NAME"'"*.pbt
 fi
 sync
 killall settings.app || true
 /ebrmain/bin/iv2sh SendEventTo -1 154
fi' > "$SYSTEM_BIN/openwith_remove.app"

echo '#!/bin/sh
Set_default()
{
 apps="`echo "$str"|cut -d : -f4`"
 new_apps="$def_app`echo ",$apps"|sed "s/,*$def_app//g"|sed s/,,*/,/g`"
 sed -i "/^$ext:/s:\:$apps\::\:$new_apps\::" "'"$SYSTEM_EXTENSIONS_CFG"'"
}

while read def_str; do
 apply=0
 def_ext="${def_str%%=*}"
 def_app="${def_str#*=}"
 for str in `awk /:/ "'"$SYSTEM_EXTENSIONS_CFG"'"`; do
  ext="${str%%:*}"
  [ "$ext" != "$def_ext" ] && continue
  Set_default
  apply=1
 done
 if [ $apply = 0 ]; then
 for str in `awk /:/ "'"$EBRMAIN_EXTENSIONS_CFG"'"`; do
  ext="${str%%:*}"
  [ "$ext" != "$def_ext" ] && continue
  echo "$str" >> "'"$SYSTEM_EXTENSIONS_CFG"'"
  Set_default
 done
 fi
done < "'"$SYSTEM_OPENWITH_CFG"'"
sync
/ebrmain/bin/iv2sh SendEventTo -1 154' > "$SYSTEM_BIN/openwith_apply.app"

echo '#!/bin/sh
LNG="`awk -F= '\''/^language=/ {print $2}'\'' "'"$SYSTEM_GLOBAL_CFG"'"|tr -d '\''\r'\''`"

Get_word()
{
 w="`awk -F= '\''/^'\''"$2"'\''=/ {print $2}'\'' "'"$EBRMAIN_LANG"'/${LNG:-en}.txt"|tr -d '\''\r'\''`"
 eval "$1=\"${w:-$2}\""
}

Get_word w1 "@BrowserClearHistory"
Get_word w2 "@BooksOpened"
Get_word w3 "@APP_file"
/ebrmain/bin/dialog 2 "" "$w1:
$w2 - $w3
(/mnt/ext1/system/config/handlers.cfg)?" "@Clear"
[ "$?" = 1 ] && rm -f /mnt/ext1/system/config/handlers.cfg && sync' > "$SYSTEM_BIN/openwith_clear.app"

if [ "$fast_switch" = "1" ]; then
 GLOBAL_THEME="`awk -F= '/^theme=/ {print $2}' "$SYSTEM_GLOBAL_CFG"|tr -d '\r'`"
 current_theme="${GLOBAL_THEME:-$DEFAULT_THEME}"
 if [ -e "$SYSTEM_PATH/themes/$current_theme.pbt" ]; then
  current_theme_path="$SYSTEM_PATH/themes/$current_theme.pbt"
 elif [ -e "$EBRMAIN_THEME/$current_theme.pbt" ]; then
  current_theme_path="$EBRMAIN_THEME/$current_theme.pbt"
 else
  current_theme="$DEFAULT_THEME"
  current_theme_path="$EBRMAIN_THEME/$current_theme.pbt"
 fi
 cp -f "$current_theme_path" "$TEMP_THEME"
 current_theme_path="$TEMP_THEME"
 openwith_theme="${current_theme%-$OPEN_SWITCH_NAME*}-$OPEN_SWITCH_NAME"
 echo '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'|base64 -d|gzip -d > "$SYSTEM_BIN/pbtheme-openwith"
 Get_reader_name fast_switch_app_name "$FAST_SWITCH_APP"
 Get_reader_name default_switch_app_name "$default_switch_app"
 Get_word default_switch_app_text "$default_switch_app_name"
 $SYSTEM_BIN/pbtheme-openwith -e "$current_theme_path" "$TEMP_THEME_CFG"
 fast_switch_shortcut_position="${FAST_SWITCH_SHORTCUT//./\\.}position="
 sed -i "s/^\($fast_switch_shortcut_position.*$\)/#\1/" "$TEMP_THEME_CFG"
 sed -i "/^${FAST_SWITCH_SHORTCUT//./\\.}.*$/d" "$TEMP_THEME_CFG"
 sed -i "s/^#\($fast_switch_shortcut_position.*$\)/\1/" "$TEMP_THEME_CFG"
 sed -i "/^$fast_switch_shortcut_position.*$/a${FAST_SWITCH_SHORTCUT}icon.name=desktop_launcher_library" "$TEMP_THEME_CFG"
 sed -i "/^$fast_switch_shortcut_position.*$/a${FAST_SWITCH_SHORTCUT}focus.icon.name=desktop_launcher_library_f" "$TEMP_THEME_CFG"
 sed -i "/^$fast_switch_shortcut_position.*$/a${FAST_SWITCH_SHORTCUT}path=$SYSTEM_BIN/openwith_fb2.app" "$TEMP_THEME_CFG"
 cp -f "$TEMP_THEME_CFG" "$TEMP_THEME2_CFG"
 sed -i "/^$fast_switch_shortcut_position.*$/a${FAST_SWITCH_SHORTCUT}text=$FAST_SWITCH_TEXT$fast_switch_app_name" "$TEMP_THEME_CFG"
 $SYSTEM_BIN/pbtheme-openwith -r "$current_theme_path" "$TEMP_THEME_CFG" "$SYSTEM_PATH/themes/$openwith_theme$FAST_SWITCH_SUFFIX.pbt"
 sed -i "/^$fast_switch_shortcut_position.*$/a ${FAST_SWITCH_SHORTCUT}text=$FAST_SWITCH_TEXT$default_switch_app_text" "$TEMP_THEME2_CFG"
 $SYSTEM_BIN/pbtheme-openwith -r "$current_theme_path" "$TEMP_THEME2_CFG" "$SYSTEM_PATH/themes/$openwith_theme$DEFAULT_SWITCH_SUFFIX.pbt"
 rm -f "$SYSTEM_BIN/pbtheme-openwith"
 rm -f "$TEMP_THEME"
 rm -f "$TEMP_THEME_CFG"
 rm -f "$TEMP_THEME2_CFG"
 echo '#!/bin/sh
LNG="`awk -F= '\''/^language=/ {print $2}'\'' "'"$SYSTEM_GLOBAL_CFG"'"|tr -d '\''\r'\''`"

Get_word()
{
 w="`awk -F= '\''/^'\''"$2"'\''=/ {print $2}'\'' "'"$EBRMAIN_LANG"'/${LNG:-en}.txt"|tr -d '\''\r'\''`"
 eval "$1=\"${w:-$2}\""
}

Set_default()
{
 apps="`echo "$str"|cut -d : -f4`"
 app_default="'"$default_switch_app"'"
 app_fast="'"$FAST_SWITCH_APP"'"
 GLOBAL_THEME="`awk -F= '\''/^theme=/ {print $2}'\'' "'"$SYSTEM_GLOBAL_CFG"'"|tr -d '\''\r'\''`"
 current_theme="${GLOBAL_THEME:-'"$DEFAULT_THEME"'}"
 change_theme="no"
 if [ "${current_theme%'"-$OPEN_SWITCH_NAME"'*}" != "$current_theme" ]; then
  change_theme="yes"
  if [ "${current_theme%'"-$OPEN_SWITCH_NAME$FAST_SWITCH_SUFFIX"'*}" != "$current_theme" ]; then
   def_app=$app_default
   def_app_name="'"$default_switch_app_name"'"
   /ebrmain/bin/iv2sh WriteConfig "'"$SYSTEM_GLOBAL_CFG"'" "theme" "${current_theme%'"-$OPEN_SWITCH_NAME"'*}'"-$OPEN_SWITCH_NAME$DEFAULT_SWITCH_SUFFIX"'"
  elif [ "${current_theme%'"-$OPEN_SWITCH_NAME$DEFAULT_SWITCH_SUFFIX"'*}" != "$current_theme" ]; then
   def_app=$app_fast
   def_app_name="'"$fast_switch_app_name"'"
   /ebrmain/bin/iv2sh WriteConfig "'"$SYSTEM_GLOBAL_CFG"'" "theme" "${current_theme%'"-$OPEN_SWITCH_NAME"'*}'"-$OPEN_SWITCH_NAME$FAST_SWITCH_SUFFIX"'"
  else
   change_theme="need"
  fi
 fi
 if [ "$change_theme" != "yes" ]; then
  if [ "${apps%%,*}" != "$app_fast" ]; then
   def_app=$app_fast
   def_app_name="'"$fast_switch_app_name"'"
  else
   def_app=$app_default
   def_app_name="'"$default_switch_app_name"'"
  fi
 fi
 new_apps="$def_app`echo ",$apps"|sed "s/,*$def_app//g"|sed s/,,*/,/g`"
 sed -i "/^$ext:/s:\:$apps\::\:$new_apps\::" "'"$SYSTEM_EXTENSIONS_CFG"'"
 /ebrmain/bin/iv2sh WriteConfig "'"$SYSTEM_OPENWITH_CFG"'" "$ext" "$def_app"
 sync
# Get_word w1 "@SelectBooks"
# Get_word w2 "$def_app_name"
# /ebrmain/bin/dialog 0 "" "$w1: \"$w2\"" "" "" &
# return_code="$!"
 [ "$change_theme" != "no" ] && /ebrmain/bin/iv2sh SendEventTo -1 154
# sleep 1
# kill "$return_code"
 exit 0
}

for str in `awk /:/ "'"$SYSTEM_EXTENSIONS_CFG"'"|tr -d '\''\r'\''`; do
 ext="${str%%:*}"
 [ "$ext" != "fb2" ] && continue
 Set_default
done
for str in `awk /:/ "'"$EBRMAIN_EXTENSIONS_CFG"'"|tr -d '\''\r'\''`; do
 ext="${str%%:*}"
 [ "$ext" != "fb2" ] && continue
 echo "$str" >> "'"$SYSTEM_EXTENSIONS_CFG"'"
 Set_default
done' > "$SYSTEM_BIN/openwith_fb2.app"
 Get_word w1 "@ChangeWidget"
 Get_word w2 "@KA_srch"
 Get_word w3 "@Settings"
 Get_word w4 "@PersonalSettings"
 Get_word w5 "@Theme"
 fs_text="
$w1 \"$w2\"
(\"$default_switch_app_text\"/\"$fast_switch_app_name\"):
$w3->$w4->
$w5:$openwith_theme
"
else
 fs_text=""
fi

Get_word w1 "@Install_complete"
Get_word w2 "@Delete_book"
Get_word w3 "@No"
/ebrmain/bin/dialog 3 "" "$w1
$fs_text
$w2
(""$0"")" "@Yes" "> $w3 <"
[ "$?" = "1" ] && rm -f "$0"

sync
killall settings.app || true
# SendEventTo ALLTASKS EVT_CONFIGCHANGED
/ebrmain/bin/iv2sh SendEventTo -1 154
