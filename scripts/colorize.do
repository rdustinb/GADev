# Example config data here:
# http://noc-performance.googlecode.com/svn-history/r27/trunk/Source/gl_sim/modelsim.tcl

#####################################
# Add any custom waves and such here.
# add wave -noupdate
# add wave -noupdate -divider <NULL>
#####################################

TreeUpdate [SetDefaultTree]
configure wave -background #101010
configure wave -foreground #999999
configure wave -timecolor  #808080
#configure wave -namecolwidth 175
#configure wave -valuecolwidth 350
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 10400
configure wave -gridperiod 20800
configure wave -gridcolor #181818
configure wave -griddelta 20
configure wave -timeline 0
configure wave -displaycommas 1
configure wave -timelineunits us
configure wave -waveselectenable 1
configure wave -waveselectcolor #242424
configure wave -wavebackground #000000
configure wave -cursorcolor #305050

# Signal Colors
configure wave -vectorcolor #556b2f
# Logic Signal Color
set LogicStyleTable(LOGIC_0) {Solid #376b2f 0}
set LogicStyleTable(LOGIC_1) {Solid #376b2f 2}
# Data Bus Color
set LogicStyleTable(LOGIC_DC) {DoubleDash #2f556b 1}
set LogicStyleTable(LOGIC_W) {DoubleDash #6b2f55 1}
# Unconnected Color
set LogicStyleTable(LOGIC_U) {Solid #6b2f55 1}
# Unknown Color
set LogicStyleTable(LOGIC_X) {Solid #6b2f55 1}
# High-Z Color
set LogicStyleTable(LOGIC_Z) {Solid #2f556b 1}

# Wave Window Fonts, use the variable "treeFontV2" to only have to declare a font and size
# with the following format: { <font name> <size>}
# If the font name has a space in it, enclose the font name in another set of curly
# braces: {{PT Mono} 10}
# Main Window Object and Signal List Fonts:
set PrefDefault(fixedFontV2) {{Nimbus Mono L} 11}
# Console Prompt and Other Fonts:
set PrefDefault(footerFontV2) {{PT Mono} 11}
# Window Menu Fonts:
set PrefDefault(menuFontV2) {Tahoma 11}
# Console Fonts:
set PrefDefault(textFontV2) {Tahoma 11}
# Wave Window fonts:
set PrefDefault(treeFontV2) {{PT Mono} 11}

formatTime +commas
update

##################################################################
# Position Window at Favored Location
##################################################################
set windowname [view wave]
view $windowname -undock -x 300 -y 100 -width 1280 -height 800 -title {Master Sim}
