import mosaik

sim_config = {
    'Matlab': {
        'cmd': 'matlab.exe -minimize - nosplash -nodesktop -r "server=\'%(addr)s\';ieeh_mosaik_api_matlab.ExampleSim(server)"'
    }
}

mosaik_config = {
    'start_timeout': 3000,  # seconds
    'stop_timeout': 10,  # seconds
}

world = mosaik.World(sim_config, mosaik_config)

exsim_0 = world.start('Matlab', step_size=2)
exsim_1 = world.start('Matlab')

a_set = [exsim_0.A(init_val=i) for i in range(3)]
b_set = exsim_1.B.create(3, init_val=1)

for a, b in zip(a_set, b_set):
    world.connect(a, b, ('val_out', 'val_in'))

world.run(until=10)
#exsim_0.wtimes('Hallo', times=23)
#world.shutdown()

# 