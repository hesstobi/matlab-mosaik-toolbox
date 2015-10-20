import mosaik

sim_config = {
    'Matlab': {
        'cwd': os.path.dirname(os.path.realpath(__file__)), # Set here the path of your Matlab Simulator
        'cmd': 'matlab.exe -r "server=\'%(addr)s\';ExampleMas(\'%(addr)s\')"'
    }
}

mosaik_config = {
    'start_timeout': 600,  # seconds
    'stop_timeout': 10,  # seconds
}

world = mosaik.World(sim_config, mosaik_config)

exsim_0 = world.start('Matlab')
exsim_1 = world.start('Matlab')

a_set = exsim_0.Agent.create(3)
b_set = exsim_1.Agent.create(3)

for a, b in zip(a_set, b_set):
    world.connect(a, b, ('link', 'link'))

world.run(until=10)