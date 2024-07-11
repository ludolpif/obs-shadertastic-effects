Example of execution

```
info: CPU Name: AMD Ryzen 5 1600 Six-Core Processor
info: CPU Speed: 1661.845MHz
info: Physical Cores: 6, Logical Cores: 12
info: Physical Memory: 15910MB Total, 13285MB Free
info: Kernel Version: Linux 6.9.8-arch1-1
info: Distribution: "Arch Linux" Unknown
info: Desktop Environment: GNOME (gnome)
info: Session Type: x11
info: Unable to open X display
debug: found alternate keycode 62 for OBS_KEY_SHIFT which already has keycode 50
debug: found alternate keycode 105 for OBS_KEY_CONTROL which already has keycode 37
debug: found alternate keycode 187 for OBS_KEY_PARENLEFT which already has keycode 14
debug: found alternate keycode 188 for OBS_KEY_PARENRIGHT which already has keycode 20
debug: found alternate keycode 190 for OBS_KEY_REDO which already has keycode 137
debug: found alternate keycode 208 for OBS_KEY_VK_MEDIA_PLAY_PAUSE which already has keycode 172
debug: found alternate keycode 215 for OBS_KEY_VK_MEDIA_PLAY_PAUSE which already has keycode 172
debug: found alternate keycode 218 for OBS_KEY_PRINT which already has keycode 107
debug: found alternate keycode 231 for OBS_KEY_CANCEL which already has keycode 136
info: ---------------------------------
info: Initializing OpenGL...
debug: Created EGLDisplay 0x59a0d82515d0
info: Loading up OpenGL on adapter NVIDIA Corporation NVIDIA GeForce GTX 1060 3GB/PCIe/SSE2
info: OpenGL loaded successfully, version 3.3.0 NVIDIA 555.58.02, shading language 3.30 NVIDIA via Cg compiler
info: gs_create: success on adapter 0
info: gs_enter_context(graphics) done
info: Parsing Shader 'crash_test.hlsl'...
info: ep_init(&parser) done
info: ep_parse(...) returns false
error: -----8<----- Shader compilation error  1 -----8<-----
error: uniform float rand_seed;        
error: uniform int current_step;       
error: 
error:  
error: uniform float progression = 1.0;
error: const float testing = 1.0;
error: pppppppppppppppproperty float testing2 = 1.0;
error: ---------------------------------------^
error: crash_test.hlsl: lex_error: Expected 'name'
error: unicorn float testing3 = 42.0;
error: 
error:  
error: ----->8--------------------------------------->8-----
error: -----8<----- Shader compilation error  2 -----8<-----
error: uniform int current_step;       
error: 
error:  
error: uniform float progression = 1.0;
error: const float testing = 1.0;
error: pppppppppppppppproperty float testing2 = 1.0;
error: unicorn float testing3 = 42.0;
error: -----------------------^
error: crash_test.hlsl: lex_error: Expected 'name'
error: 
error:  
error: #define PI 3.1415926535
error: ----->8--------------------------------------->8-----
error: -----8<----- Shader compilation error  3 -----8<-----
error:     pass
error:     {
error:         vertex_shader = VSDefault(v_in);
error:         pixel_shader = PSEffect(f_in);
error:     }
error: }
error: (End of File)
error: ^
error: crash_test.hlsl: lex_error: Unexpected EOF
error: ----->8--------------------------------------->8-----
error: ep_parse: false
info: Freeing OBS context data
```
