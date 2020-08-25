# Godot JoypadSupport
GDscript Class with some helper Component and Resource Scripts and Scenes to automate much of the work in identifying Joypads, showing button prompts and letting players ustomize input maps

Here is a gif of it in motion:

![Gif of menu navigation in Escape from the cosmic abyss, going to options and changing Input Mappings](https://thumbs.gfycat.com/FinishedGrandioseBlackmamba-size_restricted.gif)

## Instalation and Usage
1. Download or clone this repository into your game repository. You can put the folder wherever you want or makes more sense into your organization
1. Got to `Project Settings > Autoload`, Select the `JoypadSupport.tscn` file and add with `JoypasSupport` as the name. Make sure the singleton check box is marked
1. Instance the scene `PromptInputAction` that is inside the Prompts folder wherever you need to show Button Prompts. It takes an action name in the exported variables in the editor and uses it to look for the registered events for that action and shows the most relevant one to the situation, which is in this order:
   1. A Joypad button texture if any Joypad is connected. It will try to autodetect what kind of joypad it is to show either an Xbox, Playstation or Swith button image
   2. A Keyboard/Mouse button texture
   3. A text Label if it can't find an image for any of the above
 
That's basically it. There is also an example of PromptLegend so you can see a suggestion on  how to make your own, and a Test Scene. There are many helper methods to help with a Input Map menu where the user can change the events on any action you want to allow him to do it, but there's still no example scene for it. If you need to you can look at the OptionsMenu of my game to see how I implemented it in [this repository](https://github.com/eh-jogos/EscapeFromTheCosmicAbyss).

Each script has some documentation at the top of it, so I hope that helps!

## List of things JoypadSupport tries to automate or at least help greatly with:
* Identifying Joypads 
  * some of this can be used standalone with `JS_JoypadIdentifier.gd`
* Showing Corretc Button Prompts and Updating them in real time as joypads are connected/disconnected
* Swapping ui_accept and ui_cancel for switch controllers (the A is Xbox B and the B is Xbox A)
* Saving and loading mappings 
* Generating Input Profiles 
  * With `JS_InputMapAction.gd` and `JS_InputMapProfiles.gd`, they don't work by themselves but you can look at how JoypadSupport.gd uses them, if you want to build a different solution or don't want to use the autoload)
* Give the player the option to turn autodetection off and choose a specific joypad skin to show all prompts in
* Give the player the option to manually swap ui_accept and ui_cancel (hey, maybe they're used to using Circle to confirm and Cross to cancel)

## License and Acknowledgements
This is Licensed under MIT as you and see in the LICENSE file, so use it however you want, in any comercial projects or not, just link this repository or this readme in the credits or somewhere.

The button images used here and under the Folder "Prompts" were done by Nicolae Berbece from [Those Awesome Guys](https://thoseawesomeguys.com/) and were graciously shared in Public Domain under Creative Comomns 0 (CC0). 

They can be downloaded directly from their [site](https://thoseawesomeguys.com/prompts/) or from [OpenGameArt](https://opengameart.org/content/free-keyboard-and-controllers-prompts-pack) (where I found it originally).
