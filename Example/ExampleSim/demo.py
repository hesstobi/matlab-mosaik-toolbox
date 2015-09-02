import mosaik

sim_config = {
    'Matlab': {
    	'cwd': 'C:\\Users\\sjras\\OneDrive\\Dokumente\\MATLAB\\IEEHMosaikToolbox\\Example',
        'cmd': 'matlab.exe -r "server=\'%(addr)s\';ExampleSim(server)"'
    }
}

mosaik_config = {
    'start_timeout': 3000,  # seconds
    'stop_timeout': 10,  # seconds
}

world = mosaik.World(sim_config, mosaik_config)

exsim_0 = world.start('Matlab')
exsim_1 = world.start('Matlab')

a_set = exsim_0.A.create(3)
b_set = exsim_1.B.create(3)

for a, b in zip(a_set, b_set):
    world.connect(a, b, ('val_out', 'val_in'))

world.run(until=10)
#exsim_0.wtimes('Hallo', times=23)
#world.shutdown() 