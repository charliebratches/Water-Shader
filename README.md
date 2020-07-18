Real-time GPU water simulation on the Unity engine.

![cool gif 1](./waterExample02.gif)

In this simulation, a body of water supports multiple collisions and overlapping ripples. Ripples will collide with eachother & with walls, creating a complex ripple simulation that is still performant enough to use in a realtime game engine.

Mesh deformation and sin-wave ripples are calculated on the GPU, while the position of any given rigidbody collision is controlled by a C# script.

I've included some other cool features for this shader to improve the visual fidelity:
* Edge detection for rendering an additional masked detail texture. For instance - foam, pond scum, or bubbles can be rendered at the edge of any body of water.
* Traditional water-shader lens distortion with adjustable distortion amount and refraction.
* Edge-detection screenspace fog effect. Crank up the fog setting for a cloudy pool. Keep it at zero for a crystal-clear pool.
* Adjust the speed of flowing water. The speed of the detail mask texture can also be adjusted as a percentage of the flow speed.
* Use any normal map for the distortion effect.

Check out some more examples of the shader in-action on my twitter: https://twitter.com/CharlieBratches/status/1272199937716092930 https://twitter.com/CharlieBratches/status/1272201267977302016

*Note, I've included a tessellation shader from this catlike-coding article: https://catlikecoding.com/unity/tutorials/advanced-rendering/tessellation/
This is just used to show off the heightfield water effect, and is used on the 3d rocks seen in the example gif.
