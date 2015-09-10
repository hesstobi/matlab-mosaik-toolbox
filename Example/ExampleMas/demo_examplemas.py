import mosaik

sim_config = {
    'Matlab_Agent': {
    	'cwd': 'C:\\Users\\sjras\\OneDrive\\Dokumente\\MATLAB\\IEEHMosaikToolbox\\Example\\ExampleMas',
        'cmd': 'matlab.exe -r "server=\'%(addr)s\';ExampleMas(server)"'
    },
    'Matlab_Model': {
    	'cwd': 'C:\\Users\\sjras\\OneDrive\\Dokumente\\MATLAB\\IEEHMosaikToolbox\\Example\\ExampleSim',
        'cmd': 'matlab.exe -r "server=\'%(addr)s\';ExampleSim(server)"'
    }
}

mosaik_config = {
    'start_timeout': 3000,  # seconds
    'stop_timeout': 10,  # seconds
}

world = mosaik.World(sim_config, mosaik_config)

exsim_0 = world.start('Matlab_Agent')
exsim_1 = world.start('Matlab_Model')

a_set = exsim_0.Agent.create(3)
b_set = exsim_1.B.create(3)

for a, b in zip(a_set, b_set):
    world.connect(a, b, ('link', 'link'))

world.run(until=10)