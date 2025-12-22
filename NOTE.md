This software is fully licensed by the MIT. 
However, I would like to request that the following is retained:

[`/.devcontainer/devcontainer.json`](/.devcontainer/devcontainer.json)
```json:/.devcontainer/devcontainer.json
{
    "postCreateCommand": "curl -L -o .devcontainer/blender/sway/splash.png https://raw.githubusercontent.com/peakys-org/blender-devcontainer/main/.devcontainer/blender/sway/splash.png",
}
```