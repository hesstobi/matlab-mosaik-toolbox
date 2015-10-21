import mosaik
import os.path

sim_config = {
    'Matlab': {
        'cwd': os.path.dirname(os.path.realpath(__file__)), # Set here the path of your Matlab Simulator
        'cmd': 'matlab.exe -minimize -nosplash -r "server=\'%(addr)s\';ExampleMas(\'%(addr)s\')"'
    }
}

mosaik_config = {
    'start_timeout': 600,  # seconds
    'stop_timeout': 10,  # seconds
}

world = mosaik.World(sim_config, mosaik_config)

exmas_0 = world.start('Matlab')
exmas_1 = world.start('Matlab')

a = exmas_0.Agent()
b = exmas_1.Agent()

world.connect(a, b, ('link', 'link'))

world.run(until=10)