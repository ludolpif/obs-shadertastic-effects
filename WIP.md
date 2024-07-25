# discord shadertastic

- [ ] le message unique dans #release de shadertastic pourrait ne pas mentionner le numéro de version (il affiche 0.0.6 au prochains nouveaux venus)

# obs-shadertastic : PR README.md 0.0.8

- [ ] Voir avec xurei ce qui pense de la PR#4 Help people with CMake include silent ignore of mismatched foldername
  - https://github.com/xurei/obs-shadertastic/pull/4 sinon cleanup mon fork (car sur la branche main)

```diff
obs-shadertastic$ git diff HEAD~2
diff --git a/README.md b/README.md
index aff32a0..5fdd157 100644
--- a/README.md
+++ b/README.md
@@ -6,8 +6,8 @@ Create amazing transitions and filters using shaders, with user-friendly configu
 # Build
 1. In-tree build
     - Build OBS Studio: https://obsproject.com/wiki/Install-Instructions
-    - Check out this repository to plugins/shadertastic
-    - Add `add_subdirectory(shadertastic)` to plugins/CMakeLists.txt
+    - Check out this repository to plugins/shadertastic (⚠ not .../obs-shadertastic as git clone may do)
+    - Add `add_subdirectory(shadertastic)` to plugins/CMakeLists.txt *twice*, after each `add_subdirectory(rtmp-services)`
     - Rebuild OBS Studio
 
 1. Stand-alone build (Linux only)
```

- [ ] comprendre les conditions de dev dans lesquelle on a ce message en boucle 
  - `error: Parameter 'camera_max_opacity' set to invalid size 0, expected 4`

# github.com/xurei/obs-shadertastic-doc/
  
Temporary doc url : https://shadertastic-doc.vercel.app/effect-development/shader-syntax/

- [ ] essayer de suivre le tuto transition de xurei et trouver les difficultés des newcomers
- [ ] essayer de documenter toutes les possibilités offertes dans `meta.json`
  - xurei: param_factory.hpp tous les types y sont listés
- [ ] documenter l'incompatibilité entre ShaderTastic 0.0.8 prebuilt et le obs du dépot deb-multimedia (dmo) pour debian 12 (segfault)
- [ ] Démêler / documenter les divers pre-pending de shader par libobs / libobs-opengl / shadertastic

- [ ] Essayer de trouver une méthode pour pas API break les shaders quand on croise un pb de compat HLSL/GLSL
    - xurei: `mix == lerp`
    - ludolpif: la fonction `mod()` n'exsite pas en HLSL.
    - xurei: ça m'embête + pour mod et fmod qui sont apparemment pas identiques
    - xurei: mais oui ce genre de trucs sont chiants. `fract()` non plus existe pas, mais je l'avais injecté dans le code C++ au load de l'effet
    - ludolpif (un autre jour) : hum, je viens de tomber sur un truc bizarre avec la release 0.0.8, est-ce que c'est connu ?
    - ludolpif (bien plus tard) : en fait il faut utiliser `frac()` qui est correctement convertie au besoin
```
0:43(18): error: no matching function for call to `fract(vec2)'; candidates are:
0:43(18): error:    float fract(float)
0:43(18): error:    float fract(float)
0:43(18): error:    vec2 fract(vec2)
0:43(18): error:    vec3 fract(vec3)
0:43(18): error:    vec4 fract(vec4)
```
- [ ] Lire le git history autour de `libobs-opengl/gl-shaderparser.c` 
  - https://github.com/obsproject/obs-studio/commits/master/libobs-opengl/gl-shaderparser.c
- [ ] Comparer avec la doc actuelle, compléter
  - https://github.com/obsproject/obs-studio/blob/master/libobs-opengl/gl-shaderparser.c#L266
  - dans `NOTE: HLSL-> GLSL intrinsic conversions`
  - xurei: la fonction atan en GLSL c'est atan2 en HLSL
  - ludolpif: tu l'avais où le problème avec atan2 ? ici ?
  - `data/effects/transitions/inkdrop/main.hlsl:    float angle_orig = atan2(uv.y, uv.x);`
  - xurei: en fait atan2 existe pas en GLSL, c'est atan, et OBS converti HLSL -> GLSL mais pas dans l'autre sens, conclusion : faut utiliser atan2
- [ ] lister explicitement tous les types supportés et non supportés
  - ludolpif: ya un type "lowp int" et un type "uint" en GLSL. On en apprends à tous les coins de rue 🙂 lowp int == char en gros
  - xurei: ouais mais je crois que OBS te déconseille de l'utiliser, pour la compat justement
- [ ] lister toutes leurs injections en `const` en plus des `#define` aussi (car ça crée des reserved words que les users peuvent pas deviner)
  - `dstr_cat(&glsp->gl_string, "const bool obs_glsl_compile = true;\n\n");`

- [ ] sourcer la bonne pratique consistant à ne jamais call tex.Sample() dans une branche
- [ ] sourcer des articles à propos de ce qui est gratuit / cher en Shader
- [ ] sourcer ce qui est fait par les compilateurs (inline all funcs, unroll loops)
  - donner les keywords qui aident
  - OpenGL 3.x no binary standard :  https://stackoverflow.com/questions/15900161/are-opengl-binary-program-formats-standardized
  - NVIDIA autoamtic shader cache https://docs.nvidia.com/drive/drive_os_5.1.6.1L/nvvib_docs/index.html#page/DRIVE_OS_Linux_SDK_Development_Guide/Graphics/graphics_binary_shaders.html
  - High-Level Shader Language (HLSL) programs into DirectX Intermediate Language (DXIL) representation. 
  - https://github.com/microsoft/DirectXShaderCompiler
  - OBS n'utilise pas SPIR-V as far as I know https://registry.khronos.org/SPIR-V/

# obs-shadertastic-private branche ludolpif-tries

- [ ] Regarder si tout à été intégré 
  - xurei 6 juillet : J'ai merge ton changement pour le fichier de meta, avec la revision, mais j'ai finalement les effets "template", on va les mettre dans un repo à part je pense.
- [ ] proposer quelques conversion de log debug() non dispo pour les gens qui otn une release normale (DEV_MODE non défini) et des "ça marche pas" silencieux (s'ils noment mal les dossiers filters / transition par exemple
  -  le point qui m'a fait partir en sucette c'est : pas l'info du sous dossier obligatoire "filters" pour mettre son effet en cours de dev dedans, et pas de logs activatble au runtime qui affiche ce chemin là (car tu l'as en debug() avec #define debug vers vide)
- [ ] (ou chercher meilleure solution sur ce qui reste ?)
- [ ] dropper / resync sur main pour les prochaines suggestions
- [ ] essayer d'améliorer le cmake pour un build in-tree sans devoir passer des varaibles à cmake (et build libzip avant)
  - vérifier s'il reste de occurences de `cmake -H` (< 3.13) car c'est le help depuis "longtemps", `cmake -S` doit être assez universel
  - peut être que l'history du plugin template officiel aidera
  - https://github.com/obsproject/obs-plugintemplate/commits/master/
- [ ] essayer de corriger la perte de luminosité des contenus non full-opaques des scènes lors d'une transition shadertastic
  - peut être qu'il y a déjà un fixer de xurei pour les filters pas appliqué sur les transitions
  - peut être que c'est différent car normalement `linear -> linear [...] -> linear -> sRGB` mais dans le cas des transition les sources sont des scènes rendues du coup on a peut être `linear -> linear [...] -> linear -> sRGB -> linear -> sRGB`
  - ludolpif: au fond de : https://registry.khronos.org/OpenGL/extensions/EXT/EXT_texture_sRGB_decode.txt
  - Any texture with an sRGB internal format (for example, GL_SRGB8_ALPHA8 for the internal format) will perform sRGB decode before blending and encode after blending.  This matches the Direct3D9 semantics when D3DUSAGE_QUERY_SRGBWRITE is true of the resource format.
  - sachant qu'OBS utilise `GL_SKIP_DECODE_EXT` :
```c
void device_load_texture(gs_device_t *device, gs_texture_t *tex, int unit) {
    device_load_texture_internal(device, tex, unit, GL_SKIP_DECODE_EXT);
}
void device_load_texture_srgb(gs_device_t *device, gs_texture_t *tex, int unit) {
    device_load_texture_internal(device, tex, unit, GL_DECODE_EXT);
}
```
  - qui est appelé via `gs_effect_set_texture_srgb()` et `gs_effect_set_texture()`
  - ça ne me dit pas comment corriger le code tout à fait, mais plus ça va, plus ça va.
  - autre piste mais semble "fausse" vu l'effet fade classique qui est différent de l'effet face-to-color :
  - Shadertastic n'a aucun call à `gs_enable_framebuffer_srgb()` et `obs-studio/plugins/obs-transitions/transition-fade-to-color.c` en a deux (un pour changer l'état et un pour restaurer après)

- [ ] essayer de voir si les modèles template de filtres/transitions sont au mieux de nos connaissances / commentaires (voir mon vieil obs-draft pour comparer les commentaires)

# obs-shadertastic-lib-private

- [ ] vérifier que printValue() en include de la lib est in-sync avec la release actuel du filter
- [ ] investiguer le bad display que xurei a obtenu et les pb qu'il a avec la config ci après
  - AMD Ryzen 5 / NVIDIA GeForce GTX 1650 Ti Mobile, Linux Mint sur Cinnamon, OBS 30.2.0, Branches main de Shadertastic private et de la lib
  - (comme si yavais un offset de -1 sur la font size)

- [ ] évaluer la pertinence de rename la paire de fonction `rgb2lab()` et `lab2rgb()`
  - pour ajouter le fait qu'elles sont en D50 (et éventuellemetn fournir la paire en D65 ?)
  - Wikipedia says : CIELAB is calculated relative to a reference white, for which the CIE recommends the use of CIE Standard illuminant D65.[1] D65 is used in the vast majority of industries and applications, with the notable exception being the printing industry which uses D50. 
  - (d'autres sources disent que le D65 c'est juste pénible. Je ne sais pas quoi en penser). Dont des grosses, genre photoshop -> D50. 
  - la réf de Rancune_ du site ressource qu'il sait très exact autour des color conversions notament : http://www.brucelindbloom.com/index.html?Eqn_RGB_XYZ_Matrix.html

- [ ] envisager des const avec des couleurs de base
  - xurei: pour le `red` j'avais pensé à des define (à mettre dans un fichier le la lib, genre basic_colors.hlsl)

- [ ] envisager d'intégrer, ou pas la conversion pour HSV
  - https://www.shadertoy.com/view/MsS3Wc
  - iq le fait sans faire 6 if() avec l'astuce d'un mod (6.0...) :
  - mais plus je lis, plus je me dis que c'est un color space du passé et qu'il convient d'apprendre les autres plutôt que d'ajouter celui là 
```c
// Official HSV to RGB conversion 
vec3 hsv2rgb( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );

	return c.z * mix( vec3(1.0), rgb, c.y);
}

// Smooth HSV to RGB conversion 
vec3 hsv2rgb_smooth( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );

	rgb = rgb*rgb*(3.0-2.0*rgb); // cubic smoothing	

	return c.z * mix( vec3(1.0), rgb, c.y);
}
```

- [ ] envisager d'intégrer des fonctions de palettes de couleurs
  - ludolpif à xurei : connais-tu les shadertoy "palettes", si jamais tu vas un include de lib, ça peut savloir le coup de mettre qques palettes assorties (contantes en luma, avec des angles harmonieux en chroma) : https://www.shadertoy.com/view/ll2GD3
  - xurei: je joue un peu avec mais j'ai du mal à faire la palette souhaitée (une sorte d'effet de feu, rouge-jaune-noir)
  - xurei: je coirs qu'il faudrait que je fasse un filtre bidon avec des sliders pour chaque channel de a b c d et que je voie comme ça fait réagir la palette
  - ben c'est tentant de faire un filtre color-palette-chooser oui 😄
  - ce qui est étonnant c'est qu'il n'a pas fait ça dans un espace genre YUV
  - il fait direct en RGB
  - les colors pickers à la adobe comme : https://color.adobe.com/fr/create/color-wheel utiliser en hue

- [ ] envisager des solutions d eshipping des fonctions de la lib qui limitent le breakage des filters existants lors d'une nouvelle version de la lib ou de shadertastic (on tiendra pas facilement avec une lib gravée dans le marbre définitivement)
  - `$ cpp essai.hlsl > essai-preprocesse.hlsl`
  - ou un pre-processeur qu'on peut embed dans l'outil de production de fichier .shadertastic


# obs-shadertastic-effects/utils/my_shader_parser

- [x] contextualisation des erreurs du lexer
- [ ] contextualisation des erreurs compiler OpenGL
    - aucune, numéro de ligne encore différents
- [ ] PR pour le crash dans `ep_parse()` / `ep_compile()` dans le cas d'un ajout de `if(true) {` sans la matching accolade
- [ ] PR possiblement bienvenues dans OBS pour améliorer le error_string de gs_effect_create()

Remarques :
- le `char **error_string` de `gs_effect_create()` n'a jamais été accessible depuis lua
   - profiter pour proposer un meilleur type composite dans un `gs_effect_create2()` ?

- ABI libobs windows n'expose(ra) pas `ep_parse()` donc pas intégrable dans shadertastic.so raisonnablement
  - https://github.com/obsproject/obs-studio/issues/10973

- on tient un cas de shader qui compile pas partout
  - not_lex_error.hlsl (venant de la release de debug_values)
  - run ok Win 10 / OBS 30 / NVIDIA / Shadertastic 0.0.8 precompiled
  - run ok ArchLinux / OBS 30.1.2 / NVIDIA / Shadertastic main en dev-mode
  - syntax error Debian 12 / OBS 29.1.3 / Intel / Shadertastic main en dev-mode
  - voir le `#if 0` de `libobs-opengl/gl-shader.c:gl_shader_init()` car 0 erreurs dans `ep_parse()`
  - le code est en doublon dans `gl_get_shader_info()` et est call depuis `gl_shader_init()`
  - le source post transformation GLSL est dans `struct gs_shader *shader->obj` ?
  - le début semble `static struct gs_shader *shader_create(gs_device_t *device, enum gs_shader_type type, const char *shader_str, const char *file, char **error_string)`


# obs-shadertastic-effects/effects/released_filters/debug_values

- [x] releaser une v1 sur le discord / github pour avoir des retours et des usages
- [ ] vérifier que le code dans obs-shadertastic-lib est in-sync avec la release
- [ ] corriger l'erreur 0.099 -> 0.199 -> 0.100 ajoutée par rapport au shadertoy
- [ ] n'utiliser que des fonctions HLSL et pas GLSL
- [ ] ajouter des helpers pour le print de matrices (commencé depuis Windows, laissé en WIP)

Remarques :
- il y a au moins un `fract()` qui traine, et le `fmod()` modifié depuis `mod()` reste suspicieux (jamais de negative values ?)

# obs-shadertastic-effects/effects/filters/temporal_diff

- [x] avoir une branche obs-shadertastic-private/origin/prev_frame rebased (done by xurei)
- [x] avoir un hello world like utilisant prev_tex (`ghost`, done by xurei)
- [x] avoir un cas pathologique utilisant prev_tex (`filters/temporal_diff`)
- [ ] tracer le code pour voir le mélange qui se produit selon si preview actif ou pas

# obs-shadertastic-effects/effects/released_transitions/stinger_html

- [x] avoir un effet hello world qui restart tout seul à chaque nouvelle transition
- [ ] documenter l'utilisation du plugin (édiiton du HTML local, activation WebSocket)
- [ ] étudier l'ajout d'un type dans meta.json pour afficher un message et une URL de doc à l'utilisateur ?
- [ ] PR OBS pour avoir l'event hors WebSocket mais via l'objet JS / eventListeners ? (il n'y a que celui de FIN de transition)
- [ ] essayer en half-resolution et 60 FPS et voir si ça keep up sur des petites configs
  - dessiner des numéro de frame à des positions différentes à chaque frame pour compter ?

Remarques :
- mouahaha obs-websocker s'abonne à tous les events de toutes les sources de toutes les scènes pour avoir l'event de la libobs plutôt que d'avoir l'event de la frontend-api de l'UI d'OBS. Quel millefeuille...
- `obs_source_dosignal(transition, "source_transition_start", "transition_start");`
- https://github.com/obsproject/obs-websocket/blob/master/docs/generated/protocol.md#scenetransitionstarted

https://discord.com/channels/1118094149846044724/1118682945700499526/1262421425923297311

# obs-shadertastic-effects/effects/filters/cam_toolbox

- [ ] ajouter correction / amplification effets lentille :
  - https://marcodiiga.github.io/radial-lens-undistortion-filtering
  - https://www.shadertoy.com/view/XtVSzz
  - https://www.shadertoy.com/view/lstyzs
  - voir le TOSEE pour du détail GEGL / GIMP mais c'est compliqué et âgé

- [ ] faire un format de texture pour d'éventuelles bordures de fenêtres
  - remarque, il est possible que l'intérieur de la frame soit plus grande que la zone extensible de la barre de titre
  - peut être faut il rotate 90 les éléments de titre dans le texture ? trouver une disposition "toujours correcte" ?
  - peut-être essayer de faire comme dans les skins WinAmp (mais ils avaietn tout fixés), ou les vieux WM léger on top of Xorg ?
  - https://skins.webamp.org/skin/5e4f10275dcb1fb211d4a8b4f1bda236/base-2.91.wsz/
  - idée initiale mais qui s'avère limitante : j'ai eu une idée possiblement décevante de simplicité au petit matin sur l'idée d'un shader qui sert de window-decorator. Pour ne pas avec une foret de if() et de rect pour piocher dans la tilemap... finalement quelle est la meilleure façon d'arranger les morceaux d'images dans la tilemap ? faire une texture d'une taille carrée, d'une largeur impaire en nombre de pixels, choisir la couleur de fond de la fenetre grace au pixel central (ou transparent si on veut)
- [ ] ptet Shadertastic devrait passer des uniform avec des texture size ? Pas certains ce que ça soit nécessaire, à explorer d'abord

# Notes de surprises trouvées au passage dans OBS

- plugins/win-capture/inject-helper/inject-helper.c avec du code obfusqué (pour les antivirus?) sur dans `open_process` et `inject_library`
- D'après IEEE 754 on est sûr d'être bit-exact même en float32 jusqu'à des fontes en 6x4 car on a 24 bits de mantisse au moins. 
- Et Shadertoy confirme : https://www.shadertoy.com/view/tlGfR3


