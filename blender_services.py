# python -m pip install --break-system-packages ruamel.yaml
# python blender_services.py
# cp blender_services.json .devcontainer/
import copy
import json
from ruamel.yaml import YAML
yaml = YAML()
yaml.preserve_quotes = True
yaml.indent(mapping=2, sequence=4, offset=2)

with open('./blender_services.json', 'r') as f:
    services = json.load(f)
ports = [services[service]['port'] for service in services]
if len(ports) != len(set(ports)):
    raise ValueError('Duplicate ports found in blender_services.json')

with open('./.devcontainer/compose.yaml', 'r') as f:
    compose = yaml.load(f)

compose['x-volumes'] = ['../:/workspaces/development/',]
compose['volumes'] = {}
[compose['services'].pop(service) for service in list(compose['services'].keys()) if (service not in ['devcontainer', 'novnc'])]

for service in services:
    version = services[service]['version']
    port = services[service]['port']
    resources = services[service].get('resources', None)
    compose['services'][service] = copy.deepcopy(compose['x-blender'])
    compose['services'][service]['build']['args'][0] = f'BLENDER_VERSION={version}'
    compose['services'][service]['image'] = f'ghcr.io/peakys-org/blender-devcontainer/blender:{version}'
    compose['services'][service]['environment'][1] = f'SERVICE_NAME={service}'
    compose['services'][service]['ports'][0] = f'{port}:5900'
    compose['services'][service]['volumes'][0] = f'../:/workspaces/development/'
    compose['services'][service]['volumes'][1] = f'{service}:/workspaces/blender/'
    if resources:
        compose['services'][service]['volumes'][2] = f'{resources}:/workspaces/blender/portable/'
    else:
        compose['services'][service]['volumes'].pop()
    compose['volumes'][service] = None
    compose['x-volumes'].append(f'{service}:/workspaces/{service}/')
compose['services']['devcontainer']['volumes'] = compose['x-volumes']

with open('./.devcontainer/compose.yaml', 'w') as f:
    yaml.dump(compose, f)